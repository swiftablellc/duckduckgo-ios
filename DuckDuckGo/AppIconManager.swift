//
//  AppIconManager.swift
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
import os.log
import WidgetKit

class AppIconManager {

    static var shared = AppIconManager()

    var isAppIconChangeSupported: Bool {
        if #available(iOS 10.3, *) {
            return UIApplication.shared.supportsAlternateIcons
        } else {
            return false
        }
    }

    enum AppIconManagerError: Error {
        case changeNotSupported
    }

    @available(iOS 10.3, *)
    fileprivate func changeAppIconWhereSupported(_ appIcon: AppIcon, _ completionHandler: ((Error?) -> Void)?) {
        let alternateIconName = appIcon != AppIcon.defaultAppIcon ? appIcon.rawValue : nil
        UIApplication.shared.setAlternateIconName(alternateIconName) { error in
            if let error = error {
                Pixel.fire(pixel: .settingsAppIconChangeFailed, error: error)
                os_log("Error while changing app icon: %s", log: generalLog, type: .debug, error.localizedDescription)
                completionHandler?(error)
            } else {
                completionHandler?(nil)
                SharedSettings.shared.appIconName = appIcon.rawValue
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
    }

    func changeAppIcon(_ appIcon: AppIcon, completionHandler: ((Error?) -> Void)? = nil) {
        if self.appIcon == appIcon {
            completionHandler?(nil)
            return
        }

        if #available(iOS 10.3, *), isAppIconChangeSupported {
            changeAppIconWhereSupported(appIcon, completionHandler)
        } else {
            let error = AppIconManagerError.changeNotSupported
            Pixel.fire(pixel: .settingsAppIconChangeNotSupported, error: error)
            os_log("Error while changing app icon: %s", log: generalLog, type: .debug, error.localizedDescription)
            completionHandler?(error)
        }
    }

    var appIcon: AppIcon {
        if #available(iOS 10.3, *) {
            guard let appIconName = UIApplication.shared.alternateIconName,
                let appIcon = AppIcon(rawValue: appIconName) else {
                return AppIcon.defaultAppIcon
            }

            return appIcon
        } else {
            return AppIcon.defaultAppIcon
        }
    }

}
