//
//  Message.swift
//  Object-Segmentation
//
//  Created by EchoAR on 7/7/20.
//  Copyright © 2020 EchoAR. All rights reserved.
//

import Foundation
import UIKit

/**
    Custom Media struct to represent Image data which has to be encoded in the HttpBody.
 */
struct Media {
    let key: String
    let filename: String
    let data: Data
    let mimeType: String
    
    init?(withImage image: UIImage, forKey key: String, withName filename: String) {
        self.key = key
        self.mimeType = "image/png"
        self.filename = filename + ".png"
        
        guard let data = image.pngData() else { return nil }
        self.data = data
    }
    
}

