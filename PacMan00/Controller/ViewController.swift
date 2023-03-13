import UIKit
import SpriteKit

class ViewController: UIViewController {
   @IBOutlet var skView : SKView?
   
   override func viewDidLoad() {
      super.viewDidLoad()
      let view = self.skView!
      let scene = SKScene(fileNamed: "PacMan")!
      scene.scaleMode = .aspectFit
      view.presentScene(scene)
      view.showsFPS = true
    }
   
   static let motionDetectDelta = CGFloat(20)
   
   @IBAction func takeMotionFrom(gestureRecognizer : UIPanGestureRecognizer) {
      let velocity = gestureRecognizer.velocity(in: skView)
      if velocity.y > ViewController.motionDetectDelta {
         (skView!.scene as! PacManScene).setPacManDirection(direction: .Up)
      } else if velocity.y < -ViewController.motionDetectDelta {
         (skView!.scene as! PacManScene).setPacManDirection(direction: .Down)
      } else if velocity.x < -ViewController.motionDetectDelta {
         (skView!.scene as! PacManScene).setPacManDirection(direction: .Left)
      } else if velocity.x > ViewController.motionDetectDelta {
         (skView!.scene as! PacManScene).setPacManDirection(direction: .Right)
      } else {
         (skView!.scene as! PacManScene).setPacManDirection(direction: .None)
      }
   }
   
   @IBAction func takeStopFrom(gestureRecognizer : UITapGestureRecognizer) {
      (skView!.scene as! PacManScene).setPacManDirection(direction: .None)
   }
}

