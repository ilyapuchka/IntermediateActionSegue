//
//  ViewController.swift
//  IntermediateSegues
//
//  Created by Ilya Puchka on 20.12.15.
//
//

import UIKit

class ViewController: UIViewController, UIPopoverPresentationControllerDelegate {
    
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return .FullScreen
    }
    
    func presentationController(controller: UIPresentationController, viewControllerForAdaptivePresentationStyle style: UIModalPresentationStyle) -> UIViewController? {
        if controller.presentedViewController is UINavigationController {
            return nil
        }
        else {
            let nc = UINavigationController(rootViewController: controller.presentedViewController)
            nc.topViewController!.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done", style: .Done, target: controller.presentedViewController, action: "succeed")
            return nc
        }
    }
    
    @IBOutlet var intermediateButton: UIButton!
    @IBOutlet var intermediateStoryButton: UIButton!
    @IBOutlet var intermediateActionButton: UIButton!
    
    @IBAction
    func intermediateActionButtonTapped(sender: UIButton) {
        withAction {
            sender.setTitle("Action Succeed", forState: .Normal)
        }
    }
    
    func withAction(block: ()->()) {
        let segue = IntermediateActionSegue(identifier: "button", sourceViewController: self, intermediateViewController: storyboard?.instantiateViewControllerWithIdentifier("Intermediate")) { (success, _) in
            if success { block() }
        }
        segue.intermediateViewControllerPresentationStyle = .Modal
        segue.intermediateViewController!.modalPresentationStyle = .FormSheet
        segue.perform()
    }
}

let IntermediateViewSegueId = "IntermediateView"
let IntermediateStorySegueId = "IntermediateStory"

extension ViewController: IntermediateActionPresentationDelegate {
    
    func intermediateViewControllerForSegue(segue: IntermediateActionSegue) -> UIViewController? {
        if segue.identifier == IntermediateViewSegueId {
            let vc = storyboard?.instantiateViewControllerWithIdentifier("Intermediate")
            return vc
        }
        else if segue.identifier == IntermediateStorySegueId {
            let storyboard = UIStoryboard(name: "Intermediate", bundle: nil)
            let vc = storyboard.instantiateInitialViewController()
            return vc
        }
        return nil
    }
    
    func intermediateViewControllerPresentationStyleForSegue(segue: IntermediateActionSegue) -> IntermediateActionSeguePresentationStyle {
        if segue.identifier == IntermediateStorySegueId {
            return .Popover
        }
        return .Show
    }

    func willPresentIntermediateViewController(intermediateViewController: UIViewController, segue: IntermediateActionSegue) {
        switch intermediateViewController.modalPresentationStyle {
        case .Popover:
            intermediateViewController.popoverPresentationController?.delegate = self
            intermediateViewController.popoverPresentationController?.sourceView = self.view
            
            if segue.identifier == IntermediateStorySegueId {
                intermediateViewController.popoverPresentationController?.sourceRect = self.intermediateStoryButton.frame
            }
            else if segue.identifier == IntermediateViewSegueId {
                intermediateViewController.popoverPresentationController?.sourceRect = self.intermediateButton.frame
            }
            else {
                intermediateViewController.popoverPresentationController?.sourceRect = self.intermediateActionButton.frame
            }
        
        case .Custom:
            intermediateViewController.modalPresentationStyle = .FormSheet
            
        default: break
        }
    }
    
}

class Intermediate: UIViewController {
    
    @IBAction func succeed() {
        complete(true)
    }
    
    @IBAction func fail() {
        complete(false)
    }
    
    func complete(success: Bool) {
        intermediateActionSegue?.intermediateViewControllerCompleted(self, success: success, completionData: nil)
    }

}



