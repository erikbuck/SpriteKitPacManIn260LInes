import SpriteKit

class WallNode : SKSpriteNode {}

let pacManSpeed = CGFloat(10)
let pacManStartPosition = CGPoint(x: 10, y: -10) // Arbitrary not inside maze walls
let wackawackaPlaySoundAction = SKAction.playSoundFileNamed("wackawacka", waitForCompletion: false)
let deathPlaySoundAction = SKAction.playSoundFileNamed("death", waitForCompletion: false)

// Play sound whenever PacMan is in motion
func makePacManAction(node : SKNode) -> SKAction {
   let soundRepeatPeriodSeconds = 0.5
   return SKAction.repeatForever(SKAction.sequence(
      [SKAction.wait(forDuration: soundRepeatPeriodSeconds),
       SKAction.run {
          let dx = node.physicsBody!.velocity.dx
          let dy = node.physicsBody!.velocity.dy
          if abs(dx) >= pacManSpeed || abs(dy) >= pacManSpeed {
             node.run(wackawackaPlaySoundAction)
          }
       }]))
}

func makePacManDeathAction() -> SKAction {
   return SKAction.sequence([deathPlaySoundAction,
                             SKAction.scale(to: 1.5, duration: 0.2),
                             SKAction.scale(to: 0.5, duration: 0.5),
                             SKAction.removeFromParent()])
}

let infoLabelMoveAction = SKAction.sequence([SKAction.moveBy(x: 0.0, y: 100, duration: 1.0),
                                             SKAction.fadeOut(withDuration: 0.4), SKAction.removeFromParent()])

class PacManScene : SKScene, SKPhysicsContactDelegate
{
   static let pacManRadius = CGFloat(9) // Arbitrary small enough to not scrape edges of maze
   enum Direction : Int, CaseIterable { case Up, Down, Left, Right }
   
   static let directionVectors = [CGVector(dx: 0, dy: -pacManRadius),     // up
                                  CGVector(dx: 0, dy: pacManRadius),  // down
                                  CGVector(dx: -pacManRadius, dy: 0), // left
                                  CGVector(dx: pacManRadius, dy: 0),  // right
   ]
   static let directionAnglesRad = [CGFloat.pi * -0.5,      // up
                                    CGFloat.pi * 0.5,   // down
                                    CGFloat.pi * 1.0,   // left
                                    CGFloat.pi * 0.0,   // right
   ]
   static var vulnerableGhostPrototype : VulnerableGhostNode?
   static var eyesPrototype : SKSpriteNode?
   static var infoLabelPrototype : SKLabelNode?
   var namedGhosts = Dictionary<String, GhostNode>()
   var pacManNode : SKShapeNode?
   var pacManMouthAngleRad = CGFloat.pi * 0.25  // Arbitrary initial angle
   var pacManMouthAngleDeltaRad = CGFloat(-0.05) // Arbitrary small change
   var pacManDirection = Direction.Left { didSet { movePacMan() } }
   var score = 0
   
   // MARK: - Initialization
   override func didMove(to view: SKView) {
      physicsWorld.contactDelegate = self
      PacManScene.vulnerableGhostPrototype = (childNode(withName: "GhostVulnerablePrototype") as? VulnerableGhostNode)!
      PacManScene.eyesPrototype = (childNode(withName: "EyesPrototype") as? SKSpriteNode)!
      PacManScene.infoLabelPrototype = (childNode(withName: "InfoLabelPrototype") as? SKLabelNode)!
      initGhosts(scene: self, names: ["GhostBlinky", "GhostInky", "GhostPinky", "GhostClyde"])      
      pacManNode = (childNode(withName: "PacManNode") as? SKShapeNode)!
      pacManNode!.position = pacManStartPosition
      pacManNode!.physicsBody = SKPhysicsBody(circleOfRadius: PacManScene.pacManRadius)
      pacManNode!.physicsBody!.allowsRotation = false
      pacManNode!.physicsBody!.friction = 0.01 // Arbitrry small to mitigate impacts with mage edges
      pacManNode!.physicsBody!.linearDamping = 0.01 // Arbitrry small to prevent slowdown
      pacManNode!.run(makePacManAction(node: pacManNode!))
      
      // Pellets have collision category b0001 and collision mask b0000
      // Ghosts have collision category  b0010 and collision mask b0010
      pacManNode!.physicsBody!.collisionBitMask = 0b0100 // Don't colllide with Pellets or ghosts
   }
   
