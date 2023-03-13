import UIKit
import SpriteKit

class ViewController: UIViewController {
   @IBOutlet var skView : SKView?
   
   override func viewDidLoad() {
      super.viewDidLoad()
      if let view = self.skView {
         // Load the SKScene from 'GameScene.sks'
         if let scene = SKScene(fileNamed: "PacMan") {
            // Set the scale mode to scale to fit the window
            scene.scaleMode = .aspectFit
            
            // Present the scene
            view.presentScene(scene)
            view.ignoresSiblingOrder = true
            view.showsFPS = true
            view.showsNodeCount = true
         }
      }
   }
   
   static let motionDelta = CGFloat(20)
   //   static let pacManMoveSpeed = CGFloat(4)
   
   @IBAction func takeMotionFrom(gestureRecognizer : UIPanGestureRecognizer) {
      let velocity = gestureRecognizer.velocity(in: skView)
      //print("\(velocity)")
      if velocity.y > ViewController.motionDelta {
         (skView!.scene as! PacManScene).setPacManDirection(direction: .Up)
      } else if velocity.y < -ViewController.motionDelta {
         (skView!.scene as! PacManScene).setPacManDirection(direction: .Down)
      } else if velocity.x < -ViewController.motionDelta {
         (skView!.scene as! PacManScene).setPacManDirection(direction: .Left)
      } else if velocity.x > ViewController.motionDelta {
         (skView!.scene as! PacManScene).setPacManDirection(direction: .Right)
      } else {
         (skView!.scene as! PacManScene).setPacManDirection(direction: .None)
      }
   }
   
   @IBAction func takeStopFrom(gestureRecognizer : UITapGestureRecognizer) {
      (skView!.scene as! PacManScene).setPacManDirection(direction: .None)
   }
}

