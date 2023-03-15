import SpriteKit

let ghostSpeed = CGFloat(10)
let ghostDecisionPeriodSeconds = 0.2

class GhostNode : SKSpriteNode {
   var startPosition = CGPoint()
}

class VulnerableGhostNode : GhostNode {
   static var consumptionPoints = 200 // Number of points for eating a vulnerable ghost
   static let consumptionDeltaPoints = 200 // Increase in points for each consecutive ghost that's eaten

   var invulnerableNode : GhostNode?
}

/// Make the Action that controls Ghost behavior. In future, consider different Actions for each ghost so they have "personality".
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

func replaceGhostWithVulnerableGhosts(_ ghost : GhostNode) {
   if nil != ghost.parent {
      let newGhost = PacManScene.vulnerableGhostPrototype!.copy() as! VulnerableGhostNode
      newGhost.invulnerableNode = ghost
      newGhost.position = ghost.position
      ghost.parent!.addChild(newGhost)
      ghost.removeFromParent()
      newGhost.run(makeGhostAction(node: newGhost))
      DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) {
         if nil != newGhost.parent {
            ghost.position = newGhost.position
            newGhost.parent!.addChild(ghost)
            newGhost.removeFromParent()
            VulnerableGhostNode.consumptionPoints = 200 // Reset to eliminate bonus
         }
      }
   }
}

func replaceVulnerableGhostWithEyes(_ vulnerableGhost : VulnerableGhostNode) {
   if nil != vulnerableGhost.parent {
      VulnerableGhostNode.consumptionPoints += VulnerableGhostNode.consumptionDeltaPoints
      let newEyesNode = PacManScene.eyesPrototype!.copy() as! SKSpriteNode
      newEyesNode.position = vulnerableGhost.position
      vulnerableGhost.parent!.addChild(newEyesNode)
      vulnerableGhost.removeFromParent()
      newEyesNode.run(SKAction.sequence([SKAction.move(to: vulnerableGhost.invulnerableNode!.startPosition, duration: 3),
                                             SKAction.run {
         vulnerableGhost.invulnerableNode!.position = newEyesNode.position
         newEyesNode.parent!.addChild(vulnerableGhost.invulnerableNode!)
         newEyesNode.removeFromParent()
      }]))
   }
}

func initGhosts(scene: PacManScene, names : [String]) {
   for name in names {
      let existingGhostNode = (scene.childNode(withName: name) as? GhostNode)!
      existingGhostNode.startPosition = existingGhostNode.position
      existingGhostNode.run(makeGhostAction(node: existingGhostNode))
      scene.namedGhosts[name] = existingGhostNode
   }
}
