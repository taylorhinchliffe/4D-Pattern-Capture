//
//  GameViewController.swift
//  4D Pattern Capture
//
//  Created by Taylor Hinchliffe on 2/22/24.
//

import SceneKit
import Cocoa
import QuartzCore

class GameViewController: NSViewController {
    
    var dropdownManager: DropdownManager!
    var materialPropertyDropdown: NSPopUpButton!
    var lightingPropertyDropdown: NSPopUpButton!
    var backgroundContentsDropdown: NSPopUpButton!
    var sliderManager: SliderManager!
    var contrastSlider: NSSlider!
    var transparencySlider: NSSlider!
    var planeDistanceSlider: NSSlider!
    
    var planeDistance: CGFloat = 0.0035  // Default value
    var planeNodes: [SCNNode] = []
    
    var startTextNode: SCNNode?
    var endTextNode: SCNNode?
    var scaleBarLabelNode: SCNNode?
    
    var duration: Float = 0.0
    var totalFrames: Int = 0
    
    // define the currentImage to be manipulated
    var currentImage: NSImage?
    
    // node to display the image as a material in the scene
    var displayNode: SCNNode?
    
    // keep references to the materials meant to be adjusted
    var materialsToAdjust: [SCNMaterial] = []
    
    // parent node for holding plane nodes (scene optimization, N)
    var parentNode: SCNNode!
    
    // node for the time scale bar
    var timeScaleBar: SCNNode?
    
    override func viewDidLoad() {
        
        // slider manager initialization
        sliderManager = SliderManager(viewController: self)
        
        // create transparent image
        let size = NSSize(width: 100, height: 100)  // Define your desired size
        let image = NSImage(size: size)
        image.lockFocus()
        NSColor.clear.set()
        NSRect(origin: .zero, size: size).fill()
        image.unlockFocus()
        
        currentImage = image  // Set the transparent image as the current image
        
        super.viewDidLoad()
        print("Initializing view controller...")
        setupSliders()
        print("Sliders should be initialized.")
        setupDisplayNode()
        print("Display nodes set up.")
        
        // create new scene
        let scene = SCNScene(named: "art.scnassets/4D.scn")!
        
        // create parent node & add it to the scene (scene optimization, N)
        parentNode = SCNNode()
        scene.rootNode.addChildNode(parentNode)
        
        // create and add camera to the scene
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        scene.rootNode.addChildNode(cameraNode)
        
        // place camera
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 15)
        
        // retrieve SCNView
        let scnView = self.view as! SCNView
        
        // set the scene to the view
        scnView.scene = scene
        
        // additional adjustments for contrast/lighting
        
        scnView.autoenablesDefaultLighting = true
        
        // permit camera manipulation
        scnView.allowsCameraControl = true
        
