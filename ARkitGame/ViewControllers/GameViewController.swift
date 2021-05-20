//
//  GameViewController.swift
//  ARkitGame
//
//  Created by Mansi Vadodariya on 10/02/21.
//

import UIKit
import SceneKit
import ARKit

struct GameConstants {
    static let availableShots: Int = 6
    static let remainingBoxes: Int = 6
}

class GameViewController: UIViewController {
    
    // MARK: -
    // MARK: - Outlets
    
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var lblAvailable: UILabel!
    @IBOutlet weak var lblRemaining: UILabel!
    @IBOutlet weak var imgAvailableBG: UIImageView!
    @IBOutlet weak var imgRemainingBG: UIImageView!
    
    // MARK: -
    // MARK: - Variables & Declarations
    
    var trackerNode: SCNNode?
    var foundSurface = false
    var directionalLightNode: SCNNode?
    var ambientLightNode: SCNNode?
    var tracking = true
    var availableShots = GameConstants.availableShots
    var remainingBoxes = GameConstants.remainingBoxes
    var planeNode: SCNNode?
    var modelRootB: SCNNode?
    
    // MARK: -
    // MARK: - ViewController Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initialSetup()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        // Detect horizontal planes in the scene
        configuration.planeDetection = .horizontal
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if tracking {
            //Set up the scene
            guard foundSurface else { return }
            trackerNode?.removeFromParentNode()
            addContainer()
            sceneView.scene.physicsWorld.contactDelegate = self
            tracking = false
        } else {
            //Handle the shooting
            guard let frame = sceneView.session.currentFrame else {
                return
            }
            let camMatrix = SCNMatrix4(frame.camera.transform)
            let direction = SCNVector3Make(-camMatrix.m31 * 5.0, -camMatrix.m32 * 10.0, -camMatrix.m33 * 5.0)
            let position = SCNVector3Make(camMatrix.m41, camMatrix.m42, camMatrix.m43)
            
            let ball = SCNSphere(radius: 0.06)
            ball.firstMaterial?.diffuse.contents = UIImage(named: "greenTexture")
            ball.firstMaterial?.emission.contents = UIImage(named: "greenTexture")
            let ballNode = SCNNode(geometry: ball)
            ballNode.name = "Ball"
            ballNode.position = position
            ballNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
            ballNode.physicsBody?.categoryBitMask = 3
            ballNode.physicsBody?.contactTestBitMask = 1
            sceneView.scene.rootNode.addChildNode(ballNode)
            ballNode.runAction(SCNAction.sequence([SCNAction.wait(duration: 10.0), SCNAction.removeFromParentNode()]))
            let velocityInLocalSpace = SCNVector3(0, 0, -0.15)
            let velocityInWorldSpace = ballNode.presentation.convertVector(velocityInLocalSpace, to: nil)
            ballNode.physicsBody?.velocity = velocityInWorldSpace
            ballNode.physicsBody?.applyForce(direction, asImpulse: true)
            
            // Shot gets fired here
            didFiredShot()
            if self.planeNode != nil {
                planeNode?.removeFromParentNode()
                planeNode = nil
            }
        }
    }
    
    // MARK: -
    // MARK: - Internal setup functions
    
    fileprivate func initialSetup() {
        // Set the view's delegate
        sceneView.delegate = self
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        // Create a new scene
        let scene = SCNScene(named: "art.scnassets/scene.scn")!
        // Set the scene to the view
        sceneView.scene = scene
        
        [imgAvailableBG, imgRemainingBG].forEach { imageView in
            if let imageView = imageView {
                imageView.layer.cornerRadius = 5.0
                imageView.clipsToBounds = true
            }
        }
        clearTexts()
    }
    
    /// Add Root Container to Scene
    func addContainer() {
        guard let backboardScene = SCNScene(named: "art.scnassets/scene.scn") else {
            return
        }
        guard let backBoardNode = backboardScene.rootNode.childNode(withName: "container", recursively: true) else {
            return
        }
        backBoardNode.isHidden = false
        sceneView.scene.rootNode.addChildNode(backBoardNode)
        resetGame()
        addChildNode()
    }
    
    /// Add Boxes
    func addChildNode() {
        addBoxNodes(index: 0, position: SCNVector3(0, -0.138, -0.3))
        addBoxNodes(index: 1, position: SCNVector3(0.12, -0.138, -0.3))
        addBoxNodes(index: 2, position: SCNVector3(0.24, -0.138, -0.3))
        addBoxNodes(index: 3, position: SCNVector3(0.06, -0.038, -0.3))
        addBoxNodes(index: 4, position: SCNVector3(0.18, -0.038, -0.3))
        addBoxNodes(index: 5, position: SCNVector3(0.12, 0.062, -0.3))
        
        planeNode = SCNNode()
        if let planeNode = planeNode {
            planeNode.name = "Plane"
            planeNode.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
            planeNode.geometry = SCNBox(width: 0.4, height: 0.015, length: 0.3, chamferRadius: 0)
            planeNode.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "gridDash")
            planeNode.position = SCNVector3(0.125, -0.2, -0.28)
            self.sceneView.scene.rootNode.addChildNode(planeNode)
        }
    }
    
    /// Add boxes inside scene view
    /// - Parameters:
    ///   - index: Index
    ///   - position: Position
    func addBoxNodes(index: Int, position: SCNVector3) {
        let node = SCNNode()
        node.name = "Node\(index)"
        node.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
        node.geometry = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0)
        node.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "box")
        node.position = position
        node.physicsBody?.contactTestBitMask = 1
        self.sceneView.scene.rootNode.addChildNode(node)
    }
    
}// End of Class

