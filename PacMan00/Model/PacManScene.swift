import SpriteKit


class PacManScene : SKScene, SKPhysicsContactDelegate
{
   static let pacManRadius = CGFloat(9)
   enum Direction : Int { case Up, Down, Left, Right, None }
   
   static let directionVectors = [CGVector(dx: 0, dy: -pacManRadius), // up
                                  CGVector(dx: 0, dy: pacManRadius),  // down
                                  CGVector(dx: -pacManRadius, dy: 0), // left
                                  CGVector(dx: pacManRadius, dy: 0),  // right
                                  CGVector(dx: 0, dy: 0),   // none
   ]
   
   static let directionAnglesRad = [CGFloat.pi * -0.5,   // up
                                    CGFloat.pi * 0.5,    // down
                                    CGFloat.pi * 1.0,    // left
                                    CGFloat.pi * 0.0,    // right
                                    CGFloat.pi * 0.0,    // none
   ]
   
   var pacManMouthAngleRad = CGFloat.pi * 0.25
   var pacManNode : SKShapeNode?
   var pacManMouthAngleDeltaRad = CGFloat(-0.05)
   var pacManDirection = Direction.None
   var pacManSpeed = CGFloat(10)
   
   override func didMove(to view: SKView) {
      pacManNode = self.childNode(withName: "PacManNode") as? SKShapeNode
      pacManNode!.fillColor = UIColor.yellow
      pacManNode!.physicsBody = SKPhysicsBody(circleOfRadius: PacManScene.pacManRadius)
      pacManNode!.physicsBody!.allowsRotation = false
      physicsWorld.contactDelegate = self
      pacManNode!.physicsBody!.friction = 0.01
      pacManNode!.physicsBody!.linearDamping = 0.01
      pacManNode!.physicsBody!.angularDamping = 0.01
      pacManNode!.physicsBody!.collisionBitMask = 0xfe
   }
   
   func didBegin(_ contact: SKPhysicsContact) {
      if contact.bodyA.node?.name == "PacManNode" || contact.bodyB.node?.name == "PacManNode" {
         if contact.bodyA.node?.name == "Pellet" {
            contact.bodyA.node?.removeFromParent()
         } else if contact.bodyB.node?.name == "Pellet"{
            contact.bodyB.node?.removeFromParent()
         }
      }
   }
   
   func movePacMan() {
      let vector = PacManScene.directionVectors[pacManDirection.rawValue]
      pacManNode!.physicsBody!.velocity = CGVector(dx: vector.dx * pacManSpeed, dy: vector.dy * pacManSpeed)
      if pacManDirection != .None {
         pacManNode!.run(SKAction.rotate(toAngle: PacManScene.directionAnglesRad[pacManDirection.rawValue], duration: 0.06))
      }
   }
   
   override func update(_ currentTime: TimeInterval) {
      if pacManMouthAngleRad > CGFloat.pi * 0.35 || pacManMouthAngleRad < 0 {
         pacManMouthAngleDeltaRad *= -1.0
      }
      pacManMouthAngleRad += pacManMouthAngleDeltaRad
      
      let path = UIBezierPath(arcCenter: CGPoint(), radius: PacManScene.pacManRadius, startAngle: pacManMouthAngleRad, endAngle: CGFloat.pi * 2 - pacManMouthAngleRad, clockwise: true)
      path.addLine(to: CGPoint())
      pacManNode!.path = path.cgPath
   }
   
   func setPacManDirection(direction : Direction) {
      if pacManDirection != direction {
         pacManDirection = direction
         pacManNode!.removeAllActions()
         movePacMan()
      }
   }
}
