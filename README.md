###Intermediate action segue

_Proof of concept._

It's very often when we need to perform segue on some conditions. For instance only if user is logged in or accepted turms of service. If condition is not met then we want to present some other screen to make user to do some required action and only when user completes that action successfully we perform the initial segue.

The idea is to have a special subclass of `UIStoryboardSegue` that can handle such scenarios.

###Design goals:

- segue should know nothing about current application context and application (view controllers) should know as little as possible about their presentation context (for instance that they were presented as intermediate controllers)
- segue should support different kinds of presentation style like modal, fullscreen, popover and custom
- segue should be adaptive
- there should be a way to present single view controller or a storyboard as intermediate action
- segue API should look like UIKit API, meaning that client code should be able to change presentation using delegate callbacks

###IntermediateActionSegue

`UIStoryboardSegue` subclass that instead of presenting destination view controller first presents intermediate view controller and when its task is finished successfully completes transition to destination view controller or aborts it.

###IntermediateActionPresentationDelegate

Protocol to control style of intermediate view controller presentation. Can be used to setup modal, popover or any custom presentation. Also is used to provide segue with concrete instance of intermediate view controller.
