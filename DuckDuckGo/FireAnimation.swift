//
//  FireAnimation.swift
//  DuckDuckGo
//
//  Copyright © 2017 DuckDuckGo. All rights reserved.
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
import Lottie
import Core

class FireButtonAnimationSettings {

    @UserDefaultsWrapper(key: .animationType, defaultValue: 0)
    var animationType: Int {
        didSet {
            animationCycle = 0
        }
    }

    @UserDefaultsWrapper(key: .animationCycle, defaultValue: 0)
    var animationCycle: Int

}

extension FireAnimation: NibLoading {}

class FireAnimation: UIView {

    @IBOutlet var image: UIImageView!
    @IBOutlet var offset: NSLayoutConstraint!

    struct Constants {
        static let animationDuration = 1.2
        static let endDelayDuration = animationDuration + 0.2
        static let endAnimationDuration = 0.2
    }

    enum AnimName: String, CaseIterable {

        case fireRisingFlame = "01_Fire_Hero_Rising_Flame"
        case fireLightning = "01_Fire_Lightning_2"
        case fireMatch = "01_Fire_Match_Swirl"
        case waterSwirl = "02_Water_Swirl"
        case waterHeroDroplet = "02_Water_Hero_Droplet"
        case waterWash = "02_Water_Wash"
        case abstractHeroSqueegee = "03_Abstract_Hero_Squeegee"
        case abstractKaleidoscope1 = "03_Abstract_Kaleidoscope_1"
        case abstractKaleidoscope3 = "03_Abstract_Kaleidoscope_3"

    }

    struct AnimSpec {

        static let fireRisingFlame = AnimSpec(name: .fireRisingFlame, transition: 0.35)
        static let fireLightning = AnimSpec(name: .fireLightning, transition: 0.40)
        static let fireMatch = AnimSpec(name: .fireMatch, transition: 0.61)

        static let waterSwirl = AnimSpec(name: .waterSwirl, transition: 0.5)
        static let waterHeroDroplet = AnimSpec(name: .waterHeroDroplet, transition: 0.5)
        static let waterWash = AnimSpec(name: .waterWash, transition: 0.3)

        static let abstractHeroSqueegee = AnimSpec(name: .abstractHeroSqueegee, transition: 0.5)
        static let abstractKaleidoscope1 = AnimSpec(name: .abstractKaleidoscope1, transition: 0.5)
        static let abstractKaleidoscope3 = AnimSpec(name: .abstractKaleidoscope3, transition: 0.5)

        let name: AnimName
        let transition: CGFloat

    }

    static let anims: [[AnimSpec]] = [
        [ .fireRisingFlame, .fireRisingFlame, .fireRisingFlame, .fireLightning, .fireRisingFlame, .fireRisingFlame, .fireMatch],
        [ .waterSwirl, .waterSwirl, .waterSwirl, .waterHeroDroplet, .waterSwirl, .waterSwirl, .waterWash ],
        [ .abstractHeroSqueegee, .abstractHeroSqueegee, .abstractHeroSqueegee, .abstractKaleidoscope1,
                                 .abstractHeroSqueegee, .abstractHeroSqueegee, .abstractKaleidoscope3 ]
    ]

    static var animCache: [AnimName: Any] = [:]

    static func preload() {
        print("***", #function, "IN")
        AnimName.allCases.forEach {
            let anim = Animation.named($0.rawValue)
            animCache[$0] = anim
            print("***", #function, $0.rawValue, anim!.endFrame)
        }
        print("***", #function, "OUT")
    }

    static func animate(completion: @escaping () -> Void) {

        guard let window = UIApplication.shared.keyWindow else {
            completion()
            return
        }

        let animView = AnimationView()
        animView.frame = window.frame
        animView.contentMode = .scaleAspectFill
        window.addSubview(animView)

        let settings = FireButtonAnimationSettings()
        let animCycle = anims[settings.animationType]
        if settings.animationCycle >= animCycle.count {
            settings.animationCycle = 0
        }
        let animSpec = animCycle[settings.animationCycle]
        settings.animationCycle += 1

        let cachedData = animCache[animSpec.name] as? Animation ?? Animation.named(animSpec.name.rawValue)

        animView.animation = cachedData

// Accurate method, maybe causes a delay?
        animView.play(toProgress: animSpec.transition) { _ in
            animView.play(fromProgress: animView.currentProgress, toProgress: 1.0) { _ in
                animView.removeFromSuperview()
                window.showBottomToast(UserText.actionForgetAllDone, duration: 1)
            }
            completion()
       }

// Alt: inaccurate method
//        animView.play() { _ in
//            animView.removeFromSuperview()
//            window.showBottomToast(UserText.actionForgetAllDone, duration: 1)
//        }
//
//        let delay = Double(CGFloat(animView.animation?.duration ?? 0) * animSpec.transition)
//        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
//            completion()
//        }

    }

    private static var animatedImages: [UIImage] {
        var images = [UIImage]()
        for i in 1...20 {
            let filename = String(format: "flames00%02d", i)
            let image = #imageLiteral(resourceName: filename)
            images.append(image)
        }
        return images
    }

}
