//
//  FireAnimationSettingsViewController.swift
//  DuckDuckGo
//
//  Created by Chris Brind on 07/09/2020.
//  Copyright © 2020 DuckDuckGo. All rights reserved.
//

import UIKit

class FireAnimationSettingsViewController: UITableViewController {

    static let model = ["Fire", "Water", "Abstract" ]

    private let settings = FireButtonAnimationSettings()

    override func viewDidLoad() {
        super.viewDidLoad()
        applyTheme(ThemeManager.shared.currentTheme)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Self.model.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let theme = ThemeManager.shared.currentTheme
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")!
        cell.textLabel?.textColor = theme.tableCellTextColor
        cell.backgroundColor = theme.tableCellBackgroundColor
        cell.setHighlightedStateBackgroundColor(theme.tableCellHighlightedBackgroundColor)
        cell.tintColor = theme.buttonTintColor
        cell.textLabel?.text = Self.model[indexPath.row]
        cell.accessoryType = settings.animationType == indexPath.row ? .checkmark : .none
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        settings.animationType = indexPath.row
        tableView.reloadData()
    }

}

extension FireAnimationSettingsViewController: Themable {

    func decorate(with theme: Theme) {
        tableView.backgroundColor = theme.backgroundColor
        tableView.separatorColor = theme.tableCellSeparatorColor
        tableView.reloadData()
    }

}