        // add click gesture recognizer
        let clickGesture = NSClickGestureRecognizer(target: self, action: #selector(handleClick(_:)))
        var gestureRecognizers = scnView.gestureRecognizers
        gestureRecognizers.insert(clickGesture, at: 0)
        scnView.gestureRecognizers = gestureRecognizers
        
        // create DragDropView instance w/o setting its frame
        let dragDropView = DragDropView()
        
        // prep view for auto layout
        dragDropView.translatesAutoresizingMaskIntoConstraints = false
        dragDropView.wantsLayer = true
        dragDropView.layer?.backgroundColor = NSColor.gray.withAlphaComponent(0.5).cgColor // Semi-transparent
        
        // add dragDropView to scnView
        scnView.addSubview(dragDropView)
        
        // set up constraints for dragDropView relative to scnView
        NSLayoutConstraint.activate([
            // Position dragDropView in the center of scnView
            dragDropView.centerXAnchor.constraint(equalTo: scnView.centerXAnchor),
            // Position dragDropView towards the bottom of scnView, minus some offset if desired
            dragDropView.bottomAnchor.constraint(equalTo: scnView.bottomAnchor, constant: -50), // Adjust the constant as needed
            // Set the width of dragDropView
            dragDropView.widthAnchor.constraint(equalToConstant: 200), // Adjust as needed
            // Set the height of dragDropView
            dragDropView.heightAnchor.constraint(equalToConstant: 100) // Adjust as needed
        ])
        
        dragDropView.delegate = self // Set delegate
        
        // retrieve & store references to materials from nodes in the scene
        scnView.scene?.rootNode.enumerateChildNodes { (node, _) in
            if let material = node.geometry?.firstMaterial {
                self.materialsToAdjust.append(material)
            }
        }
        
        // initialize currentImage w/ example image
        currentImage = NSImage(named: "DefaultImageName") // Ensure this image is in your assets
        
        // initialize dropdown manager
        dropdownManager = DropdownManager(viewController: self)
        
        // create & add  material dropdown menu
        materialPropertyDropdown = dropdownManager.createMaterialPropertyDropdown()
        // Add the material dropdown to the view
        scnView.addSubview(materialPropertyDropdown)
        
        // create & add lighting dropdown menu
        lightingPropertyDropdown = dropdownManager.createLightingModelDropdown()
        scnView.addSubview(lightingPropertyDropdown)
        
        // create & add background dropdown menu
        backgroundContentsDropdown = dropdownManager.createBackgroundContentsDropdown()
        scnView.addSubview(backgroundContentsDropdown)
        
        // button to delete all image planes
        let deleteButton = NSButton(title: "Delete Model", target: self, action: #selector(deleteImagePlanes))
        deleteButton.frame = NSRect(x: 10, y: 270, width: 150, height: 30)
        scnView.addSubview(deleteButton)
    }
    
    func setupSliders() {
        sliderManager = SliderManager(viewController: self)
        
        // setup contrast slider
        let (contrastSlider, contrastLabel) = sliderManager.createContrastSlider()
        view.addSubview(contrastSlider)
        view.addSubview(contrastLabel)
        self.contrastSlider = contrastSlider  // Assign to a class property if needed
        
        // setup transparency slider
        let (transparencySlider, transparencyLabel) = sliderManager.createTransparencySlider()
        view.addSubview(transparencySlider)
        view.addSubview(transparencyLabel)
        self.transparencySlider = transparencySlider  // Assign to a class property if needed
        
        // setup time-scale slider
        let (planeDistanceSlider, distanceLabel) = sliderManager.createPlaneDistanceSlider()
        view.addSubview(planeDistanceSlider)
        view.addSubview(distanceLabel)
        self.planeDistanceSlider = planeDistanceSlider  // Assign to a class property if needed
    }
    
    func setupDisplayNode() {
        let plane = SCNPlane(width: 1, height: 1)
        let material = SCNMaterial()
        material.diffuse.contents = currentImage
        material.transparency = 0.0
        plane.materials = [material]
        
        displayNode = SCNNode(geometry: plane)
        displayNode?.position = SCNVector3(x: 0, y: 0, z: 0)
        if let sceneView = self.view as? SCNView {
            sceneView.scene?.rootNode.addChildNode(displayNode!)
        }
    }
    
    func updateImageContrast() {
        guard let currentImage = self.currentImage,
              let slider = contrastSlider else {
            print("Necessary components are not initialized.")
            return
        }
        let sliderValue = CGFloat(slider.doubleValue)
        if let enhancedImage = ImageProcessor.enhanceImage(of: currentImage, contrast: sliderValue) {
            updateDisplayedImage(enhancedImage)
            self.currentImage = enhancedImage  // Update the current image with the new contrast adjusted image
        }
    }
    
    func updateMaterialTransparency(_ transparency: CGFloat) {
        for material in materialsToAdjust {
            material.transparency = transparency
        }
    }
    
    func updateDisplayedImage(_ image: NSImage) {
        displayNode?.geometry?.firstMaterial?.diffuse.contents = image
    }
    
    func updateLabelsPositions() {
        guard let timeScaleBar = timeScaleBar else { return }
        
        // Update the position of the endTextNode only
        endTextNode?.position = SCNVector3(x: 0.15, y: -1.5, z: timeScaleBar.position.z + timeScaleBar.boundingBox.max.z)
    }
    
    func updatePlaneDistance(_ distance: CGFloat) {
        planeDistance = distance
        
        for (index, planeNode) in parentNode.childNodes.enumerated() {
            planeNode.position.z = CGFloat(index) * planeDistance
        }
        
        // update the length of the time scale bar
        updateTimeScaleBarLengthAndLabels(duration: duration, totalFrames: totalFrames)
        
        // update the positions of the labels
        updateLabelsPositions()
    }

    func updateTimeScaleBarLengthAndLabels(duration: Float, totalFrames: Int) {
        guard let firstPlane = parentNode.childNodes.first else { return }
        guard let lastPlane = parentNode.childNodes.last else { return }

        // calculate total length of the image planes
        let totalLength = lastPlane.position.z - firstPlane.position.z
        let barWidth = CGFloat(totalLength)

        // ppdate the time scale bar geometry
        if let scaleBarNode = timeScaleBar, let scaleBarGeometry = scaleBarNode.geometry as? SCNPlane {
            scaleBarGeometry.width = barWidth
            scaleBarNode.position = SCNVector3(x: 0, y: -1, z: (firstPlane.position.z + lastPlane.position.z) / 2)
        }

        // reposition the start label
        if let startTextNode = parentNode.childNodes.first(where: { $0.geometry is SCNText && ($0.geometry as! SCNText).string as! String == "0" }) {
            let startZPosition = firstPlane.position.z - CGFloat(timeScaleBar!.geometry!.boundingBox.max.z) - 0.1
            startTextNode.position = SCNVector3(x: 0.15, y: -1.5, z: startZPosition + 0.15)
        }

        // reposition end label
        if let endTextNode = parentNode.childNodes.first(where: { $0.geometry is SCNText && ($0.geometry as! SCNText).string as! String == String(format: "%.2f seconds, %d frames", duration, totalFrames) }) {
            let endZPosition = lastPlane.position.z + CGFloat(timeScaleBar!.geometry!.boundingBox.max.z)
            endTextNode.position = SCNVector3(x: 0.15, y: -1.5, z: endZPosition)
        }

        // reposition scale bar label
        if let scaleBarLabelNode = parentNode.childNodes.first(where: { $0.geometry is SCNText && ($0.geometry as! SCNText).string as! String == "Time Scale Bar" }) {
            scaleBarLabelNode.position = SCNVector3(x: 0.2, y: -1.35, z: (firstPlane.position.z + lastPlane.position.z) / 2)
        }
    }
    
    func updatePlanePositions(with distance: CGFloat) {
        planeDistance = distance
        for (index, planeNode) in parentNode.childNodes.enumerated() {
            planeNode.position.z = CGFloat(index) * planeDistance
        }
    }
    
    @objc
    func handleClick(_ gestureRecognizer: NSGestureRecognizer) {
        // retrieve SCNView
        let scnView = self.view as! SCNView
        
        // check what nodes are clicked
        let p = gestureRecognizer.location(in: scnView)
        let hitResults = scnView.hitTest(p, options: [:])
        // check that at least one object was clicked
        if hitResults.count > 0 {
            // retrieve first clicked object
            let result = hitResults[0]
            // gets material
            let material = result.node.geometry!.firstMaterial!
            
            // highlights
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.5
            
            // unhighlight on completion
            SCNTransaction.completionBlock = {
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.5
                
                material.emission.contents = NSColor.black
                
                SCNTransaction.commit()
            }
            
            material.emission.contents = NSColor.red
            
            SCNTransaction.commit()
        }
    }
    
    @objc func deleteImagePlanes() {
        print("Delete button pressed.")
        for node in parentNode.childNodes {
            print("Removing node: (node)")
        node.removeFromParentNode()
        }
        planeNodes.removeAll()
        materialsToAdjust.removeAll()
        print("All image planes deleted.")
        }
    
    // call VideoProcessor
    func didExtractVideo(_ videoURL: URL) {
        print("Video URL received: \(videoURL)")
        let videoProcessor = VideoProcessor()
        videoProcessor.extractFrames(from: videoURL, frameInterval: 1, maxConcurrentTasks: 4, batchSize: 8) { [weak self] images, frameRate, duration, totalFrames in
            print("Extracted \(images.count) frames from the video.")
            
            // assign duration and totalFrames
            self?.duration = duration
            self?.totalFrames = totalFrames
            
            DispatchQueue.main.async {
                if let scnView = self?.view as? SCNView, let scene = scnView.scene {
                    self?.addImagesAsPlanesToScene(images, in: scene, frameRate: frameRate, duration: duration, totalFrames: totalFrames)
                }
            }
        }
    }
}

extension GameViewController: DragDropViewDelegate {
    func didExtractImages(_ images: [NSImage]) {
        // Handle extracted images if needed
        print("Extracted \(images.count) images.")
    }
    
    

    
    func addImagesAsPlanesToScene(_ images: [NSImage], in scene: SCNScene, frameRate: Float, duration: Float, totalFrames: Int) {
        print("Adding \(images.count) images as planes to the scene.")
        let nodeCount = parentNode.childNodes.count
        let processingQueue = DispatchQueue(label: "imageProcessingQueue", attributes: .concurrent)
        let group = DispatchGroup()
        
        for (index, image) in images.enumerated() {
            processingQueue.async(group: group) {
                let plane: SCNPlane
                let material: SCNMaterial
                let planeNode: SCNNode
                
                if index < nodeCount {
                    planeNode = self.parentNode.childNodes[index]
                    plane = planeNode.geometry as! SCNPlane
                    material = plane.materials.first!
                } else {
                    plane = SCNPlane(width: 1.0, height: 1.0)
                    material = SCNMaterial()
                    plane.materials = [material]
                    planeNode = SCNNode(geometry: plane)
                    self.parentNode.addChildNode(planeNode)
                }
                
                let sliderValue = CGFloat(self.contrastSlider?.doubleValue ?? 1.0)
                if let enhancedImage = ImageProcessor.enhanceImage(of: image, contrast: sliderValue) {
                    DispatchQueue.main.async {
                        material.diffuse.contents = enhancedImage
                        material.lightingModel = .constant
                        material.blendMode = .replace
                        material.isDoubleSided = true
                        material.transparency = 1.0
                        planeNode.position = SCNVector3(x: 0, y: 0, z: CGFloat(index) * self.planeDistance)
                        self.materialsToAdjust.append(material)
                    }
                }
            }
        }
        
        group.notify(queue: .main) {
            self.addTimeScaleBar(frameRate: frameRate, duration: duration, totalFrames: totalFrames)
            self.addLabelsToTimeScaleBar(duration: duration, totalFrames: totalFrames) // Ensure this is called with both duration and totalFrames
            print("All images processed and added to the scene.")
        }
        
        if images.count < nodeCount {
            for i in images.count..<nodeCount {
                parentNode.childNodes[i].removeFromParentNode()
            }
        }
    }
    