// MARK: -
// MARK: - Game Logic

extension GameViewController {
    
    /// Reset Game
    func resetGame() {
        availableShots = GameConstants.availableShots
        remainingBoxes = GameConstants.remainingBoxes
        setTexts()
        showHideViews(shouldShow: true)
    }
    
    /// Show Hide views based on game state
    /// - Parameter shouldShow: shouldShow
    func showHideViews(shouldShow: Bool) {
        [lblAvailable, lblRemaining, imgAvailableBG, imgRemainingBG].forEach {
            if let subView = $0 {
                subView.isHidden = !shouldShow
            }
        }
    }
    
    /// Setup shots count text
    func setTexts() {
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else { return }
            self.lblRemaining.text = "Remaining Boxes: \(self.remainingBoxes)"
            self.lblAvailable.text = "Available Shots: \(self.availableShots)"
        }
    }
    
    /// Clear texts
    func clearTexts() {
        lblRemaining.text = ""
        lblAvailable.text = ""
        showHideViews(shouldShow: false)
    }
    
    /// This will be called once shot is fired
    /// - Parameter manageShotForSingle: manage shot for single remaining item
    func didFiredShot(manageShotForSingle: Bool = true) {
        if availableShots == 1, manageShotForSingle {
            manageShotForSingleShot()
            return
        }
        // AvailableShots are not 1 here
        availableShots -= 1
        if availableShots == 0, remainingBoxes > 0 {
            showAlertToUser(title: "Oops!!!", message: "You lose the game.")
        }
        setTexts()
    }
    
    /// Manage shot count for single only shot
    func manageShotForSingleShot() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let `self` = self else { return }
            self.didFiredShot(manageShotForSingle: false)
        }
    }
    
    func showCongratulations() {
        DispatchQueue.main.async {
            //load congratulations XIB.
            guard let congratsView = UINib(nibName: "Congratulations", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as? Congratulations else {
                return
            }
            self.clearTexts()
            congratsView.imgCongratulations.applyRadius(radius: 20.0)
            congratsView.frame = CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: congratsView.frame.size.height)
            congratsView.alpha = 0
            self.sceneView.addSubview(congratsView)
            UIView.animate(withDuration: 1.0) { [weak self] in
                guard let `self` = self else { return }
                congratsView.alpha = 1.0
                congratsView.frame = CGRect(x: 0,
                                            y: (self.view.center.y - congratsView.frame.size.height / 2),
                                            width: self.view.frame.size.width,
                                            height: congratsView.frame.size.height)
                guard let activeSceneB = SCNScene(named: "art.scnassets/CustomParticle.scn"),
                      let modelRootB = activeSceneB.rootNode.childNode(withName: "particles", recursively: false)  else { return }
                self.modelRootB = modelRootB
                self.sceneView.scene.rootNode.addChildNode(modelRootB)
            } completion: { (isCompleted) in
                if isCompleted {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                        guard let `self` = self else { return }
                        congratsView.removeFromSuperview()
                        self.modelRootB?.removeFromParentNode()
                        self.removeAllNodes()
                        self.resetGame()
                        self.addChildNode()
                    }
                }
            }
        }
    }
    
    /// Used did shot the box
    func didShotBox() {
        self.remainingBoxes -= 1
        setTexts()
        if self.remainingBoxes == 0 {
            showCongratulations()
        } else if availableShots == 0 {
            showAlertToUser(title: "Oops!!!", message: "You lose the game.")
        }
    }
    
    func showAlertToUser(title: String, message: String) {
        let okAction = UIAlertAction(title: "Ok", style: .default) { [weak self] _ in
            guard let `self` = self else { return }
            self.removeAllNodes()
            self.resetGame()
            self.addChildNode()
        }
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(okAction)
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else { return }
            self.clearTexts()
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    /// Remove all nodes
    func removeAllNodes() {
        self.sceneView.scene.rootNode.enumerateChildNodes { (node, _ ) in
            node.removeFromParentNode()
        }
    }
    
}// End of Extension

