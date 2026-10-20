//
//  UIApplication+Extension.swift
//

import UIKit

extension UIApplication {
    var visibleViewController: UIViewController? {
        let windows = connectedScenes.flatMap { ($0 as? UIWindowScene)?.windows ?? [] }
        let keyWindow = windows.first { $0.isKeyWindow }
        return keyWindow?.visibleViewController
    }
}
