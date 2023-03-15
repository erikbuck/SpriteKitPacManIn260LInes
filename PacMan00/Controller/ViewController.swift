import UIKit
import SpriteKit

class ViewController: UIViewController {
   @IBOutlet var skView : SKView?
   @IBOutlet var scoreLabel : UILabel?
   var score = 0
   
   override func viewDidLoad() {
      super.viewDidLoad()
      let scene = SKScene(fileNamed: "PacMan") as! PacManScene
      scene.scaleMode = .aspectFit
      skView!.presentScene(scene)
      
      NotificationCenter.default.addObserver(forName: Notification.Name("didChangeScore"), object: nil, queue: nil, using: { (n : Notification) in
         self.scoreLabel?.text = "\(scene.score)"
      })
    }
   
   static let motionDetectDelta = CGFloat(20)
   
   @IBAction func takeMotionFrom(gestureRecognizer : UIPanGestureRecognizer) {
      let velocity = gestureRecognizer.velocity(in: skView)
      if velocity.y > ViewController.motionDetectDelta {
         (skView!.scene as! PacManScene).pacManDirection = .Up
      } else if velocity.y < -ViewController.motionDetectDelta {
         (skView!.scene as! PacManScene).pacManDirection = .Down
      } else if velocity.x < -ViewController.motionDetectDelta {
         (skView!.scene as! PacManScene).pacManDirection = .Left
      } else if velocity.x > ViewController.motionDetectDelta {
         (skView!.scene as! PacManScene).pacManDirection = .Right
      }
   }
}
