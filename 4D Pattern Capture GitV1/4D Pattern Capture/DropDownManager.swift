//
//  DropDownManager.swift
//  4D Pattern Capture
//
//  Created by Taylor Hinchliffe on 4/29/24.
//

import Foundation
import Cocoa
import SceneKit

class DropdownManager {
    weak var viewController: GameViewController?

    init(viewController: GameViewController) {
        self.viewController = viewController
    }

    func createMaterialPropertyDropdown() -> NSPopUpButton {
        let dropdown = NSPopUpButton(frame: NSRect(x: 10, y: 10, width: 150, height: 25), pullsDown: false)
        let items = [
            "Blend Mode: Add",
            "Blend Mode: Alpha",
            "Blend Mode: Max",
            "Blend Mode: Multiply",
            "Blend Mode: Replace",
            "Blend Mode: Screen",
            "Blend Mode: Subtract"
        ]
        dropdown.addItems(withTitles: items)
        dropdown.action = #selector(handleMaterialPropertySelection(_:))
        dropdown.target = self
        return dropdown
    }

    @objc func handleMaterialPropertySelection(_ sender: NSPopUpButton) {
        guard let selectedItem = sender.selectedItem,
              let viewController = viewController else { return }

        let selectedBlendMode = blendMode(from: selectedItem.title)

        for material in viewController.materialsToAdjust {
            material.blendMode = selectedBlendMode
        }
    }

    private func blendMode(from title: String) -> SCNBlendMode {
        switch title {
        case "Blend Mode: Add":
            return .add
        case "Blend Mode: Alpha":
            return .alpha
        case "Blend Mode: Max":
            return .max
        case "Blend Mode: Multiply":
            return .multiply
        case "Blend Mode: Replace":
            return .replace
        case "Blend Mode: Screen":
            return .screen
        case "Blend Mode: Subtract":
            return .subtract
        default:
            return .alpha
        }
    }
    
    
    func createLightingModelDropdown() -> NSPopUpButton {
            let dropdown = NSPopUpButton(frame: NSRect(x: 10, y: 50, width: 150, height: 25), pullsDown: false)
            let items = [
                "Lighting Model: Blinn",
                "Lighting Model: Constant",
                "Lighting Model: Lambert",
                "Lighting Model: Phong",
                "Lighting Model: Physically Based",
                "Lighting Model: Shadow Only"
            ]
            dropdown.addItems(withTitles: items)
            dropdown.action = #selector(handleLightingModelSelection(_:))
            dropdown.target = self
            return dropdown
        }

        @objc func handleLightingModelSelection(_ sender: NSPopUpButton) {
            guard let selectedItem = sender.selectedItem,
                  let viewController = viewController else { return }

            let selectedLightingModel = lightingModel(from: selectedItem.title)

            for material in viewController.materialsToAdjust {
                material.lightingModel = selectedLightingModel
            }
        }

        private func lightingModel(from title: String) -> SCNMaterial.LightingModel {
            switch title {
            case "Lighting Model: Blinn":
                return .blinn
            case "Lighting Model: Constant":
                return .constant
            case "Lighting Model: Lambert":
                return .lambert
            case "Lighting Model: Phong":
                return .phong
            case "Lighting Model: Physically Based":
                return .physicallyBased
            case "Lighting Model: Shadow Only":
                return .shadowOnly
            default:
                return .blinn // Default or fallback case
            }
        }
    
    
    func createBackgroundContentsDropdown() -> NSPopUpButton {
            let dropdown = NSPopUpButton(frame: NSRect(x: 10, y: 90, width: 150, height: 25), pullsDown: false)
            let items = [
                "Background: Default",  // Assuming this resets to the default background
                "Background: Black",
                "Background: White",
                "Background: Red",
                "Background: Green",
                "Background: Blue",
                "Background: Image",
                "Background: Gradient"
            ]
            dropdown.addItems(withTitles: items)
            dropdown.action = #selector(handleBackgroundContentsSelection(_:))
            dropdown.target = self
            return dropdown
        }

        @objc func handleBackgroundContentsSelection(_ sender: NSPopUpButton) {
            guard let selectedItem = sender.selectedItem,
                  let scnView = viewController?.view as? SCNView else { return }

            switch selectedItem.title {
            case "Background: Black":
                scnView.scene?.background.contents = NSColor.black
            case "Background: White":
                scnView.scene?.background.contents = NSColor.white
            case "Background: Red":
                scnView.scene?.background.contents = NSColor.red
            case "Background: Green":
                scnView.scene?.background.contents = NSColor.green
            case "Background: Blue":
                scnView.scene?.background.contents = NSColor.blue
            case "Background: Image":
                let image = NSImage(named: "YourBackgroundImageName") // Add your image to Assets
                scnView.scene?.background.contents = image
            case "Background: Gradient":
                let colors = [NSColor.red.cgColor, NSColor.blue.cgColor]
                let gradientLayer = CAGradientLayer()
                gradientLayer.colors = colors
                gradientLayer.frame = scnView.bounds
                scnView.scene?.background.contents = gradientLayer
            case "Background: Default":
                scnView.scene?.background.contents = nil // Or set to your initial default background
            default:
                break
            }
        }
    
    
    
}

