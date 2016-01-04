//
//  IntermediateActionSegue.swift
//  IntermediateSegues
//
//  Created by Ilya Puchka on 20.12.15.
//
//

import UIKit

public enum IntermediateActionSeguePresentationStyle {
    ///Will present intermediate view controller using adaptive presentation style
    case Show
    
    ///Will present intermediate view controller will `FullScreen` modal presentation style
    case Modal
    
    ///Will present intermediate view controller in popover
    case Popover
    
    ///Will present intermediate view controller with `Custom` modal presentation style
    case Custom
}

///Protocol used to configure intermediate views presentation
public protocol IntermediateActionPresentationDelegate: class {
    
    ///Returns intermediate view controller to be presented by segue. 
    ///If returns nil then segue will present it's destination view controller.
    func intermediateViewControllerForSegue(segue: IntermediateActionSegue) -> UIViewController?
    
    ///Returns presentation style for intermediate view controller.
    ///Default implementation returns `Show`.
    func intermediateViewControllerPresentationStyleForSegue(segue: IntermediateActionSegue) -> IntermediateActionSeguePresentationStyle
    
    ///Called when intermediate view controller is going to be presented .
    ///Use this method to change or setup presentation.
    ///Default implementation does nothing.
    func willPresentIntermediateViewController(intermediateViewController: UIViewController, segue: IntermediateActionSegue)
    
    ///Called when intermediate view controller completed its task.
    ///Should return `true` if segue should complete and present destination view controller or `false` if it should be aborted.
    ///Default implementation returns `true`.
    func intermediateViewControllerCompleted(intermediateViewController: UIViewController, success: Bool, completionData: AnyObject?) -> Bool

}

//Default delegate methods implementations
extension IntermediateActionPresentationDelegate {
    public func intermediateViewControllerPresentationStyleForSegue(segue: IntermediateActionSegue) -> IntermediateActionSeguePresentationStyle {
        return .Show
    }
    
    public func intermediateViewControllerCompleted(intermediateViewController: UIViewController, success: Bool, completionData: AnyObject?) -> Bool {
        return success
    }
    
    public func willPresentIntermediateViewController(intermediateViewController: UIViewController, segue: IntermediateActionSegue) { }
}

extension UIStoryboard {
    
    private struct AssociatedKeys {
        static var segueKey = 0
    }
    
    ///Not nil if storyboard was used to instantiate view controller presented with intermediate action segue.
    ///Used to provide segue for controllers other then initialIntermediateController
    private var intermediateActionSegue: IntermediateActionSegue? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.segueKey) as? IntermediateActionSegue
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.segueKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

extension UIViewController {

    private struct AssociatedKeys {
        static var segueKey = 0
    }
    
    ///Not nil if controller was presented cause of intermediate action segue
    public private(set) var intermediateActionSegue: IntermediateActionSegue? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.segueKey) as? IntermediateActionSegue ?? storyboard?.intermediateActionSegue
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.segueKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

}

public class IntermediateActionSegue: UIStoryboardSegue {

    private weak var _delegate: IntermediateActionPresentationDelegate?
    
    ///Delegate object or source view controller if it conforms to IntermediateActionPresentationDelegate
    public final weak var intermediateActionPresentationDelegate: IntermediateActionPresentationDelegate? {
        get {
            return _delegate ?? (self.sourceViewController as? IntermediateActionPresentationDelegate)
        }
        set {
            _delegate = newValue
        }
    }
    
    ///Reference to initial view controller presented for intermediate action
    public private(set) final var initialIntermediateController: UIViewController?
    
    ///View controller to present for intermediate action. If nil then segue will ask its delegate to provide it.
    public var intermediateViewController: UIViewController?
    
    ///Presentation style for intermediate view controller. If nil then segue will ask its delegate to provide it.
    ///If not provided will use `Show`
    public var intermediateViewControllerPresentationStyle: IntermediateActionSeguePresentationStyle?
    
