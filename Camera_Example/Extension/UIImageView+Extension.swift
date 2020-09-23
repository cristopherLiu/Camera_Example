//
//  UIImageView+Extension.swift
//  MyCode
//
//  Created by 劉紘任 on 2020/5/18.
//  Copyright © 2020 劉紘任. All rights reserved.
//

import UIKit

extension UIImageView {
  
  func setImageColor(color: UIColor) {
    let templateImage = self.image?.withRenderingMode(.alwaysTemplate)
    self.image = templateImage
    self.tintColor = color
  }
}
