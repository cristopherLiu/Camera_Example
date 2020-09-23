//
//  SquareMaskView.swift
//  Camera_Example
//
//  Created by hjliu on 2020/9/23.
//

import UIKit

class SquareMaskView: UIView {
  
  @IBOutlet weak var transparentHoleView: UIView!
  
  // MARK: - Drawing
  override func draw(_ rect: CGRect) {
    super.draw(rect)
    
    if self.transparentHoleView != nil {
      // Ensures to use the current background color to set the filling color
      
      self.backgroundColor?.setFill()
      UIRectFill(rect)
      
      let path = CGMutablePath()
      path.addRect(bounds)
      
      //      path.addRect(transparentHoleView.frame)
      let middlePath = UIBezierPath(roundedRect: self.transparentHoleView.frame, cornerRadius: 18)
      path.addPath(middlePath.cgPath)
      
      let layer = CAShapeLayer()
      layer.path = path
      layer.fillRule = CAShapeLayerFillRule.evenOdd
      self.layer.mask = layer
    }
  }
  
  // MARK: - Initialization
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
  }
}
