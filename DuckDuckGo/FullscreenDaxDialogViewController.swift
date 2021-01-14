//
//  FullscreenDaxDialogViewController.swift
//  DuckDuckGo
//
//  Copyright © 2020 DuckDuckGo. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import UIKit
import Core

protocol FullscreenDaxDialogDelegate: NSObjectProtocol {

    func hideDaxDialogs(controller: FullscreenDaxDialogViewController)
    func closedDaxDialogs(controller: FullscreenDaxDialogViewController)
    func daxDialogDidRequestFireButtonPosition(controller: FullscreenDaxDialogViewController) -> CGPoint?
    
}

class FullscreenDaxDialogViewController: UIViewController {

    struct Constants {
        
        static let defaultCTAHeight: CGFloat = 100
        
        static let largeHighlightBottom: CGFloat = -40
        static let defaultHighlightBottom: CGFloat = 0
        static let largeAddressBarOffset: CGFloat = -90
        static let defaultAddressBarOffset: CGFloat = -50
        
    }
    @IBOutlet weak var highlightCutOutView: HighlightCutOutView!
    @IBOutlet weak var containerHeight: NSLayoutConstraint!
    
    weak var daxDialogViewController: DaxDialogViewController?
    weak var delegate: FullscreenDaxDialogDelegate?

    var spec: DaxDialogs.BrowsingSpec?
    var woShown: Bool = false
    var fireButtonLocation: CGPoint? //TODO since we have the delegate method, maybe we don't need this now?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        daxDialogViewController?.cta = spec?.cta
        daxDialogViewController?.message = spec?.message
        daxDialogViewController?.onTapCta = dismissCta
        
        highlightCutOutView.fillColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1.0)
        
        NotificationCenter.default.addObserver(self, selector: #selector(orientationDidChange), name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        containerHeight.constant = daxDialogViewController?.calculateHeight() ?? 0
        
        updateCutOut()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let spec = spec {
            Pixel.fire(pixel: spec.pixelName, withAdditionalParameters: [ "wo": woShown ? "1" : "0" ])
        }
        containerHeight.constant = daxDialogViewController?.calculateHeight() ?? 0
        daxDialogViewController?.start()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        if segue.destination is DaxDialogViewController {
            daxDialogViewController = segue.destination as? DaxDialogViewController
        }
    }
    
    @objc
    func orientationDidChange() {
        updateCutOut()
    }
    
    private func updateCutOut() {
        if spec?.highlightAddressBar ?? false {
            //TODO
//            fullScreen.isActive = false
//            showAddressBar.isActive = true
//            highlightBar.isHidden = false
//            highlightBarBottom.constant = AppWidthObserver.shared.isLargeWidth ? Constants.largeHighlightBottom : Constants.defaultHighlightBottom
//            showAddressBar.constant = AppWidthObserver.shared.isLargeWidth ? Constants.largeAddressBarOffset : Constants.defaultAddressBarOffset
        } else if spec?.highlightFireButton ?? false, let pos = delegate?.daxDialogDidRequestFireButtonPosition(controller: self) {
            let size: CGFloat = 56
            let point = CGPoint(x: pos.x - size / 2.0, y: pos.y - size / 2.0)
            let rect = CGRect(origin: point, size: CGSize(width: size, height: size))
            highlightCutOutView.cutOutPath = UIBezierPath(ovalIn: rect)
            highlightCutOutView.setNeedsDisplay()
        } else {
            highlightCutOutView.cutOutPath = nil
        }
    }

    @IBAction func onTapHide() {
        dismiss(animated: true)
        delegate?.hideDaxDialogs(controller: self)
    }
    
    private func dismissCta() {
        dismiss(animated: true)
        delegate?.closedDaxDialogs(controller: self)
    }
    
}

extension TabViewController: FullscreenDaxDialogDelegate {

    func hideDaxDialogs(controller: FullscreenDaxDialogViewController) {

        let alertController = UIAlertController(title: UserText.daxDialogHideTitle,
                                           message: UserText.daxDialogHideMessage,
                                           preferredStyle: isPad ? .alert : .actionSheet)

        alertController.addAction(title: UserText.daxDialogHideButton, style: .default) {
            Pixel.fire(pixel: .daxDialogsHidden, withAdditionalParameters: [ "c": DefaultDaxDialogsSettings().browsingDialogsSeenCount ])
            DaxDialogs.shared.dismiss()
        }
        alertController.addAction(title: UserText.daxDialogHideCancel, style: .cancel)
        present(alertController, animated: true)
        if controller.spec?.highlightAddressBar ?? false {
            chromeDelegate?.omniBar.cancelAllAnimations()
        }
    }
    
    func closedDaxDialogs(controller: FullscreenDaxDialogViewController) {
        if controller.spec?.highlightAddressBar ?? false {
            chromeDelegate?.omniBar.completeAnimations()
        }
        
        if controller.spec != DaxDialogs.BrowsingSpec.fireButtonEducation {
            showDaxDialogOrStartTrackerNetworksAnimationIfNeeded()
        }
        
        if controller.spec == DaxDialogs.BrowsingSpec.fireButtonEducation {
            delegate?.tabDidRequestForgetAll(tab: self)
        }
    }

    func daxDialogDidRequestFireButtonPosition(controller: FullscreenDaxDialogViewController) -> CGPoint? {
        return delegate?.tabDidRequestFireButtonLocation(tab: self)
    }
}

fileprivate extension DefaultDaxDialogsSettings {
    
    var browsingDialogsSeenCount: String {
        let count = [ browsingMajorTrackingSiteShown,
                      browsingWithoutTrackersShown,
                      browsingWithTrackersShown,
                      browsingAfterSearchShown,
                      browsingFireButtonEducationShown].reduce(0, { $0 + ($1 ? 1 : 0) })
        return "\(count)"
    }
    
}
