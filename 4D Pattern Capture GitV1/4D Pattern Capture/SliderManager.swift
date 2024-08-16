//
//  SliderManager.swift
//  4D Pattern Capture
//
//  Created by Taylor Hinchliffe on 4/29/24.
//

import Foundation
import Cocoa
import SceneKit

class SliderManager {
    weak var viewController: GameViewController?

    init(viewController: GameViewController) {
        self.viewController = viewController
    }

    // contrast slider (only usable before loading the video)
    
    func createContrastSlider() -> (NSSlider, NSTextField) {
        let contrastSlider = NSSlider(value: 1.0, minValue: 0.0, maxValue: 3.0, target: self, action: #selector(contrastSliderChanged(_:)))
        contrastSlider.isContinuous = true
        contrastSlider.frame = NSRect(x: 10, y: 130, width: 150, height: 25)
        
        let contrastLabel = NSTextField(labelWithString: "Contrast")
        contrastLabel.frame = NSRect(x: 10, y: 155, width: 150, height: 20)
        contrastLabel.alignment = .center
        contrastLabel.textColor = .gray
        contrastLabel.backgroundColor = .clear
        contrastLabel.isBezeled = false
        contrastLabel.isEditable = false
        contrastLabel.sizeToFit()
        
        return (contrastSlider, contrastLabel)
    }

    @objc func contrastSliderChanged(_ sender: NSSlider) {
        print("Slider changed: \(sender.doubleValue)")  // Debug to confirm it's being called
        viewController?.updateImageContrast()
    }
    
    
    // transparency slider
    
    func createTransparencySlider() -> (NSSlider, NSTextField) {
        let transparencySlider = NSSlider(value: 1.0, minValue: 0.0, maxValue: 1.0, target: self, action: #selector(transparencySliderChanged(_:)))
        transparencySlider.isContinuous = true
        transparencySlider.frame = NSRect(x: 10, y: 170, width: 150, height: 25)
        
        let transparencyLabel = NSTextField(labelWithString: "Transparency")
        transparencyLabel.frame = NSRect(x: 10, y: 195, width: 150, height: 20)
        transparencyLabel.alignment = .center
        transparencyLabel.textColor = .gray
        transparencyLabel.backgroundColor = .clear
        transparencyLabel.isBezeled = false
        transparencyLabel.isEditable = false
        transparencyLabel.sizeToFit()
        
        return (transparencySlider, transparencyLabel)
    }
    
    @objc func transparencySliderChanged(_ sender: NSSlider) {
        let transparencyValue = CGFloat(sender.doubleValue)
        viewController?.updateMaterialTransparency(transparencyValue)
    }
    
    
    // image distance slider ("time axis" slider)
    
    func createPlaneDistanceSlider() -> (NSSlider, NSTextField) {
        let planeDistanceSlider = NSSlider(value: 0.0035, minValue: 0.001, maxValue: 0.01, target: self, action: #selector(planeDistanceSliderChanged(_:)))
        planeDistanceSlider.isContinuous = true
        planeDistanceSlider.frame = NSRect(x: 10, y: 210, width: 150, height: 25)

        let distanceLabel = NSTextField(labelWithString: "Image Distance")
        distanceLabel.frame = NSRect(x: 10, y: 235, width: 150, height: 20)
        distanceLabel.alignment = .center
        distanceLabel.textColor = .gray
        distanceLabel.backgroundColor = .clear
        distanceLabel.isBezeled = false
        distanceLabel.isEditable = false
        distanceLabel.sizeToFit()

        return (planeDistanceSlider, distanceLabel)
    }

    @objc func planeDistanceSliderChanged(_ sender: NSSlider) {
        let newDistance = CGFloat(sender.doubleValue)
        viewController?.updatePlaneDistance(newDistance)
    }
    
}


