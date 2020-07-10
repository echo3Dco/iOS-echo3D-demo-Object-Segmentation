//
//  UIImageExtensions.swift
//  Object-Segmentation
//
//  Created by EchoAR on 6/24/20.
//  Copyright © 2020 EchoAR. All rights reserved.
//



import UIKit
import VideoToolbox

extension CVPixelBuffer {
    
    /**
    CVPixelBuffer extension to convert CVPixelBuffer to an UIImage:
     - Uses:
        `let image:UIimage = pixelBuffer.createImage()`
    */
    func createImage()->UIImage {
        CVPixelBufferLockBaseAddress(self, CVPixelBufferLockFlags(rawValue: 0))
        let baseAddress =  CVPixelBufferGetBaseAddress(self)
        let context = CGContext(data: baseAddress,
                                width: CVPixelBufferGetWidth(self),
                                height: CVPixelBufferGetHeight(self),
                                bitsPerComponent: 8,
                                bytesPerRow: CVPixelBufferGetBytesPerRow(self),
                                space: CGColorSpaceCreateDeviceGray(),
                                bitmapInfo: CGImageAlphaInfo.none.rawValue)
        let cgimage = context?.makeImage()
        CVPixelBufferUnlockBaseAddress(self, CVPixelBufferLockFlags(rawValue: 0))
        return UIImage(cgImage: cgimage!)
    }
}

extension UIImage {
    
    /*
    Use this UIImage Extension to fix the orientation of UIImage.
    While converting UIImage to CGImage for masking, UIImage loses it's orientation so use this function to fix the orientation issues.
     
    - Uses:
        `image = image.fixOrientation()`
     
    - return: UIimage with orientation .up
    */
    func fixOrientation() -> UIImage? {
        switch imageOrientation {
        case .up:
            return self
        default:
           return createImageFromContext()
        }
    }
    
    /*
     
    Use the createImageFromContext() extenstion for creating image from the context.
    
    */
    func createImageFromContext() -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(self.size, false, scale)
        draw(in: CGRect(origin: .zero, size: size))
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result
    }
    
    /*
    Use this function to resize image:
        
    - Parameters:
        - size: @CGSize -> size of the new image.
        
    - Returns: UIImage with new size.
    */
    func resizeImage(for size: CGSize) -> UIImage? {
        let image = self.cgImage

        let context = CGContext(data: nil,
                                width: Int(size.width),
                                height: Int(size.height),
                                bitsPerComponent: 8,
                                bytesPerRow: Int(size.width),
                                space: CGColorSpaceCreateDeviceGray(),
                                bitmapInfo: CGImageAlphaInfo.none.rawValue)
        context?.interpolationQuality = .high
        context?.draw(image!, in: CGRect(origin: .zero, size: size))

        guard let scaledImage = context?.makeImage() else { return nil }

        return UIImage(cgImage: scaledImage)
    }
}
