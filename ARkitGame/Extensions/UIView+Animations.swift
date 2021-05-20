//
//  UIView+Animations.swift
//  ARkitGame
//
//  Created by Mansi Vadodariya on 20/04/21.
//

import Foundation
import UIKit

extension UIView {
    
    /// Rotate 180 degree to self
    /// - Parameters:
    ///   - duration: duration
    ///   - options: options
    func rotate180(duration: TimeInterval, options: UIView.AnimationOptions) {
        UIView.animate(withDuration: duration, delay: 0, options: options, animations: { [weak self] in
            guard let `self` = self else { return }
            self.transform = self.transform.rotated(by: CGFloat.pi)
        }, completion: nil)
    }
    
    /// Apply radius with border to view
    /// - Parameters:
    ///   - radius: radius
    ///   - borderWidth: borderWidth
    ///   - borderColor: borderColor
    func applyRadius(radius: CGFloat, borderWidth: CGFloat = 0, borderColor: CGColor = UIColor.clear.cgColor) {
        self.layer.borderColor = borderColor
        self.layer.borderWidth = borderWidth
        self.layer.cornerRadius = radius
        self.layer.masksToBounds = true
    }
    
}
