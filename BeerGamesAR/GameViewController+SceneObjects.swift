//
//  GameViewController+SceneObjects.swift
//  BeerGamesAR
//
//  Created by Brian Vo on 2018-06-02.
//  Copyright © 2018 Brian Vo & Ray Lin & Ramen Singh & Tyler Boudreau. All rights reserved.
//

import ARKit

// Scene Objects
extension GameViewController: SCNPhysicsContactDelegate {
    
    // MARK: Setup Scene
    
    func createBall(transform: SCNMatrix4) -> SCNNode {
        let ball = SCNNode(geometry: SCNSphere(radius: 0.02)) // 0.02
        ball.geometry?.firstMaterial?.diffuse.contents = UIColor.orange
        ball.transform = transform
        ball.name = "ball"
        return ball
    }
    
    func createRedCup(position: SCNVector3, name: String) -> SCNNode {
        let redCupScene = SCNScene(named: "cup.scnassets/RedSoloCup.scn")
        let redCupNode = redCupScene?.rootNode.childNode(withName: "redCup", recursively: false)
        redCupNode?.name = name
        redCupNode?.position = position
        return redCupNode!
    }
    
    func setupGameScene() -> SCNNode {
        
        // add Table Top
        let tableScene = SCNScene(named: "customTableAndCups.scnassets/Table.scn")
        guard let tableNode = tableScene?.rootNode.childNode(withName: "table", recursively: false) else { return SCNNode() }
        
        DispatchQueue.global(qos: .default).async {
            let beerPongText = self.createText(text: "BEER PONG AR",
                                               textColor: .red,
                                               position: SCNVector3(0, 2, 0),
                                               scale: SCNVector3(0.01, 0.01, 0.01))
            tableNode.addChildNode(beerPongText)
            self.nodePhysics.apply()
        }
        return tableNode
    }
    
    func createText(text: String, textColor: UIColor, position: SCNVector3, scale: SCNVector3) -> SCNNode {
        let text = SCNText(string: text, extrusionDepth: 2)
        text.font = UIFont(name: "HelveticaNeue-CondensedBlack", size: 25)
        
        let material = SCNMaterial()
        material.diffuse.contents = textColor
        text.materials = [material]
        
        let node = SCNNode(geometry: text)
        node.scale = scale
        node.position = position
        
        // rotate at the center of the nodes width and height
        let min = node.boundingBox.min
        let max = node.boundingBox.max
        node.pivot = SCNMatrix4MakeTranslation(
            min.x + /* (+ 0.5 *) */ (max.x - min.x) / 2,
            min.y + /* (+ 0.5 *) */ (max.y - min.y) / 2,
            min.z + /* (+ 0.5 *) */ (max.z - min.z) / 2
        )
        
        node.name = "scoreNode"
        return node
    }
    
    func rotateAnimation() -> SCNAction {
        
        let rotateAction = SCNAction.rotate(by: 2 * CGFloat.pi, around: SCNVector3(0, 0.5, 0), duration: 5)
        
        return SCNAction.repeatForever(rotateAction)
    }
    
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        let nodeA = contact.nodeA
        let nodeB = contact.nodeB
        
        DispatchQueue.global(qos: .background).async {
            
            if nodeA.name == "ball" && nodeB.name?.range(of: "plane") != nil {
                print("ball touched \(nodeB.name!)")
                self.removeCupAndPhysics(contactNode: nodeB)
            }
            else if (nodeA.name?.contains("plane"))! && nodeB.name == "ball" {
                print("\(nodeA.name!) touched ball")
                self.removeCupAndPhysics(contactNode: nodeA)
            }
        }
    }
    
    func removeCupAndPhysics(contactNode: SCNNode) {
        self.sceneView.scene.rootNode.enumerateChildNodes({ (node, _) in
            guard let nodeName = contactNode.name,
                let rangeIndex = nodeName.range(of: "_") else { return }
            let nodeNumber = nodeName[rangeIndex.upperBound...]
            if node.name == "cup_" + nodeNumber {
                //node.removeFromParentNode()
                node.isHidden = true
                self.updateCupState(nodeNumber: String(nodeNumber))
            }
            if node.name == "tube_" + nodeNumber ||
                node.name == "plane_" + nodeNumber {
                //node.removeFromParentNode()
                node.isHidden = true
                node.physicsBody?.collisionBitMask = 0
            }
            if node.name == "ball" {
                node.removeFromParentNode()
                self.updateBallInPlay(bool: false)
                self.isBallInPlay = false
                dismissBallTimer.invalidate()
            }
        })
    }
}
