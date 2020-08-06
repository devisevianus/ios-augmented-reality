//
//  ViewController.swift
//  AugmentedRealityApp
//
//  Created by Devis Evianus on 29/10/18.
//  Copyright © 2018 stickearn. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var imageAd1: UIImageView!
    @IBOutlet weak var imageAd2: UIImageView!
    @IBOutlet weak var imageAd3: UIImageView!
    
    var nodeModel: SCNNode!
    let nodeName = "avanza"
    
    var currentAngleY: Float = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imageAd1.isHidden = true
        imageAd2.isHidden = true
        imageAd3.isHidden = true
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        
        // Create a new scene
        let scene = SCNScene()
        
        // Set the scene to the view
        sceneView.scene = scene
        
        let zoomGesture = UIPinchGestureRecognizer(target: self, action: #selector(didPinch(_:)))
        sceneView.addGestureRecognizer(zoomGesture)
        
        let rotateGesture = UIPanGestureRecognizer(target: self, action: #selector(didPan(_:)))
        sceneView.addGestureRecognizer(rotateGesture)
        
        let tapFruitTea = UITapGestureRecognizer(target: self, action: #selector(changeAdFruitTea(_:)))
        imageAd1.isUserInteractionEnabled = true
        imageAd1.addGestureRecognizer(tapFruitTea)
        
        let tapGlico = UITapGestureRecognizer(target: self, action: #selector(changeAdGlico(_:)))
        imageAd2.isUserInteractionEnabled = true
        imageAd2.addGestureRecognizer(tapGlico)
        
        let tapOppo = UITapGestureRecognizer(target: self, action: #selector(changeOppo(_:)))
        imageAd3.isUserInteractionEnabled = true
        imageAd3.addGestureRecognizer(tapOppo)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }

    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        DispatchQueue.main.async {
            self.infoLabel.text = "Surface Detected."
        }
        
        let carScene = SCNScene(named: nodeName, inDirectory: "art.scnassets/avanza")
        nodeModel = carScene?.rootNode.childNode(withName: nodeName, recursively: true)
        nodeModel.simdPosition = float3(planeAnchor.center.x, planeAnchor.center.y, planeAnchor.center.z)
        sceneView.scene.rootNode.addChildNode(nodeModel)
        node.addChildNode(nodeModel)
        
        imageAd1.isHidden = false
        imageAd2.isHidden = false
        imageAd3.isHidden = false
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        infoLabel.text = "Session failed: \(error.localizedDescription)"
        resetTracking()
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        switch camera.trackingState {
        case .normal :
            infoLabel.text = "Move the device to detect horizontal surfaces."
            
        case .notAvailable:
            infoLabel.text = "Tracking not available."
            
        case .limited(.excessiveMotion):
            infoLabel.text = "Tracking limited - Move the device more slowly."
            
        case .limited(.insufficientFeatures):
            infoLabel.text = "Tracking limited - Point the device at an area with visible surface detail."
            
        case .limited(.initializing):
            infoLabel.text = "Initializing AR session."
            
        default:
            infoLabel.text = ""
        }
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        infoLabel.text = "Session was interrupted"
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        infoLabel.text = "Session interruption ended"
        resetTracking()
    }
    
    func resetTracking() {
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        
        // Run the view's session
        sceneView.session.run(configuration)
        
        imageAd1.isHidden = true
        imageAd2.isHidden = true
        imageAd3.isHidden = true
    }
    
    @objc func didPinch(_ gesture: UIPinchGestureRecognizer) {
        guard let _ = nodeModel else {
            return
        }
        
        var originalScale = nodeModel?.scale
        
        switch gesture.state {
        case .began:
            originalScale = nodeModel?.scale
            gesture.scale = CGFloat((nodeModel?.scale.x)!)
        case .changed:
            guard var newScale = originalScale else {
                return
            }
            
            newScale = SCNVector3(gesture.scale, gesture.scale, gesture.scale)
            
            nodeModel?.scale = newScale
        case .ended:
            guard var newScale = originalScale else {
                return
            }
            
            newScale = SCNVector3(gesture.scale, gesture.scale, gesture.scale)
            
            nodeModel?.scale = newScale
            gesture.scale = CGFloat((nodeModel?.scale.x)!)
        default:
            gesture.scale = 1.0
            originalScale = nil
        }
    }
    
    @objc func didPan(_ gesture: UIPanGestureRecognizer) {
        guard let _ = nodeModel else {
            return
        }
        
        let translation = gesture.translation(in: gesture.view)
        var newAngleY = (Float)(translation.x)*(Float)(Double.pi)/180.0
        
        newAngleY += currentAngleY
        nodeModel?.eulerAngles.y = newAngleY
        
        if gesture.state == .ended {
            currentAngleY = newAngleY
        }
    }
    
    @objc func changeAdFruitTea(_ gesture: UITapGestureRecognizer) {
        nodeModel?.childNode(withName: "ID908", recursively: true)?.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "art.scnassets/avanza/avanza/fruittea.jpg")
    }
    
    @objc func changeAdGlico(_ gesture: UITapGestureRecognizer) {
        nodeModel?.childNode(withName: "ID908", recursively: true)?.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "art.scnassets/avanza/avanza/glico.png")
    }
    
    @objc func changeOppo(_ gesture: UITapGestureRecognizer) {
        nodeModel?.childNode(withName: "ID908", recursively: true)?.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "opporaisa1")
    }
}

extension float4x4 {
    var translation: float3 {
        let translation = self.columns.3
        return float3(translation.x, translation.y, translation.z)
    }
}
