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

//
func makePacManDeathAction() -> SKAction {
   let soundRepeatPeriodSeconds = 0.5
   return SKAction.sequence([deathPlaySoundAction,
                             SKAction.scale(to: 1.5, duration: 0.2),
                             SKAction.scale(to: 0.5, duration: 0.5),
                             SKAction.removeFromParent()])
}

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
   var namedGhosts = Dictionary<String, GhostNode>()
   var pacManNode : SKShapeNode?
   var pacManMouthAngleRad = CGFloat.pi * 0.25  // Arbitrary initial angle
   var pacManMouthAngleDeltaRad = CGFloat(-0.05) // Arbitrary small change
   var pacManDirection = Direction.Left { didSet { movePacMan() } }

   // MARK: - Initialization
   override func didMove(to view: SKView) {
      physicsWorld.contactDelegate = self
      
      PacManScene.vulnerableGhostPrototype = (childNode(withName: "GhostVulnerable") as? VulnerableGhostNode)!
      PacManScene.vulnerableGhostPrototype!.removeFromParent()
      PacManScene.eyesPrototype = (childNode(withName: "EyesPrototype") as? SKSpriteNode)!
      PacManScene.eyesPrototype!.removeFromParent()
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

   // MARK: - Physics Collisions
   func didBegin(_ contact: SKPhysicsContact) {
      if contact.bodyA.node?.name == "PacManNode" || contact.bodyB.node?.name == "PacManNode" {
         if contact.bodyA.node?.name == "Pellet" {
            contact.bodyA.node?.removeFromParent()
            NotificationCenter.default.post(Notification(name: Notification.Name("didEatPellet")))
         } else if contact.bodyB.node?.name == "Pellet"{
            contact.bodyB.node?.removeFromParent()
            NotificationCenter.default.post(Notification(name: Notification.Name("didEatPellet")))
         } else if contact.bodyA.node?.name == "PowerPellet" {
            contact.bodyA.node?.removeFromParent()
            for ghostNode in namedGhosts.values { replaceGhostWithVulnerableGhosts(ghostNode) }
         } else if contact.bodyB.node?.name == "PowerPellet"{
            contact.bodyB.node?.removeFromParent()
            for ghostNode in namedGhosts.values { replaceGhostWithVulnerableGhosts(ghostNode) }
         } else if (contact.bodyA.node?.name ?? "").starts(with: "GhostVulnerable") {
            replaceVulnerableGhostWithEyes(contact.bodyA.node as! VulnerableGhostNode)
         } else if (contact.bodyB.node?.name ?? "").starts(with: "GhostVulnerable") {
            replaceVulnerableGhostWithEyes(contact.bodyB.node as! VulnerableGhostNode)
         } else if (contact.bodyA.node?.name ?? "").starts(with: "Ghost") ||
                     (contact.bodyB.node?.name ?? "").starts(with: "Ghost") {
            
            // Create expand and "pop" animation using arbitrary scale factors and periods
            pacManNode!.run(makePacManDeathAction())
            
            // Respawn Pac Man after arbitrary period and restore Pac Man size to default
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: {
               self.pacManNode!.position = pacManStartPosition
               self.pacManNode!.removeFromParent()
               self.addChild(self.pacManNode!)
               self.pacManNode!.run(SKAction.scale(to: 1, duration: 0.2))
            })
         }
      }
   }
}