    func addLabelsToTimeScaleBar(duration: Float, totalFrames: Int) {
        guard let timeScaleBar = timeScaleBar else { return }
        
        // Create and position the start text node ("0")
        if startTextNode == nil {
            let startTextGeometry = SCNText(string: "0", extrusionDepth: 0.01)
            startTextGeometry.font = NSFont.systemFont(ofSize: 0.3)
            startTextGeometry.firstMaterial?.diffuse.contents = NSColor.white
            
            startTextNode = SCNNode(geometry: startTextGeometry)
            startTextNode!.scale = SCNVector3(0.2, 0.2, 0.2)
            startTextNode!.rotation = SCNVector4(x: 1, y: 8, z: -1, w: .pi / 2)
            // Position at the start of the time scale bar
            startTextNode!.position = SCNVector3(x: 0.15, y: -1.5, z: timeScaleBar.position.z - timeScaleBar.boundingBox.max.z - 2.213)
            parentNode.addChildNode(startTextNode!)
        }
        
        // create and position the scale bar label node ("Time Scale Bar")
        if scaleBarLabelNode == nil {
            let scaleBarLabelGeometry = SCNText(string: "Time Scale Bar", extrusionDepth: 0.01)
            scaleBarLabelGeometry.font = NSFont.systemFont(ofSize: 0.4)
            scaleBarLabelGeometry.firstMaterial?.diffuse.contents = NSColor.yellow
            
            scaleBarLabelNode = SCNNode(geometry: scaleBarLabelGeometry)
            scaleBarLabelNode!.scale = SCNVector3(0.2, 0.2, 0.2)
            scaleBarLabelNode!.rotation = SCNVector4(x: 1, y: 8, z: -1, w: .pi / 2)
            // Position near the center of the time scale bar
            scaleBarLabelNode!.position = SCNVector3(x: 0.2, y: -1.35, z: timeScaleBar.position.z)
            parentNode.addChildNode(scaleBarLabelNode!)
        }
        
        // create and position the end text node (duration and total frames)
        if endTextNode == nil {
            let endTextGeometry = SCNText(string: "", extrusionDepth: 0.01)
            endTextGeometry.font = NSFont.systemFont(ofSize: 0.3)
            endTextGeometry.firstMaterial?.diffuse.contents = NSColor.white
            
            endTextNode = SCNNode(geometry: endTextGeometry)
            endTextNode!.scale = SCNVector3(0.2, 0.2, 0.2)
            endTextNode!.rotation = SCNVector4(x: 1, y: 8, z: -1, w: .pi / 2)
            parentNode.addChildNode(endTextNode!)
        }
        
        // set the initial text for the end node
        let endLabelString = String(format: "%.2f seconds, %d frames", duration, totalFrames)
        (endTextNode!.geometry as! SCNText).string = endLabelString
        
        // initla position of the endTextNode
        endTextNode!.position = SCNVector3(x: 0.15, y: -1.5, z: timeScaleBar.position.z + timeScaleBar.boundingBox.max.z)
    }
    