// MARK: -
// MARK: - ARSCNViewDelegate

extension GameViewController: ARSCNViewDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        DispatchQueue.main.async {
            guard self.tracking else { return }
            let hitTest = self.sceneView.hitTest(CGPoint(x: self.view.frame.midX, y: self.view.frame.midY), types: .featurePoint)
            guard let result = hitTest.first else { return }
            let translation = SCNMatrix4(result.worldTransform)
            let position = SCNVector3Make(translation.m41, translation.m42, translation.m43)
            if self.trackerNode == nil { //1
                let plane = SCNPlane(width: 0.15, height: 0.15)
                plane.firstMaterial?.diffuse.contents = UIImage(named: "tracker.png")
                plane.firstMaterial?.isDoubleSided = true
                self.trackerNode = SCNNode(geometry: plane) //2
                self.trackerNode?.eulerAngles.x = -.pi * 0.5 //3
                self.sceneView.scene.rootNode.addChildNode(self.trackerNode!)
                self.foundSurface = true //4
            }
            self.trackerNode?.position = position //5
        }
    }
    
}// End of Extension

extension GameViewController: SCNPhysicsContactDelegate {
    
    func physicsWorld(_ world: SCNPhysicsWorld, didEnd contact: SCNPhysicsContact) {
        let ball = contact.nodeA.name == "Ball" ? contact.nodeA : contact.nodeB
        let box = contact.nodeA.name != "Ball" ? contact.nodeA : contact.nodeB
        if ((contact.nodeA.name ?? "").hasPrefix("Node")) || ((contact.nodeB.name ?? "").hasPrefix("Node")) {
            didShotBox()
            createExplosion(geometry: box.geometry!, position: box.presentation.position, rotation: box.presentation.rotation)
            contact.nodeA.removeFromParentNode()
            contact.nodeB.removeFromParentNode()
        } else {
            ball.removeFromParentNode()
        }
    }
    
    func createExplosion(geometry: SCNGeometry, position: SCNVector3, rotation: SCNVector4) {
        let explosion = SCNParticleSystem(named: "art.scnassets/reactor.scnp", inDirectory: nil)!
        explosion.emitterShape = SCNBox(width: 0.01, height: 0.01, length: 0.01, chamferRadius: 0) //geometry
        explosion.birthLocation = .vertex
        let rotationMatrix = SCNMatrix4MakeRotation(rotation.w, rotation.x, rotation.y, rotation.z)
        let translationMatrix = SCNMatrix4MakeTranslation(position.x, position.y, position.z)
        let transformMatrix = SCNMatrix4Mult(rotationMatrix, translationMatrix)
        sceneView.scene.addParticleSystem(explosion, transform: transformMatrix)
    }
    
}// End of Extension
