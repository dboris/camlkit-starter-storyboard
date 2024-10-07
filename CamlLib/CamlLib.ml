open Foundation
open UIKit
open Runtime

let greetings =
  [| "English", "Hello World!"
   ; "Spanish", "Hola Mundo!"
   |]

module GreetingsTVC = struct
  module LLong = Objc.LLong

  (* Prototype cell for this ID is registered in Main.xib *)
  let cellID = new_string "Cell"

  let numberOfSectionsInTableView =
    Method.define
      ~args: Objc_t.[id]
      ~return: Objc_t.llong
      ~cmd: (selector "numberOfSectionsInTableView:")
      (fun _self _cmd _tv -> LLong.of_int 1)

  let titleForHeaderInSection =
    Method.define
      ~args: Objc_t.[id; llong]
      ~return: Objc_t.id
      ~cmd: (selector "tableView:titleForHeaderInSection:")
      (fun _self _cmd _tv _section -> new_string "Language")

  let numberOfRowsInSection =
    Method.define
      ~args: Objc_t.[id; llong]
      ~return: Objc_t.llong
      ~cmd: (selector "tableView:numberOfRowsInSection:")
      (fun _self _cmd _tv _section -> LLong.of_int (Array.length greetings))

  let cellForRowAtIndexPath =
    Method.define
      ~args: Objc_t.[id; id]
      ~return: Objc_t.id
      ~cmd: (selector "tableView:cellForRowAtIndexPath:")
      (fun _self _cmd tv index_path ->
        let cell =
          tv |> UITableView.dequeueReusableCellWithIdentifier' cellID
            ~forIndexPath: index_path
        and i = index_path |> NSIndexPath.row |> LLong.to_int in
        cell
        |> UITableViewCell.textLabel
        |> UILabel.setText (new_string (fst greetings.(i)));
        cell)

  let didSelectRowAtIndexPath =
    Method.define
      ~args: Objc_t.[id; id]
      ~return: Objc_t.void
      ~cmd: (selector "tableView:didSelectRowAtIndexPath:")
      (fun self _cmd _tv index_path ->
        let i = index_path |> NSIndexPath.row |> LLong.to_int
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

  let viewDidLoad =
    Method.define
      ~args: Objc_t.[]
      ~return: Objc_t.void
      ~cmd: (selector "viewDidLoad")
      (fun self cmd ->
        self |> msg_super cmd ~args: Objc_t.[] ~return: Objc_t.void;
        self |> UIViewController.setTitle (new_string "Greetings"))

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
        ; viewDidLoad
        ]
end

module SceneDelegate = struct
  (* This class is referenced in Info.plist, UISceneConfigurations key.
    It is instantiated from UIApplicationMain. *)
  let _self =
    Class.define "SceneDelegate"
      ~superclass: UIResponder.self
      ~protocols: [Objc.get_protocol "UIWindowSceneDelegate"]
      ~ivars: [Ivar.define "window" Objc_t.id]
      ~methods: (Property._object_ "window" Objc_t.id ())
end

module AppDelegate = struct
  (* This class is referenced in main.m. It is instantiated from UIApplicationMain. *)
  let _self =
    Class.define "AppDelegate"
      ~superclass: UIResponder.self
      ~methods:
        [ Method.define
          ~cmd: (selector "application:didFinishLaunchingWithOptions:")
          ~args: Objc_t.[id; id]
          ~return: Objc_t.bool
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
          ~args: Objc_t.[id]
          ~return: Objc_t.void
          (fun _self _cmd _scene -> Printf.eprintf "sceneActivated...\n%!")

        ; Method.define
          ~cmd: (selector "application:configurationForConnectingSceneSession:options:")
          ~args: Objc_t.[id; id; id]
          ~return: Objc_t.id
          (fun _self _cmd _app conn_session _opts ->
            alloc UISceneConfiguration.self
            |> UISceneConfiguration.initWithName (new_string "Default Configuration")
                ~sessionRole: (UISceneSession.role conn_session))
        ]
end