//
//  MultiArrayToImage.swift
//  Object-Segmentation
//
//  Created by EchoAR on 6/23/20.
//  Copyright © 2020 EchoAR. All rights reserved.
//

import Foundation
import CoreML
import UIKit

func clamp<T: Comparable>(value: T, lower: T, upper: T) -> T {
    return min(max(value, lower), upper)
}


public protocol MultiArrayType: Comparable {
    static var multiArrayDataType: MLMultiArrayDataType { get }
    static func +(lhs: Self, rhs: Self) -> Self
    static func -(lhs: Self, rhs: Self) -> Self
    static func *(lhs: Self, rhs: Self) -> Self
    static func /(lhs: Self, rhs: Self) -> Self
    init(_: Int)
    var toUInt8: UInt8 { get }
}

extension Double: MultiArrayType {
    public static var multiArrayDataType: MLMultiArrayDataType { return .double }
    public var toUInt8: UInt8 { return UInt8(self) }
}

extension Float: MultiArrayType {
    public static var multiArrayDataType: MLMultiArrayDataType { return .float32 }
    public var toUInt8: UInt8 { return UInt8(self) }
}

extension Int32: MultiArrayType {
    public static var multiArrayDataType: MLMultiArrayDataType { return .int32 }
    public var toUInt8: UInt8 { return UInt8(self) }
}


extension MLMultiArray {
    
    public func cgImage(min: Double = 0,
                        max: Double = 255,
                        channel: Int? = nil,
                        axes: (Int, Int, Int)? = nil) -> CGImage? {
        switch self.dataType {
        case .double:
            return _image(min: min, max: max)
        case .float32:
            return _image(min: Float(min), max: Float(max))
        case .int32:
            return _image(min: Int32(min), max: Int32(max))
        @unknown default:
            fatalError("Unsupported data type \(dataType.rawValue)")
        }
    }
    
    private func _image<T: MultiArrayType>(min: T,
                                           max: T) -> CGImage? {
        if let (b, w, h) = toRawBytes(min: min, max: max) {
            return CGImage.fromByteArrayGray(b, width: w, height: h)
        }
        return nil
    }
    
    public func toRawBytes<T: MultiArrayType>(min: T,
                                              max: T)
    -> (bytes: [UInt8], width: Int, height: Int)? {
        
        if shape.count < 2 {
            print("Cannot convert MLMultiArray of shape \(shape) to image")
            return nil
        }
        
        // Figure out which dimensions to use for the channels, height, and width.
        let heightAxis = 1
        let widthAxis = 0
        
        
        let height = self.shape[heightAxis].intValue
        let width = self.shape[widthAxis].intValue
        
        let cStride = 0
        let bytesPerPixel = 1
        let channelOffset = 0
        
        
        // Allocate storage for the RGBA or grayscale pixels. Set everything to
        // 255 so that alpha channel is filled in if only 3 channels.
        let count = height * width * bytesPerPixel
        var pixels = [UInt8](repeating: 255, count: count)
        
        // Grab the pointer to MLMultiArray's memory.
        var ptr = UnsafeMutablePointer<T>(OpaquePointer(self.dataPointer))
        ptr = ptr.advanced(by: channelOffset * cStride)
        
        // Loop through all the pixels and all the channels and copy them over.
        
        for i in 0..<height {
            for j in 0..<width {
                let index = i * width + j;
                let value = ptr[index]
                let pixel: UInt8
                if(value == T(0)) {
                    pixel = (0).toUInt8
                }else {
                    pixel = (255).toUInt8
                }
                pixels[(index)*bytesPerPixel] = pixel
                
            }
        }
        return (pixels, width, height)
    }
}

extension MLMultiArray {
    public func image(min: Double = 0,
                      max: Double = 255) -> UIImage? {
        let cgImg = cgImage(min: min, max: max)
        return cgImg.map { UIImage(cgImage: $0) }
    }
}


