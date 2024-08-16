//
//  VideoProcessor.swift
//  4D Pattern Capture
//
//  Created by Taylor Hinchliffe on 2/28/24.
//

import AVFoundation
import Metal
import AppKit

class VideoProcessor {
    var assetReader: AVAssetReader?
    var videoTrackOutput: AVAssetReaderTrackOutput?
    var extractedImages: [NSImage] = []
    let extractionQueue = DispatchQueue(label: "extractionQueue", attributes: .concurrent)
    let imageQueue = DispatchQueue(label: "imageQueue")
    
    var frameRate: Float = 0
    var duration: Float = 0

    func extractFrames(from url: URL, frameInterval: Int = 1, maxConcurrentTasks: Int, batchSize: Int, completion: @escaping ([NSImage], Float, Float, Int) -> Void) {
        let asset = AVAsset(url: url)
        guard let track = asset.tracks(withMediaType: .video).first else {
            print("Error: No video tracks found in asset")
            completion([], 0, 0, 0)
            return
        }
        
        let duration = Float(CMTimeGetSeconds(asset.duration))
        let frameRate = Float(track.nominalFrameRate)
        let totalFrames = Int(duration * frameRate)
        
        do {
            assetReader = try AVAssetReader(asset: asset)
            let outputSettings: [String: Any] = [
                (kCVPixelBufferPixelFormatTypeKey as String): kCVPixelFormatType_32BGRA
            ]
            videoTrackOutput = AVAssetReaderTrackOutput(track: track, outputSettings: outputSettings)
            assetReader?.add(videoTrackOutput!)
            assetReader?.startReading()
            
            var images: [NSImage] = []
            var index = 0
            let dispatchGroup = DispatchGroup()
            
            while assetReader?.status == .reading {
                if let sampleBuffer = videoTrackOutput?.copyNextSampleBuffer(),
                   let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
                    dispatchGroup.enter()
                    extractionQueue.async {
                        self.processFrame(pixelBuffer, index: index) { image in
                            if let image = image {
                                self.imageQueue.async {
                                    images.append(image)
                                }
                            }
                            dispatchGroup.leave()
                        }
                    }
                    index += 1
                } else {
                    print("Failed to copy sample buffer at index \(index)")
                }
            }
            
            dispatchGroup.notify(queue: .main) {
                completion(images, frameRate, duration, totalFrames)
            }
            
            if assetReader?.status == .completed {
                print("All frames processed successfully")
            } else {
                print("AssetReader status: \(String(describing: assetReader?.status))")
            }
            
        } catch {
            print("Error initializing asset reader: \(error)")
            completion([], 0, 0, 0)
        }
    }
    
    func processFrame(_ pixelBuffer: CVPixelBuffer, index: Int, completion: @escaping (NSImage?) -> Void) {
        guard let inputTexture = MetalManager.shared?.texture(from: pixelBuffer),
              let outputTexture = MetalManager.shared?.emptyTexture(width: CVPixelBufferGetWidth(pixelBuffer),
                                                                   height: CVPixelBufferGetHeight(pixelBuffer)) else {
            print("Error creating textures for frame at index: \(index)")
            completion(nil)
            return
        }
        
        MetalManager.shared?.processImage(inputTexture: inputTexture, outputTexture: outputTexture)
        let image = MetalManager.shared?.imageFromTexture(outputTexture)
        completion(image)
    }
}
