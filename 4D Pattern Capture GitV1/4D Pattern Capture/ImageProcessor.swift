//
//  ImageProcessor.swift
//  4D Pattern Capture
//
//  Created by Taylor Hinchliffe on 3/1/24.
//



import MetalKit

class ImageProcessor {
    static func enhanceImage(of image: NSImage, contrast: CGFloat) -> NSImage? {
        guard let metalManager = MetalManager.shared,
              let texture = metalManager.texture(from: image) else {
            return nil
        }
        
        guard let enhancedTexture = metalManager.enhanceImage(texture: texture, contrast: Float(contrast)) else {
            return nil
        }
        
        return metalManager.imageFromTexture(enhancedTexture)
        }
    }

