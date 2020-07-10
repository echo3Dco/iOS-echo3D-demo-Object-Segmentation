//
//  CGImageRaw.swift
//  Object-Segmentation
//
//  Created by EchoAR on 6/23/20.
//  Copyright © 2020 EchoAR. All rights reserved.
//

import CoreGraphics
import CoreImage
import VideoToolbox

extension CGImage {
    /**
     Converts the image into an array of RGBA bytes.
     */
    @nonobjc public func toByteArrayRGBA() -> [UInt8] {
        var bytes = [UInt8](repeating: 0, count: width * height * 4)
        bytes.withUnsafeMutableBytes { ptr in
            if let colorSpace = colorSpace,
                let context = CGContext(
                    data: ptr.baseAddress,
                    width: width,
                    height: height,
                    bitsPerComponent: bitsPerComponent,
                    bytesPerRow: bytesPerRow,
                    space: colorSpace,
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) {
                let rect = CGRect(x: 0, y: 0, width: width, height: height)
                context.draw(self, in: rect)
            }
        }
        return bytes
    }
    
    /**
     Creates a new CGImage from an array of RGBA bytes.
     */
    @nonobjc public class func fromByteArrayRGBA(_ bytes: [UInt8],
                                                 width: Int,
                                                 height: Int) -> CGImage? {
        return fromByteArray(bytes, width: width, height: height,
                             bytesPerRow: width * 4,
                             colorSpace: CGColorSpaceCreateDeviceRGB(),
                             alphaInfo: .premultipliedLast)
    }
    
    /**
     Creates a new CGImage from an array of grayscale bytes.
     */
    @nonobjc public class func fromByteArrayGray(_ bytes: [UInt8],
                                                 width: Int,
                                                 height: Int) -> CGImage? {
        return fromByteArray(bytes, width: width, height: height,
                             bytesPerRow: width,
                             colorSpace: CGColorSpaceCreateDeviceGray(),
                             alphaInfo: .none)
    }
    
    @nonobjc class func fromByteArray(_ bytes: [UInt8],
                                      width: Int,
                                      height: Int,
                                      bytesPerRow: Int,
                                      colorSpace: CGColorSpace,
                                      alphaInfo: CGImageAlphaInfo) -> CGImage? {
        return bytes.withUnsafeBytes { ptr in
            let context = CGContext(data: UnsafeMutableRawPointer(mutating: ptr.baseAddress!),
                                    width: width,
                                    height: height,
                                    bitsPerComponent: 8,
                                    bytesPerRow: bytesPerRow,
                                    space: colorSpace,
                                    bitmapInfo: alphaInfo.rawValue)
            return context?.makeImage()
        }
    }
    
    public func resizeCGIImage(width: Int, height: Int, orientation: CGImagePropertyOrientation) -> CGImage? {
        guard let pixelBuf = pixelBuffer(width: width, height: height, orientation: orientation) else { return nil }
        return CGImage.create(pixelBuffer: pixelBuf)
    }
    
    
    public func pixelBuffer(width: Int, height: Int,
                            orientation: CGImagePropertyOrientation) -> CVPixelBuffer? {
        return pixelBuffer(width: width, height: height,
                           pixelFormatType: kCVPixelFormatType_32ARGB,
                           colorSpace: CGColorSpaceCreateDeviceRGB(),
                           alphaInfo: .noneSkipFirst,
                           orientation: orientation)
    }
    
    func pixelBuffer(width: Int, height: Int, pixelFormatType: OSType,
                     colorSpace: CGColorSpace, alphaInfo: CGImageAlphaInfo,
                     orientation: CGImagePropertyOrientation) -> CVPixelBuffer? {
        
        // TODO: If the orientation is not .up, then rotate the CGImage.
        // See also: https://stackoverflow.com/a/40438893/
        assert(orientation == .up)
        
        var maybePixelBuffer: CVPixelBuffer?
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
                     kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue]
        let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                         width,
                                         height,
                                         pixelFormatType,
                                         attrs as CFDictionary,
                                         &maybePixelBuffer)
        
        guard status == kCVReturnSuccess, let pixelBuffer = maybePixelBuffer else {
            return nil
        }
        
        let flags = CVPixelBufferLockFlags(rawValue: 0)
        guard kCVReturnSuccess == CVPixelBufferLockBaseAddress(pixelBuffer, flags) else {
            return nil
        }
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, flags) }
        
        guard let context = CGContext(data: CVPixelBufferGetBaseAddress(pixelBuffer),
                                      width: width,
                                      height: height,
                                      bitsPerComponent: 8,
                                      bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
                                      space: colorSpace,
                                      bitmapInfo: alphaInfo.rawValue)
            else {
                return nil
        }
        
        context.draw(self, in: CGRect(x: 0, y: 0, width: width, height: height))
        return pixelBuffer
    }
    
}

extension CGImage {
    /**
     Creates a new CGImage from a CVPixelBuffer.
     - Note: Not all CVPixelBuffer pixel formats support conversion into a
     CGImage-compatible pixel format.
     */
    public static func create(pixelBuffer: CVPixelBuffer) -> CGImage? {
        var cgImage: CGImage?

        //print(CVPixelBufferGetPixelFormatType(pixelBuffer))
        VTCreateCGImageFromCVPixelBuffer(pixelBuffer, options: nil, imageOut: &cgImage)
        return cgImage
    }
    
}
