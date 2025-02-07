//
//  ViewController.swift
//  AR-Portal
//
//  Created by Quentin Faure on 05/12/2017.
//  Copyright © 2017 Quentin Faure. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {
    @IBOutlet weak var planeSearchLabel: UILabel!
    @IBOutlet weak var sceneView: ARSCNView!
    
    // State
    private func updatePlaneOverlay() {
        DispatchQueue.main.async {
            
            self.planeSearchLabel.isHidden = self.currentPlane != nil
            
            if self.planeCount == 0 {
                self.planeSearchLabel.text = "Move around to allow the app the find a plane..."
            } else {
                self.planeSearchLabel.text = "Tap on a plane surface to place board..."
            }
            
        }
    }
    
    var planeCount = 0 {
        didSet {
            updatePlaneOverlay()
        }
    }
    var currentPlane:SCNNode? {
        didSet {
            updatePlaneOverlay()
        }
    }
    
    var animations = [String: CAAnimation]()
    var idle:Bool = true
    
    func loadAnimation(withKey: String, sceneName:String, animationIdentifier:String) {
        let sceneURL = Bundle.main.url(forResource: sceneName, withExtension: "dae")
        let sceneSource = SCNSceneSource(url: sceneURL!, options: nil)
        
        if let animationObject = sceneSource?.entryWithIdentifier(animationIdentifier, withClass: CAAnimation.self) {
            // The animation will only play once
            animationObject.repeatCount = 1
            // To create smooth transitions between animations
            animationObject.fadeInDuration = CGFloat(1)
            animationObject.fadeOutDuration = CGFloat(0.5)
            
            // Store the animation for later use
            animations[withKey] = animationObject
        }
    }

    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.session.delegate = self
        sceneView.automaticallyUpdatesLighting = false
        
        let tap = UITapGestureRecognizer()
        tap.addTarget(self, action: #selector(didTap))
        sceneView.addGestureRecognizer(tap)
    }
    
    
    // this func from Apple ARKit placing objects demo
    func enableEnvironmentMapWithIntensity(_ intensity: CGFloat) {
        if sceneView.scene.lightingEnvironment.contents == nil {
            if let environmentMap = UIImage(named: "Media.scnassets/environment_blur.exr") {
                sceneView.scene.lightingEnvironment.contents = environmentMap
            }
        }
        sceneView.scene.lightingEnvironment.intensity = intensity
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        configuration.isLightEstimationEnabled = true
        
        sceneView.session.run(configuration)
    }
    
    func loadAnimations () {
        // Load the character in the idle animation
        let idleScene = SCNScene(named: "fixed.dae")!
        let logoScene = SCNScene(named: "strangerthings.dae")!
        
        
        
        
        
        // This node will be parent of all the animation models
        let node = SCNNode()
        node.name = "demogorgon"
        let logoNode = SCNNode()
        logoNode.name = "logo"
        
        // Add all the child nodes to the parent node
        for child in idleScene.rootNode.childNodes {
            node.addChildNode(child)
        }
        
        for child in logoScene.rootNode.childNodes {
            logoNode.addChildNode(child)
        }
        
        // Set up some properties
        node.scale = SCNVector3(0.009, 0.009, 0.009)
        node.position = SCNVector3(-0.9, 0, 0)
        logoNode.scale = SCNVector3(0.003, 0.003, 0.003)
        logoNode.position = SCNVector3(-0.5, 1.3, -1)
        
        node.renderingOrder = 200
        logoNode.renderingOrder = 200
        
        //            let maskingXSegment = SCNBox(width: CGFloat(2),
        //                                            height: CGFloat(2.2),
        //                                            length: CGFloat(1),
        //                                            chamferRadius: 0)
        //            maskingXSegment.firstMaterial?.diffuse.contents = UIColor.red
        //            maskingXSegment.firstMaterial?.transparency = 0.000001
        //            maskingXSegment.firstMaterial?.writesToDepthBuffer = true
        //
        //            let maskingXSegmentNode = SCNNode(geometry: maskingXSegment)
        //            maskingXSegmentNode.renderingOrder = 100   //everything inside the portal area must have higher rendering order...
        //
        //
        //            maskingXSegmentNode.position = SCNVector3(true ? CGFloat(2) : -CGFloat(0.02),0,0)
        //
        //            let maskingYSegment = SCNBox(width: CGFloat(2.2) * CGFloat(3),
        //                                         height: CGFloat(2.2) * CGFloat(3),
        //                                         length: CGFloat(1) * CGFloat(3),
        //                                         chamferRadius: 0)
        //            maskingYSegment.firstMaterial?.diffuse.contents = UIColor.red
        //            maskingYSegment.firstMaterial?.transparency = 0.000001
        //            maskingYSegment.firstMaterial?.writesToDepthBuffer = true
        //
        //            let maskingYSegmentNode = SCNNode(geometry: maskingYSegment)
        //            maskingYSegmentNode.renderingOrder = 100   //everything inside the portal area must have higher rendering order...
        //
        //
        //            maskingYSegmentNode.position = SCNVector3(CGFloat(2) * 0.5, true ? CGFloat(0.02) : -CGFloat(0.02),0)
        //            let wrapNode = SCNNode()
        //            wrapNode.addChildNode(maskingXSegmentNode)
        //            wrapNode.addChildNode(maskingYSegmentNode)
        //            wrapNode.addChildNode(node)
        
        // Add the node to the scene
        let floorNode = sceneView.scene.rootNode.childNode(withName: "floor", recursively: true)
        floorNode?.addChildNode(node)
        floorNode?.addChildNode(logoNode)
        
        
        // Load all the DAE animations
        loadAnimation(withKey: "test", sceneName: "fixed", animationIdentifier: "fixed-1")
    }
    
    
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        sceneView.session.pause()
    }
    
    private func anyPlaneFrom(location:CGPoint) -> (SCNNode, SCNVector3)? {
        let results = sceneView.hitTest(location,
                                        types: ARHitTestResult.ResultType.existingPlaneUsingExtent)
        
        print("anyPlaneFrom results \(results)")
        guard results.count > 0,
              let anchor = results[0].anchor,
              let node = sceneView.node(for: anchor) else { return nil }
        
        return (node, SCNVector3.positionFromTransform(results[0].worldTransform))
    }
    
    @objc func didTap(_ sender:UITapGestureRecognizer) {
        let location = sender.location(in: sceneView)
        
        print("didTap \(location)")
        
        guard currentPlane == nil,
              let newPlaneData = anyPlaneFrom(location: location) else { return }
        
        
        print("adding wall???")
        currentPlane = newPlaneData.0
        
        
        let wallNode = SCNNode()
        wallNode.name = "wallNode"
        wallNode.position = newPlaneData.1
        
        
        let sideLength = Nodes.WALL_LENGTH * 3
        let halfSideLength = sideLength * 0.5
        
        let endWallSegmentNode = Nodes.wallSegmentNode(length: sideLength,
                                                       maskXUpperSide: true)
        endWallSegmentNode.eulerAngles = SCNVector3(0, 90.0.degreesToRadians, 0)
        endWallSegmentNode.position = SCNVector3(0, Float(Nodes.WALL_HEIGHT * 0.5), Float(Nodes.WALL_LENGTH) * -1.5)
        wallNode.addChildNode(endWallSegmentNode)
        
        let sideAWallSegmentNode = Nodes.wallSegmentNode(length: sideLength,
                                                       maskXUpperSide: true)
        sideAWallSegmentNode.eulerAngles = SCNVector3(0, 180.0.degreesToRadians, 0)
        sideAWallSegmentNode.position = SCNVector3(Float(Nodes.WALL_LENGTH) * -1.5, Float(Nodes.WALL_HEIGHT * 0.5), 0)
        wallNode.addChildNode(sideAWallSegmentNode)
        
        let sideBWallSegmentNode = Nodes.willSegmentNode(length: sideLength,
                                                         maskXUpperSide: true)
        sideBWallSegmentNode.position = SCNVector3(Float(Nodes.WALL_LENGTH) * 1.5, Float(Nodes.WALL_HEIGHT * 0.5), 0)
        wallNode.addChildNode(sideBWallSegmentNode)
        
        let doorSideLength = (sideLength - Nodes.DOOR_WIDTH) * 0.5
        
        let leftDoorSideNode = Nodes.wallSegmentNode(length: doorSideLength,
                                                     maskXUpperSide: true)
        leftDoorSideNode.eulerAngles = SCNVector3(0, 270.0.degreesToRadians, 0)
        leftDoorSideNode.position = SCNVector3(Float(-halfSideLength + 0.5 * doorSideLength),
                                               Float(Nodes.WALL_HEIGHT) * Float(0.5),
                                               Float(Nodes.WALL_LENGTH) * 1.5)
        wallNode.addChildNode(leftDoorSideNode)
        
        let rightDoorSideNode = Nodes.wallSegmentNode(length: doorSideLength,
                                                     maskXUpperSide: true)
        rightDoorSideNode.eulerAngles = SCNVector3(0, 270.0.degreesToRadians, 0)
        rightDoorSideNode.position = SCNVector3(Float(halfSideLength - 0.5 * doorSideLength),
                                                Float(Nodes.WALL_HEIGHT) * Float(0.5),
                                                Float(Nodes.WALL_LENGTH) * 1.5)
        wallNode.addChildNode(rightDoorSideNode)
        
        let aboveDoorNode = Nodes.wallSegmentNode(length: Nodes.DOOR_WIDTH,
                                                  height: Nodes.WALL_HEIGHT - Nodes.DOOR_HEIGHT)
        aboveDoorNode.eulerAngles = SCNVector3(0, 270.0.degreesToRadians, 0)
        aboveDoorNode.position = SCNVector3(0,
                                            Float(Nodes.WALL_HEIGHT) - Float(Nodes.WALL_HEIGHT - Nodes.DOOR_HEIGHT) * 0.5,
                                            Float(Nodes.WALL_LENGTH) * 1.5)
        wallNode.addChildNode(aboveDoorNode)
        
        let floorNode = Nodes.plane(pieces: 3,
                                    maskYUpperSide: false)
        floorNode.name = "floor"
        floorNode.position = SCNVector3(0, 0, 0)
    
        
        loadAnimations()
        wallNode.addChildNode(floorNode)
        
        let roofNode = Nodes.plane(pieces: 3,
                                   maskYUpperSide: true)
        roofNode.position = SCNVector3(0, Float(Nodes.WALL_HEIGHT), 0)
        
        // Load the character in the idle animation
        let logoSCN = SCNScene(named: "strangerthings.dae")!
        
        // This node will be parent of all the animation models
        let logoNode = SCNNode()
        
        for child in logoSCN.rootNode.childNodes {
            logoNode.addChildNode(child)
        }
        
        
        // Set up some properties
        logoNode.scale = SCNVector3(0.01, 0.01, 0.01)
        logoNode.renderingOrder = 200
        
        roofNode.addChildNode(logoNode)
        
        let rainNode = Nodes.plane(pieces: 3,
                                   maskYUpperSide: true)
        rainNode.position = SCNVector3(0, Float(Nodes.WALL_HEIGHT - CGFloat(0.1)), 0)

//        let particleSystem = SCNParticleSystem(named: "rain2", inDirectory: nil)
//        rainNode.addParticleSystem(particleSystem!)

//        roofNode.addChildNode(particlesNode)
//        sceneView.scene = scene

//        wallNode.addChildNode(roofNode)
        wallNode.addChildNode(rainNode)
        
        sceneView.scene.rootNode.addChildNode(wallNode)
        
        
        // we would like shadows from inside the portal room to shine onto the floor of the camera image(!)
        let floor = SCNFloor()
        floor.reflectivity = 0
        floor.firstMaterial?.diffuse.contents = UIColor.white
        floor.firstMaterial?.colorBufferWriteMask = SCNColorMask(rawValue: 0)
        let floorShadowNode = SCNNode(geometry:floor)
        floorShadowNode.position = newPlaneData.1
        sceneView.scene.rootNode.addChildNode(floorShadowNode)
        
        
        let light = SCNLight()
        // [SceneKit] Error: shadows are only supported by spot lights and directional lights
        light.type = .ambient
        light.spotInnerAngle = 120
        light.spotOuterAngle = 180
        light.zNear = 0.01
        light.zFar = 10
        light.castsShadow = true
        light.shadowRadius = 200
        light.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.1)
        light.shadowMode = .deferred
        let constraint = SCNLookAtConstraint(target: floorShadowNode)
        constraint.isGimbalLockEnabled = true
        let lightNode = SCNNode()
        lightNode.light = light
        lightNode.position = SCNVector3(newPlaneData.1.x,
                                        newPlaneData.1.y + Float(Nodes.DOOR_HEIGHT),
                                        newPlaneData.1.z - Float(Nodes.WALL_LENGTH))
        lightNode.constraints = [constraint]
        sceneView.scene.rootNode.addChildNode(lightNode)
        
        
        
    }
    
    var animate: Bool = false
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // Do something with the new transform
        let currentTransform = frame.camera.transform
        let currentTransformSCN = SCNMatrix4(currentTransform)
        