   // MARK: - PacMan Movement
   func movePacMan() {
      let v = PacManScene.directionVectors[pacManDirection.rawValue]
      pacManNode!.physicsBody!.velocity = CGVector(dx: v.dx * pacManSpeed, dy: v.dy * pacManSpeed)
      pacManNode!.run(SKAction.rotate(toAngle: PacManScene.directionAnglesRad[pacManDirection.rawValue],
                                      duration: 0.06))
   }
   
   // MARK: - Update for every frame
   override func update(_ currentTime: TimeInterval) {
      let pacManMounthOpenAngleRad = 0.35 // arbitrary
      // Draw PacMan mouth open and close using Core Graphics
      if pacManMouthAngleRad > CGFloat.pi * pacManMounthOpenAngleRad || pacManMouthAngleRad < 0 {
         pacManMouthAngleDeltaRad *= -1.0 // reverse direction of mouth open/close animation
      }
      pacManMouthAngleRad += pacManMouthAngleDeltaRad
      
      let path = UIBezierPath(arcCenter: CGPoint(), radius: PacManScene.pacManRadius,
                              startAngle: pacManMouthAngleRad,
                              endAngle: CGFloat.pi * 2 - pacManMouthAngleRad,
                              clockwise: true)
      path.addLine(to: CGPoint())
      pacManNode!.path = path.cgPath
   }
   
   // MARK: - Info Labls
   func spawnInfoLabel(position: CGPoint, text: String) {
      let newLabel = PacManScene.infoLabelPrototype!.copy() as! SKLabelNode
      newLabel.position = position
      newLabel.text = text
      addChild(newLabel)
      newLabel.run(infoLabelMoveAction)
   }
   
   // MARK: - Physics Collisions
   func didBegin(_ contact: SKPhysicsContact) {
      var otherNode : SKNode? = nil
      // If one of the nodes in contact is PacMan, take note of the other node
      if contact.bodyA.node?.name == "PacManNode" {
         otherNode = contact.bodyB.node
      } else if contact.bodyB.node?.name == "PacManNode" {
         otherNode = contact.bodyA.node
      }
      
      if let validOtherNode = otherNode {
         if validOtherNode.name == "Pellet" {
            score += 1
            validOtherNode.removeFromParent()
            NotificationCenter.default.post(Notification(name: Notification.Name("didChangeScore")))
         } else if validOtherNode.name == "PowerPellet" {
            validOtherNode.removeFromParent()
            for ghostNode in namedGhosts.values { replaceGhostWithVulnerableGhost(ghostNode) }
         } else if (validOtherNode.name ?? "").starts(with: "GhostVulnerable") {
            score += VulnerableGhostNode.consumptionPoints
            spawnInfoLabel(position: validOtherNode.position, text: "\(VulnerableGhostNode.consumptionPoints)")
            replaceVulnerableGhostWithEyes(validOtherNode as! VulnerableGhostNode)
            NotificationCenter.default.post(Notification(name: Notification.Name("didChangeScore")))
         } else if (contact.bodyA.node?.name ?? "").starts(with: "Ghost") ||
                     (contact.bodyB.node?.name ?? "").starts(with: "Ghost") {
            // Create "expand and pop" animation using arbitrary scale factors and periods
            pacManNode!.run(makePacManDeathAction())
            
            // Respawn PacMan after arbitrary period and restore PacMan size to default
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: {
               self.pacManNode!.position = pacManStartPosition
               self.pacManNode!.physicsBody!.velocity = CGVector()
               self.pacManNode!.removeFromParent()
               self.addChild(self.pacManNode!)
               self.pacManNode!.run(SKAction.scale(to: 1, duration: 0.2))
            })
         }
      }
   }
}