    private func _presentationStyle() -> IntermediateActionSeguePresentationStyle {
        return intermediateViewControllerPresentationStyle ??
            intermediateActionPresentationDelegate?.intermediateViewControllerPresentationStyleForSegue(self) ??
            .Show
    }
    
    private func _intermediateViewController() -> UIViewController? {
        return intermediateViewController ?? intermediateActionPresentationDelegate?.intermediateViewControllerForSegue(self)
    }

    override public final func perform() {
        
        if let intermediateViewController = _intermediateViewController() {
                
                self.initialIntermediateController = intermediateViewController
                intermediateViewController.intermediateActionSegue = self
                intermediateViewController.storyboard?.intermediateActionSegue = self
                
                let presentationStyle = _presentationStyle()
            
                if case presentationStyle = IntermediateActionSeguePresentationStyle.Show {
                    sourceViewController.showViewController(intermediateViewController, sender: nil)
                }
                else {
                    switch presentationStyle {
                    case .Modal:
                        intermediateViewController.modalPresentationStyle = .FullScreen
                        
                    case .Popover:
                        intermediateViewController.modalPresentationStyle = .Popover
                        
                    case .Custom:
                        intermediateViewController.modalPresentationStyle = .Custom
                    default: return
                    }
                    
                    intermediateActionPresentationDelegate?.willPresentIntermediateViewController(intermediateViewController, segue: self)
                    sourceViewController.presentViewController(intermediateViewController, animated: true, completion: nil)
                }
        }
        else {
            sourceViewController.showViewController(destinationViewController, sender: sourceViewController)
        }
    }
    
    ///Should be called to indicate that intermediate view controller completed its task.
    public final func intermediateViewControllerCompleted(viewController: UIViewController, success: Bool, completionData: AnyObject?) {
        guard let delegate = intermediateActionPresentationDelegate else { return }
        
        let shouldComplete = delegate.intermediateViewControllerCompleted(viewController, success: success, completionData: completionData)

        //If there is a modal presentation somewhere in the line we first dismiss it.
        //But not if it's how inital controller was presented because we will handle it in complete/abort.
        if let _ = sourceViewController.presentedViewController where sourceViewController.presentedViewController !== initialIntermediateController {
            sourceViewController.dismissViewControllerAnimated(true, completion: nil)
        }

        if shouldComplete {
            complete()
        }
        else {
            abort()
        }
    }
    
    ///Completes segue dismissing initial intermediate view and presenting destination view controller
    private func complete() {
        //there could be modal presentation
        if let presentingController = initialIntermediateController?.presentingViewController {
            presentingController.dismissViewControllerAnimated(true) {
                self.sourceViewController.showViewController(self.destinationViewController, sender: self.sourceViewController)
                
                self.initialIntermediateController?.intermediateActionSegue = nil
                self.initialIntermediateController = nil
            }
        }
            // or navigation
        else if let
            navigationController = initialIntermediateController?.navigationController,
            index = navigationController.viewControllers.indexOf(sourceViewController) {
                
                let count = navigationController.viewControllers.count
                
                sourceViewController.showViewController(destinationViewController, sender: sourceViewController)
                let range = Range(start: index + 1, end: count)
                navigationController.viewControllers.removeRange(range)
                
                self.initialIntermediateController?.intermediateActionSegue = nil
                self.initialIntermediateController = nil
        }
    }
    
    ///Aborts segue dismissing initial intermediate view
    private func abort() {
        if let presentingController = initialIntermediateController?.presentingViewController {
            presentingController.dismissViewControllerAnimated(true, completion: nil)
        }
        else if let navigationController = initialIntermediateController?.navigationController,
            index = navigationController.viewControllers.indexOf(sourceViewController) {
                //popToViewController cause "unbalanced calls" warning on iPad
                //this does the same but without warning
                let count = navigationController.viewControllers.count
                let range = Range(start: index + 1, end: count)
                navigationController.viewControllers.removeRange(range)
        }
        
        self.initialIntermediateController?.intermediateActionSegue = nil
        self.initialIntermediateController = nil
    }

}

