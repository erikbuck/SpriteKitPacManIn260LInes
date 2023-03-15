import SpriteKit

class WallNode : SKSpriteNode {
}

class GhostNode : SKSpriteNode {
}

class VulnerableGhostNode : SKSpriteNode {
}

func makeGhostAction(node : GhostNode) -> SKAction {
   return SKAction.repeatForever(SKAction.sequence(
      [SKAction.wait(forDuration: 0.2),
       SKAction.run {
          let dx = node.physicsBody!.velocity.dx
          let dy = node.physicsBody!.velocity.dy
          if abs(dx) < 10 && abs(dy) < 10 {
             let direction = PacManScene.Direction.allCases.randomElement()!
             var newVelocity = PacManScene.directionVectors[direction.rawValue]
             newVelocity.dx *= CGFloat(10)
             newVelocity.dy *= CGFloat(10)
             node.physicsBody!.velocity = newVelocity
          }
       }]))
}

class PacManScene : SKScene, SKPhysicsContactDelegate
{
   static let pacManRadius = CGFloat(9)
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
   var pacManMouthAngleRad = CGFloat.pi * 0.25
   var pacManNode : SKShapeNode?
   var pacManMouthAngleDeltaRad = CGFloat(-0.05)
   var pacManDirection = Direction.Left { didSet { movePacMan() } }
   var pacManSpeed = CGFloat(10)
   var blinkyNode : GhostNode?
   var inkyNode : GhostNode?
   var pinkyNode : GhostNode?
   var clydeNode : GhostNode?

   // MARK: - Initialization
   override func didMove(to view: SKView) {
      blinkyNode = (childNode(withName: "Blinky") as? GhostNode)!
      inkyNode = (childNode(withName: "Inky") as? GhostNode)!
      pinkyNode = (childNode(withName: "Pinky") as? GhostNode)!
      clydeNode = (childNode(withName: "Clyde") as? GhostNode)!
      
      blinkyNode!.run(makeGhostAction(node: blinkyNode!))
      inkyNode!.run(makeGhostAction(node: inkyNode!))
      pinkyNode!.run(makeGhostAction(node: pinkyNode!))
      clydeNode!.run(makeGhostAction(node: clydeNode!))

      pacManNode = (childNode(withName: "PacManNode") as? SKShapeNode)!
      pacManNode!.fillColor = UIColor.yellow
      pacManNode!.physicsBody = SKPhysicsBody(circleOfRadius: PacManScene.pacManRadius)
      pacManNode!.physicsBody!.allowsRotation = false
      pacManNode!.physicsBody!.friction = 0.01
      pacManNode!.physicsBody!.linearDamping = 0.01
      pacManNode!.physicsBody!.collisionBitMask = 0xfe // Don't colllide with Pellets
      physicsWorld.contactDelegate = self
   }
   
   // MARK: - PacMan Movement
   func movePacMan() {
      let vector = PacManScene.directionVectors[pacManDirection.rawValue]
      pacManNode!.physicsBody!.velocity = CGVector(dx: vector.dx * pacManSpeed, dy: vector.dy * pacManSpeed)
      pacManNode!.run(SKAction.rotate(toAngle: PacManScene.directionAnglesRad[pacManDirection.rawValue], duration: 0.06))
   }

   // MARK: - Update for every frame
   override func update(_ currentTime: TimeInterval) {
      // Draw PacMan mouth open and close using Core Graphics
      if pacManMouthAngleRad > CGFloat.pi * 0.35 || pacManMouthAngleRad < 0 {
         pacManMouthAngleDeltaRad *= -1.0
      }
      pacManMouthAngleRad += pacManMouthAngleDeltaRad
      
      let path = UIBezierPath(arcCenter: CGPoint(), radius: PacManScene.pacManRadius, startAngle: pacManMouthAngleRad, endAngle: CGFloat.pi * 2 - pacManMouthAngleRad, clockwise: true)
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
         }
      }
   }
}
