//
//  MetalManager.swift
//  4D Pattern Capture
//
//  Created by Taylor Hinchliffe on 6/13/24.
//

import Foundation
import AVFoundation
import Metal
import IOSurface
import AppKit

class MetalManager {
    static let shared = MetalManager()
    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    let pipelineState: MTLComputePipelineState
    
    private init?() {
        guard let device = MTLCreateSystemDefaultDevice() else { return nil }
        self.device = device
        self.commandQueue = device.makeCommandQueue()!
        let library = device.makeDefaultLibrary()
        let function = library?.makeFunction(name: "processFrame")
        do {
            pipelineState = try device.makeComputePipelineState(function: function!)
        } catch {
            fatalError("Unable to create pipeline state: \(error)")
        }
    }
    
    func processImage(inputTexture: MTLTexture, outputTexture: MTLTexture) {
        let commandBuffer = commandQueue.makeCommandBuffer()!
        let commandEncoder = commandBuffer.makeComputeCommandEncoder()!
        commandEncoder.setComputePipelineState(pipelineState)
        commandEncoder.setTexture(inputTexture, index: 0)
        commandEncoder.setTexture(outputTexture, index: 1)
        
        let threadGroupSize = MTLSize(width: 8, height: 8, depth: 1)
        let width = outputTexture.width
        let height = outputTexture.height
        
        guard width > 0, height > 0 else {
            print("Invalid texture dimensions")
            return
        }
        
        let threadGroups = MTLSize(
            width: (width + threadGroupSize.width - 1) / threadGroupSize.width,
            height: (height + threadGroupSize.height - 1) / threadGroupSize.height,
            depth: 1
        )
        
        commandEncoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupSize)
        commandEncoder.endEncoding()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
    }
    
    func texture(from pixelBuffer: CVPixelBuffer) -> MTLTexture? {
        guard let iosurface = CVPixelBufferGetIOSurface(pixelBuffer)?.takeUnretainedValue() else {
            print("Failed to get IOSurface from pixel buffer")
            return nil
        }
        
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .bgra8Unorm,
            width: CVPixelBufferGetWidth(pixelBuffer),
            height: CVPixelBufferGetHeight(pixelBuffer),
            mipmapped: false
        )
        textureDescriptor.usage = [.shaderRead, .shaderWrite]
        let texture = device.makeTexture(descriptor: textureDescriptor, iosurface: iosurface, plane: 0)
        if texture == nil {
            print("Failed to create texture from IOSurface")
        }
        return texture
    }
    
    func emptyTexture(width: Int, height: Int) -> MTLTexture? {
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .bgra8Unorm, width: width, height: height, mipmapped: false
        )
        textureDescriptor.usage = [.shaderRead, .shaderWrite]
        let texture = device.makeTexture(descriptor: textureDescriptor)
        if texture == nil {
            print("Failed to create empty texture")
        }
        return texture
    }
    
    func texture(from image: NSImage) -> MTLTexture? {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            print("Failed to get CGImage from NSImage")
            return nil
        }
        
        let width = cgImage.width
        let height = cgImage.height
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        var rawData = [UInt8](repeating: 0, count: width * height * 4)
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8
        
        guard let context = CGContext(
            data: &rawData,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            print("Failed to create CGContext")
            return nil
        }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .bgra8Unorm, width: width, height: height, mipmapped: false
        )
        textureDescriptor.usage = [.shaderRead, .shaderWrite]
        
        guard let texture = device.makeTexture(descriptor: textureDescriptor) else {
            print("Failed to create texture")
            return nil
        }
        
        texture.replace(
            region: MTLRegionMake2D(0, 0, width, height),
            mipmapLevel: 0,
            withBytes: rawData,
            bytesPerRow: bytesPerRow
        )
        
        return texture
    }
    
    func enhanceImage(texture: MTLTexture, contrast: Float) -> MTLTexture? {
        guard let outputTexture = emptyTexture(width: texture.width, height: texture.height) else {
            return nil
        }
        processImage(inputTexture: texture, outputTexture: outputTexture)
        return outputTexture
    }
    
    func imageFromTexture(_ texture: MTLTexture) -> NSImage? {
        let textureWidth = texture.width
        let textureHeight = texture.height
        let imageByteCount = textureWidth * textureHeight * 4
        let bytesPerRow = textureWidth * 4
        
        var imageBytes = [UInt8](repeating: 0, count: imageByteCount)
        let region = MTLRegionMake2D(0,0, textureWidth, textureHeight)
        texture.getBytes(&imageBytes, bytesPerRow: bytesPerRow, from: region, mipmapLevel: 0)
        guard let providerRef = CGDataProvider(data: NSData(bytes: &imageBytes, length: imageByteCount)) else {
            return nil
        }
        
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        let colorSpaceRef = CGColorSpaceCreateDeviceRGB()
        let renderingIntent = CGColorRenderingIntent.defaultIntent
        
        if let cgImage = CGImage(
            width: textureWidth,
            height: textureHeight,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: bytesPerRow,
            space: colorSpaceRef,
            bitmapInfo: bitmapInfo,
            provider: providerRef,
            decode: nil,
            shouldInterpolate: true,
            intent: renderingIntent
        ) {
            return NSImage(cgImage: cgImage, size: NSSize(width: textureWidth, height: textureHeight))
        }
        
        return nil
    }
}
