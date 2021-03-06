//
//  File.swift
//  Empty
//
//  Created by bsidesoft on 2018. 3. 8..
//  Copyright © 2018년 com.bsidesoft.ios. All rights reserved.
//

import Foundation
import UIKit

extension UIControl{
    typealias listener = ()->Void
    class H{
        let a:listener
        init(_ v:@escaping listener){a = v}
        @objc func h(){a()}
    }
    func addTarget(_ f:UIControlEvents, _ a:@escaping listener){
        let h = H(a)
        self.addTarget(h, action: #selector(h.h), for: f)
        objc_setAssociatedObject(self, "\(arc4random())", h, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
    }
}


extension UINavigationController {
    static private let ctrlStack = NSMutableDictionary()

    var coverControllers: NSMutableArray {

        let stack = (UINavigationController.ctrlStack[hash] as? NSMutableArray) ?? NSMutableArray.init()
        UINavigationController.ctrlStack[hash] = stack
        return stack

    }

}

extension UIViewController{

    static private let vms = NSMutableDictionary()

    var vm: VM {
        let clsName = "\(self)"
        if UIViewController.vms[clsName] == nil {
            UIViewController.vms[clsName] = VM(self)
            self.initVM()
        }
        return UIViewController.vms[clsName] as! VM
    }


    /// [Abstract]
    @objc
    func initVM() {
    }

    @discardableResult
	func pushRouter(_ c: UIViewController, _ type: Router.type) -> Int {

        let stack = vm.navStack

        if case .replace = type {
            stack.removeLastObject()
            stack.removeLastObject()
        }

        switch (self, type) {

        // UINavigationController
        case (let base as UINavigationController, .replace):
            base.viewControllers = base.viewControllers.dropLast() + [c]

        // UIViewController
        case (_, .replace):
            if let last = stack.lastObject as? UIViewController {
                last.removeFromParentViewController()
                last.view.removeFromSuperview()
            }
            addChildViewController(c)
            view.addSubview(c.view)

        case (_, .add):
            addChildViewController(c)
            view.addSubview(c.view)

        case (_, .cover):  // viewcontroller의 라이프사이클을 강제호출해준다.
            if let last = stack.lastObject as? UIViewController {
                last.viewDidDisappear(false)
            }

            if let nv = self as? UINavigationController {
                nv.coverControllers.add(c)
                c.vm.parent = nv
            } else {
                addChildViewController(c)
            }
            view.addSubview(c.view)

        }

        stack.add(type) // !주의 - 2번 빼야 함..
        stack.add(c)

        return stack.count - 1

	}


	func popRouter(){

        let stack = vm.navStack
        guard let c = stack.lastObject as? UIViewController else { return }

        stack.removeLastObject()
        let type = stack.lastObject as! Router.type
        stack.removeLastObject()

        if case .cover = type, let last = stack.lastObject as? UIViewController {
            last.viewWillAppear(false)
        }

        switch (self) {
        case (let base as UINavigationController):
            if case .cover = type {
                c.view.removeFromSuperview()
                base.coverControllers.removeLastObject()
                c.vm.parent = nil
            } else {
                base.viewControllers = base.viewControllers.dropLast() + []
            }

        default:
            c.removeFromParentViewController()
            c.view.removeFromSuperview()
        }

	}

    func removeRouter(_ idx: Int) {

        let stack = vm.navStack
        guard stack.count > idx else { return }

        var isCover = false
        var idx = idx
        while idx < stack.count {
            if let vc = stack.object(at: idx) as? UIViewController,
               let type = stack.object(at: idx - 1) as? Router.type {

                switch (self, type) {
                case (let base as UINavigationController, .replace):
                    base.viewControllers = base.viewControllers.dropLast() + []
                default:
                    if case .cover = type {
                        isCover = true
                    }
                    vc.removeFromParentViewController()
                    vc.view.removeFromSuperview()
                }
                stack.remove(vc)
                stack.remove(type)
            }
            idx += 2
        }

        if isCover, let last = stack.lastObject as? UIViewController {
            last.viewWillAppear(false)
        }

    }
}
