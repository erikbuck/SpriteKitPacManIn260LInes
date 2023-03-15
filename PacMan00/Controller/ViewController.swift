import UIKit
import SpriteKit

class ViewController: UIViewController {
   @IBOutlet var skView : SKView?
   @IBOutlet var scoreLabel : UILabel?
   
   override func viewDidLoad() {
      super.viewDidLoad()
      let scene = SKScene(fileNamed: "PacMan") as! PacManScene
      scene.scaleMode = .aspectFit
      skView!.presentScene(scene)
      
      NotificationCenter.default.addObserver(forName: Notification.Name("didChangeScore"), object: nil, queue: nil, using: {
         (n : Notification) in self.scoreLabel?.text = "\(scene.score)" })
    }
   
   @IBAction func takeMotionFrom(gestureRecognizer : UIPanGestureRecognizer) {
      let motionDetectDelta = CGFloat(20)
      let velocity = gestureRecognizer.velocity(in: skView)
      if velocity.y > motionDetectDelta {
         (skView!.scene as! PacManScene).pacManDirection = .Up
      } else if velocity.y < -motionDetectDelta {
         (skView!.scene as! PacManScene).pacManDirection = .Down
      } else if velocity.x < -motionDetectDelta {
         (skView!.scene as! PacManScene).pacManDirection = .Left
      } else if velocity.x > motionDetectDelta {
         (skView!.scene as! PacManScene).pacManDirection = .Right
      }
   }
}
