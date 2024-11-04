open UIKit

let greetings =
  [| "English", "Hello World!"
   ; "Spanish", "Hola Mundo!"
   ; "French", "Bonjour, le monde !"
   |]

module GreetingsTVC = struct
  module LLong = Objc.LLong

  (* Prototype cell for this ID is registered in Main.xib *)
  let cellID = new_string "Cell"

  let numberOfSectionsInTableView =
    UITableViewControllerMethods.numberOfSectionsInTableView'
      (fun _self _cmd _tv -> LLong.of_int 1)

  let titleForHeaderInSection =
    UITableViewControllerMethods.tableView'titleForHeaderInSection'
      (fun _self _cmd _tv _section -> new_string "Language")

  let numberOfRowsInSection =
    UITableViewControllerMethods.tableView'numberOfRowsInSection'
      (fun _self _cmd _tv _section -> LLong.of_int (Array.length greetings))

  let cellForRowAtIndexPath =
    UITableViewControllerMethods.tableView'cellForRowAtIndexPath'
      (fun _self _cmd tv index_path ->
        let cell =
          tv |> UITableView.dequeueReusableCellWithIdentifier' cellID
            ~forIndexPath: index_path
        and i = index_path |> NSIndexPath.row in
        cell
        |> UITableViewCell.textLabel
        |> UILabel.setText (new_string (fst greetings.(i)));
        cell)

  let didSelectRowAtIndexPath =
    UITableViewDelegate.tableView'didSelectRowAtIndexPath'
      (fun self _cmd _tv index_path ->
        let i = index_path |> NSIndexPath.row
        and split_vc =
          self
          |> UIViewController.navigationController
          |> UIViewController.parentViewController
        in
        split_vc
        |> UISplitViewController.viewControllerForColumn
            _UISplitViewControllerColumnSecondary
        |> UIViewController.view
        |> UIView.viewWithTag 1
        |> UILabel.setText (new_string (snd greetings.(i)));
        split_vc
        |> UISplitViewController.showColumn
            _UISplitViewControllerColumnSecondary)

  (* This class is referenced in Main.xib *)
  let _self =
    Class.define "GreetingsTVC"
      ~superclass: UITableViewController.self
      ~methods:
        [ numberOfSectionsInTableView
        ; titleForHeaderInSection
        ; numberOfRowsInSection
        ; cellForRowAtIndexPath
        ; didSelectRowAtIndexPath
        ]
end

module SceneDelegate = struct
  (* This class is referenced in Info.plist, UISceneConfigurations key.
    It is instantiated from UIApplicationMain. *)
  let _self =
    Class.define "SceneDelegate"
      ~superclass: UIResponder.self
      ~protocols: [Objc.get_protocol "UIWindowSceneDelegate"]
      ~properties: [Property.define "window" Objc_type.id]
end

module AppDelegate = struct
  (* This class is referenced in main.m. It is instantiated from UIApplicationMain. *)
  let _self =
    Class.define "AppDelegate"
      ~superclass: UIResponder.self
      ~methods:
        [ UIApplicationDelegate.application'didFinishLaunchingWithOptions'
          (fun self _cmd _app _opts ->
            NSNotificationCenter.self
            |> NSNotificationCenterClass.defaultCenter
            |> NSNotificationCenter.addObserver self
              ~selector_: (selector "sceneActivated")
              ~name: _UISceneDidActivateNotification
              ~object_: nil;
            true)

        ; Method.define
          ~cmd: (selector "sceneActivated")
          ~args: Objc_type.[id]
          ~return: Objc_type.void
          (fun _self _cmd notif ->
            notif
            |> NSNotification.object_
            |> UIWindowScene.windows
            |> NSArray.lastObject
            |> UIWindow.rootViewController
            |> UISplitViewController.showColumn _UISplitViewControllerColumnPrimary)

        ; UIApplicationDelegate.application'configurationForConnectingSceneSession'options'
          (fun _self _cmd _app conn_session _opts ->
            alloc UISceneConfiguration.self
            |> UISceneConfiguration.initWithName (new_string "Default Configuration")
                ~sessionRole: (UISceneSession.role conn_session))
        ]
end