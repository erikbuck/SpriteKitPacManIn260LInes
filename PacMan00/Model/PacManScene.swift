//
//  PacManScene.swift
//  PacMan00
//
//  Created by wsucatslabs on 3/10/23.
//

import SpriteKit

class PacManScene : SKScene
{
   let pacManRadius = CGFloat(32)
   var pacManMouthAngleRad = CGFloat.pi * 0.25
   var pacManNode : SKShapeNode?
   var pacManMouthAngleDeltaRad = CGFloat(-0.05)
   
   override func didMove(to view: SKView) {
      pacManNode = self.childNode(withName: "PacManNode") as? SKShapeNode
      pacManNode!.fillColor = UIColor.yellow
   }
   
   override func update(_ currentTime: TimeInterval) {
      if pacManMouthAngleRad > CGFloat.pi * 0.35 || pacManMouthAngleRad < 0 {
         pacManMouthAngleDeltaRad *= -1.0
      }
      pacManMouthAngleRad += pacManMouthAngleDeltaRad

      let path = UIBezierPath(arcCenter: CGPoint(), radius: pacManRadius, startAngle: pacManMouthAngleRad, endAngle: CGFloat.pi * 2, clockwise: true)
      path.addLine(to: CGPoint())
      pacManNode!.path = path.cgPath
   }
}
