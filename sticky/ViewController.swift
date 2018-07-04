//
//  ViewController.swift
//  sticky
//
//  Created by Nicolas Ferro on 01/07/2018.
//  Copyright © 2018 Nicolas Ferro. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate, UITextFieldDelegate {

    var noteText: String?;
    var currentHitResult: ARHitTestResult?;
    
    @IBOutlet weak var textField: UITextField!
    @IBOutlet var sceneView: ARSCNView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewController.handleTouchInWorld(withGestureRecognizer:)))
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        self.textField.delegate = self
        self.sceneView.delegate = self
        
        self.sceneView.addGestureRecognizer(tapGestureRecognizer)
        self.sceneView.autoenablesDefaultLighting = true
        self.sceneView.automaticallyUpdatesLighting = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .vertical
        configuration.isLightEstimationEnabled = true
        // Run the view's session
        sceneView.session.run(configuration)
        print("ENABLED")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
        print("PAUSED")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        // ON EACH FRAME SEARCH FOR A PLANE
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        self.renderPlane(anchor: planeAnchor, node: node)
        print("Found plane: \(planeAnchor)")
    }
    
    func renderPlane(anchor: ARPlaneAnchor, node: SCNNode) {
        let plane: SCNPlane
        plane = SCNPlane(width: CGFloat(anchor.extent.x), height: CGFloat(anchor.extent.z))
        plane.cornerRadius = 0.005
        let planeNode = SCNNode(geometry: plane)
        planeNode.position = SCNVector3Make(anchor.center.x, 0, anchor.center.z)
        planeNode.eulerAngles.x = -.pi / 2
        planeNode.opacity = 0.15
        node.addChildNode(planeNode)
    }
    
    @objc func handleTouchInWorld(withGestureRecognizer recognizer: UIGestureRecognizer) {
        let tapLocation = recognizer.location(in: sceneView)
        let hitTestResults = sceneView.hitTest(tapLocation, types: .existingPlaneUsingExtent)
        
        guard let hitTestResult = hitTestResults.first else { return }
        self.currentHitResult = hitTestResult
        self.openModalPromptForNote()
   
    }
    func openModalPromptForNote() {
        print("STARTING TO OPEN MODAL")
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let myModalViewController = storyboard.instantiateViewController(withIdentifier: "AddNoteViewController")
        myModalViewController.modalPresentationStyle = UIModalPresentationStyle.fullScreen
        myModalViewController.modalTransitionStyle = UIModalTransitionStyle.coverVertical
        self.present(myModalViewController, animated: true, completion: nil)
    }
    
    func onClosedModalPromptForNote() {
        print("FINISHED CLOSING MODAL")
        guard let text = self.noteText else { return }
        self.addStickyPostToLocation(hitTestResult: self.currentHitResult, text: text)
    }
    
    func addStickyPostToLocation(hitTestResult: ARHitTestResult?, text: String) {
        // IF HIT TEST RESULT IS VALID, ADD THE NOTE TO THE WORLD
        guard let translation = hitTestResult?.worldTransform.columns.3 else { return }
        guard let planeAnchor = hitTestResult?.anchor as? ARPlaneAnchor else { return }
        
        let x = translation.x
        let y = translation.y
        let z = translation.z
        
        let skScene = SKScene(size: CGSize(width: 200, height: 200))
        skScene.backgroundColor = UIColor.clear
        
        let rectangle = SKShapeNode(rect: CGRect(x: 0, y: 0, width: 200, height: 200), cornerRadius: 10)
        
        rectangle.fillColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        rectangle.fillTexture = SKTexture.init(image: UIImage(named: "art.scnassets/sticky.png")!)
        rectangle.alpha = 1
        rectangle.lineWidth = 0
        
        
        let labelNode = SKLabelNode(text: text)
        labelNode.fontSize = 14
        labelNode.position = CGPoint(x:100,y:100)
        skScene.addChild(rectangle)
        skScene.addChild(labelNode)
        
        let plane = SCNPlane(width: 0.25, height: 0.25)
        let material = SCNMaterial()
        material.isDoubleSided = true
        material.diffuse.contents = skScene
        material.diffuse.contentsTransform = SCNMatrix4Translate(SCNMatrix4MakeScale(1, -1, 1), 0, 1, 0)
        plane.materials = [material]
        let node = SCNNode(geometry: plane)
        
        
        guard let anchoredNode =  sceneView.node(for: planeAnchor) else { return }
        
        let anchorNodeOrientation = anchoredNode.worldOrientation
        node.position = SCNVector3(x,y,z)
        node.eulerAngles.y = .pi * anchorNodeOrientation.y
        
        sceneView.scene.rootNode.addChildNode(node)
        
        // RESET VALUES TO DEFAULT
        self.currentHitResult = nil
        self.noteText = nil
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        print("RETURN GO HIT")
        self.noteText = textField.text
        textField.resignFirstResponder()
        return false
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        print("keyboardWillShow")
        print(self.view.frame.origin.y)
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y == 0{
                self.view.frame.origin.y -= keyboardSize.height
            }
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        print("keyboardWillHide")
        print(self.view.frame.origin.y)
        if ((notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue) != nil {
            self.view.frame.origin.y = 0
        }
    }
}