//        print("cam \(currentTransform)")
//        for child in sceneView.scene.rootNode.childNodes{
//            print(child)
//        }
        let cameraNode = SCNNode();
        cameraNode.transform = currentTransformSCN
        print(cameraNode.position)
        
        
        if let wallNode = sceneView.scene.rootNode.childNode(withName: "wallNode", recursively: true) {
            print("node position \(wallNode.position)")

            let x = abs(cameraNode.position.x - wallNode.position.x)
            let z = abs(cameraNode.position.z - wallNode.position.z)
            if x > 1.5 || z > 1.5 {
                print("out")
                let demogorgonNode = sceneView.scene.rootNode.childNode(withName: "demogorgon", recursively: true)
                let logoNode = sceneView.scene.rootNode.childNode(withName: "logo", recursively: true)
                demogorgonNode?.removeFromParentNode()
                logoNode?.removeFromParentNode()
                animate = false
            } else {
                print("in")
                if animate {
                    
                } else {
                    loadAnimations()
                    animate = true
                }
            }
        
//            print("node x \(x)")
//            print("node z \(z)")
        }

        
        
    }
    
    /// MARK: - ARSCNViewDelegate
    
    // this func from Apple ARKit placing objects demo
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        // from apples app
        DispatchQueue.main.async {
            // If light estimation is enabled, update the intensity of the model's lights and the environment map
            if let lightEstimate = self.sceneView.session.currentFrame?.lightEstimate {
                
                // Apple divived the ambientIntensity by 40, I find that, atleast with the materials used
                // here that it's a big too bright, so I increased to to 50..
                self.enableEnvironmentMapWithIntensity(lightEstimate.ambientIntensity / 50)
            } else {
                self.enableEnvironmentMapWithIntensity(25)
            }
        }
    }
    
    // did at plane(?)
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        planeCount += 1
    }
    
    // did update plane?
    func renderer(_ renderer: SCNSceneRenderer, willUpdate node: SCNNode, for anchor: ARAnchor) {
        
    }
    
    // did remove plane?
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        if node == currentPlane {
            //TODO: cleanup
        }
        
        if planeCount > 0 {
            planeCount -= 1
        }
    }
    

}
