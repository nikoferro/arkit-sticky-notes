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
import FontAwesome_swift

class ViewController: UIViewController, ARSCNViewDelegate  {

    var titleText: String?
    var noteText: String?
    
    var gridAnimationInProgress = false;
    var noteReadyToPin:Bool = false {
        didSet{
            if noteReadyToPin == true {
                self.addButton.titleLabel?.font = UIFont.fontAwesome(ofSize: 50)
                self.addButton.setTitle(String.fontAwesomeIcon(name: .thumbTack), for: .normal)
            } else {
                self.addButton.titleLabel?.font = UIFont.fontAwesome(ofSize: 50)
                self.addButton.setTitle(String.fontAwesomeIcon(name: .plusCircle), for: .normal)
            }
        }
    };
    
    var currentHitResult: ARHitTestResult?;
    
    @IBOutlet var addButton: UIButton!
    @IBOutlet var sceneView: ARSCNView!
    @IBAction func addButtonTap(_ sender: Any) {
        if self.noteReadyToPin {
            self.addStickyPostToLocation(hitTestResult: self.currentHitResult)
        } else {
            self.showAlertWithOptions()
        }
    }
    
    // -------------------------
    // -------------------------
    // -------------------------
    //  OVERRIDES FUNCS IN CLASS
    // -------------------------
    // -------------------------
    // -------------------------
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.addButton.titleLabel?.font = UIFont.fontAwesome(ofSize: 50)
        self.addButton.setTitle(String.fontAwesomeIcon(name: .plusCircle), for: .normal)
    
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewController.handleTouchInWorld(withGestureRecognizer:)))

        self.sceneView.delegate = self
        self.sceneView.addGestureRecognizer(tapGestureRecognizer)
        self.sceneView.autoenablesDefaultLighting = true
        self.sceneView.automaticallyUpdatesLighting = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        configuration.isLightEstimationEnabled = true
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    // -------------------------
    // -------------------------
    // -------------------------
    //  DELEGATED FUNCS TO CLASS
    // -------------------------
    // -------------------------
    // -------------------------
    
    // CREATES AND ATTACH A HIDDEN PLANE WITH A GRID TO AN ANCHOR
    // IF THERE IS AN ANCHOR W/ A ARPlaneAnchor DETECTED
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        let width = CGFloat(planeAnchor.extent.x)
        let height = CGFloat(planeAnchor.extent.z)
        let plane = SCNPlane(width: width, height: height)
        // CREATE PLANE W/ GRID BACKGROUND
        let imageMaterial = SCNMaterial()
        imageMaterial.diffuse.contents = UIImage(named: "art.scnassets/grid.png")
        imageMaterial.diffuse.contentsTransform = SCNMatrix4MakeScale(12, 12, 0)
        plane.firstMaterial = imageMaterial
        
        let planeNode = SCNNode(geometry: plane)
        
        let x = CGFloat(planeAnchor.center.x)
        let y = CGFloat(planeAnchor.center.y)
        let z = CGFloat(planeAnchor.center.z)
        planeNode.position = SCNVector3(x,y,z)
        planeNode.eulerAngles.x = -.pi / 2
        planeNode.opacity = 0
        planeNode.geometry?.firstMaterial?.diffuse.wrapS = SCNWrapMode.repeat
        planeNode.geometry?.firstMaterial?.diffuse.wrapT = SCNWrapMode.repeat
        
        node.addChildNode(planeNode)
        
    }
    // UPDATES HIDDEN GRID W/ NEW WORLD DATA, AND ANIMATES IF POSSIBLE
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as?  ARPlaneAnchor,
            let planeNode = node.childNodes.first,
            let plane = planeNode.geometry as? SCNPlane
            else { return }
        
        let width = CGFloat(planeAnchor.extent.x)
        let height = CGFloat(planeAnchor.extent.z)
        plane.width = width
        plane.height = height
        
        let x = CGFloat(planeAnchor.center.x)
        let y = CGFloat(planeAnchor.center.y)
        let z = CGFloat(planeAnchor.center.z)
        planeNode.position = SCNVector3(x, y, z)
        self.animateGridIfPossible(planeNode: planeNode)
    }
    
    // ------------------------
    // ------------------------
    // ------------------------
    //  CUSTOM FUNCS FROM CLASS
    // ------------------------
    // ------------------------
    // ------------------------
    
    func showAlertWithOptions() {
        let alert = UIAlertController(title: "Hi!", message: "Select the type of note you wish to create", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Text Note", style: .default, handler: { action in self.onTextNoteOptionSelected()
        }))
        alert.addAction(UIAlertAction(title: "Image Note", style: .default, handler: nil))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func onTextNoteOptionSelected() {
        self.performSegue(withIdentifier: "ShowAddNoteViewController", sender: self)
    }
    
    @objc func handleTouchInWorld(withGestureRecognizer recognizer: UIGestureRecognizer) {
        let tapLocation = recognizer.location(in: sceneView)
        let hitTestResults = sceneView.hitTest(tapLocation, types: .existingPlaneUsingExtent)

        guard let hitTestResult = hitTestResults.first else { return }
        self.currentHitResult = hitTestResult
    }
    
    func onNoteAdded(title: String, note: String) {
        self.noteReadyToPin = true
        self.titleText = title
        self.noteText = note
    }
    
    func animateGridIfPossible(planeNode: SCNNode) {
        if (self.noteReadyToPin == true && self.gridAnimationInProgress == false) {
            self.gridAnimationInProgress = true
            
            let opacityUp = SCNAction.fadeOpacity(to: 1, duration: 0.5)
            let opacityDown = SCNAction.fadeOpacity(to: 0, duration: 0.5)
            let sequence = SCNAction.sequence([opacityUp,opacityDown])
            let opacityLoop = SCNAction.repeat(sequence, count: 1)
            
            planeNode.runAction(opacityLoop, completionHandler: {
                self.gridAnimationInProgress = false
            })
        }
    }
    
    // ADDS THE NOTE TO THE WORLD IF THE HIT TEST
    func addStickyPostToLocation(hitTestResult: ARHitTestResult?) {
        guard let translation = hitTestResult?.worldTransform.columns.3 else { return }
        guard let planeAnchor = hitTestResult?.anchor else { return }
        let isVertical = (hitTestResult?.anchor as? ARPlaneAnchor)?.alignment == ARPlaneAnchor.Alignment.vertical
        
        // STYLING
        let skScene = SKScene(size: CGSize(width: 200, height: 200))
        skScene.backgroundColor = UIColor.clear
        
        let rectangle = SKShapeNode(rect: CGRect(x: 0, y: 0, width: 200, height: 200), cornerRadius: 10)
        
        rectangle.fillColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        rectangle.fillTexture = SKTexture.init(image: UIImage(named: "art.scnassets/sticky.png")!)
        rectangle.alpha = 1
        rectangle.lineWidth = 0
        
        let labelNode = SKLabelNode(text: self.noteText)
        labelNode.fontSize = 14
        labelNode.position = CGPoint(x:100,y:100)
        labelNode.fontColor = UIColor.init(hexString: "#000000")
        skScene.addChild(rectangle)
        skScene.addChild(labelNode)
        
        let plane = SCNPlane(width: 0.25, height: 0.25)
        let material = SCNMaterial()
        material.isDoubleSided = true
        material.diffuse.contents = skScene
        
        // if vertical, it needs to rotate
        if (isVertical) {
            material.diffuse.contentsTransform = SCNMatrix4Translate(SCNMatrix4MakeScale(1, -1, 1), 0, 1, 0)
        }
        
        plane.materials = [material]
        let node = SCNNode(geometry: plane)
        
        // POSITIONING
        let x = translation.x
        let y = translation.y
        let z = translation.z
        
        guard let anchoredNode =  sceneView.node(for: planeAnchor) else { return }
        
        let anchorNodeOrientation = anchoredNode.worldOrientation
        
        node.position = SCNVector3(x,y,z)
        if (isVertical) {
            node.eulerAngles.y = .pi * anchorNodeOrientation.y
        } else {
            node.eulerAngles.x = Float.pi / 2
            node.eulerAngles.y = Float.pi * anchorNodeOrientation.y
        }
        
        sceneView.scene.rootNode.addChildNode(node)
        self.resetValues()
        
    }
    // RESET VALUES TO DEFAULT
    func resetValues() {
        self.noteReadyToPin = false
        self.currentHitResult = nil
        self.titleText = ""
        self.noteText = ""
    }
}
