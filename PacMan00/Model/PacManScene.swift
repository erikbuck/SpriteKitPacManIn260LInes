import SpriteKit


class PacManScene : SKScene, SKPhysicsContactDelegate
{
   static let pacManRadius = CGFloat(10)
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
   var pacManDestination = CGPoint(x: 20, y: -20)
   
   override func didMove(to view: SKView) {
      pacManNode = self.childNode(withName: "PacManNode") as? SKShapeNode
      pacManNode!.fillColor = UIColor.yellow
      // Make physics radious slightly smaller so pac man doesn't rub along edges of walls
      pacManNode!.physicsBody = SKPhysicsBody(circleOfRadius: PacManScene.pacManRadius - 1)
      physicsWorld.contactDelegate = self
   }
   
   func didBegin(_ contact: SKPhysicsContact) {
      if contact.bodyA.node?.name == "PacManNode" || contact.bodyB.node?.name == "PacManNode" {
         pacManNode!.removeAllActions()
      }
   }
   
   func getConstrainedPosition(position : CGPoint) -> CGPoint {
      let result = CGPoint(x: Int(max(PacManScene.pacManRadius, min(size.width - PacManScene.pacManRadius, position.x))),
                           y: Int(max(-size.height + PacManScene.pacManRadius, min(-PacManScene.pacManRadius, position.y))))
      
      return result
   }
   
   func movePacMan() {
      let vector = PacManScene.directionVectors[pacManDirection.rawValue]
      let candidatePoint = CGPoint(x: (pacManDestination.x + vector.dx),
                                   y: (pacManDestination.y + vector.dy))
      pacManDestination = getConstrainedPosition(position:candidatePoint)
      let existingNode = atPoint(pacManDestination)
      if "Wall" == existingNode.name {
         // We can't go there because wall in the way
         pacManDirection = .None
         pacManDestination = pacManNode!.position
      }
      let moveAction = SKAction.move(to: pacManDestination, duration: 0.2)
      moveAction.timingMode = .linear
      pacManNode!.run(moveAction) {
         self.movePacMan()
      }
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