    func makeTimeScaleBarTwoSided() {
        timeScaleBar?.geometry?.materials.forEach { material in
            material.isDoubleSided = true
        }
    }
    
    func addTimeScaleBar(frameRate: Float, duration: Float, totalFrames: Int) {
        guard let firstPlane = parentNode.childNodes.first else { return }
        guard let lastPlane = parentNode.childNodes.last else { return }
        
        // calculate total length of the image planes
        let totalLength = lastPlane.position.z - firstPlane.position.z
        let barWidth = CGFloat(totalLength)
        let barHeight: CGFloat = 0.1
        
        // create time scale bar geometry and material
        let scaleBarGeometry = SCNPlane(width: barWidth, height: barHeight)
        let scaleBarMaterial = SCNMaterial()
        scaleBarMaterial.diffuse.contents = NSColor.red
        scaleBarGeometry.materials = [scaleBarMaterial]
        
        // create scale bar node
        let scaleBarNode = SCNNode(geometry: scaleBarGeometry)
        // Position it directly below the image planes
        scaleBarNode.position = SCNVector3(x: 0, y: -1, z: (firstPlane.position.z + lastPlane.position.z) / 2)
        // Rotate the bar to align with the planes
        scaleBarNode.rotation = SCNVector4(x: 1, y: 8, z: -1, w: .pi / 2)
        
        // add scale bar node to the parent node
        parentNode.addChildNode(scaleBarNode)
        
        self.timeScaleBar = scaleBarNode
        
        // add labels to the time scale bar
        addLabelsToTimeScaleBar(duration: duration, totalFrames: totalFrames)
        
        makeTimeScaleBarTwoSided()
    }
}
