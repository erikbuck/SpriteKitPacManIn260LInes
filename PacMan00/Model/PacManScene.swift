import SpriteKit

class WallNode : SKSpriteNode {}
class GhostNode : SKSpriteNode {}
class VulnerableGhostNode : SKSpriteNode {}

let pacManSpeed = CGFloat(10)
let ghostSpeed = CGFloat(10)
let ghostDecisionPeriodSeconds = 0.2
let pacManStartPosition = CGPoint(x: 10, y: -10) // Arbitrary not inside maze walls

/// Make the ACtion that controls Ghost behavior. In future, consider different Actions for each ghost so they have "personality".
func makeGhostAction(node : GhostNode) -> SKAction {
   return SKAction.repeatForever(SKAction.sequence(
      [SKAction.wait(forDuration: ghostDecisionPeriodSeconds),
       SKAction.run {
          let dx = node.physicsBody!.velocity.dx
          let dy = node.physicsBody!.velocity.dy
          if abs(dx) < ghostSpeed && abs(dy) < ghostSpeed {
             let direction = PacManScene.Direction.allCases.randomElement()!
             var newVelocity = PacManScene.directionVectors[direction.rawValue]
             newVelocity.dx *= ghostSpeed; newVelocity.dy *= ghostSpeed
             node.physicsBody!.velocity = newVelocity
          }
       }]))
}

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
   var blinkyNode : GhostNode?
   var inkyNode : GhostNode?
   var pinkyNode : GhostNode?
   var clydeNode : GhostNode?
   var pacManNode : SKShapeNode?
   var pacManMouthAngleRad = CGFloat.pi * 0.25  // Arbitrary initial angle
   var pacManMouthAngleDeltaRad = CGFloat(-0.05) // Arbitrary small change
   var pacManDirection = Direction.Left { didSet { movePacMan() } }

   // MARK: - Initialization
   override func didMove(to view: SKView) {
      physicsWorld.contactDelegate = self
      
      blinkyNode = (childNode(withName: "GhostBlinky") as? GhostNode)!
      inkyNode = (childNode(withName: "GhostInky") as? GhostNode)!
      pinkyNode = (childNode(withName: "GhostPinky") as? GhostNode)!
      clydeNode = (childNode(withName: "GhostClyde") as? GhostNode)!
      
      blinkyNode!.run(makeGhostAction(node: blinkyNode!))
      inkyNode!.run(makeGhostAction(node: inkyNode!))
      pinkyNode!.run(makeGhostAction(node: pinkyNode!))
      clydeNode!.run(makeGhostAction(node: clydeNode!))
      
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
         } else if contact.bodyB.node?.name == "Pellet"{
            contact.bodyB.node?.removeFromParent()
         } else if contact.bodyA.node?.name == "PowerPellet" {
            contact.bodyA.node?.removeFromParent()
         } else if contact.bodyB.node?.name == "PowerPellet"{
            contact.bodyB.node?.removeFromParent()
         } else if (contact.bodyA.node?.name ?? "").starts(with: "Ghost") ||
                     (contact.bodyB.node?.name ?? "").starts(with: "Ghost") {
            
            // Create expand and "pop" animation using arbitrary scale factors and periods
            pacManNode!.run(SKAction.sequence([deathPlaySoundAction,
                                               SKAction.scale(to: 1.5, duration: 0.2),
                                               SKAction.scale(to: 0.5, duration: 0.5),
                                               SKAction.removeFromParent()]))
            
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
