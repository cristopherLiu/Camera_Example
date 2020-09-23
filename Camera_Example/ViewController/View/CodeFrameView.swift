//
//  CodeFrameView.swift
//  Camera_Example
//
//  Created by hjliu on 2020/9/23.
//

import UIKit

class CodeFrameView: UIView {
  
  private lazy var TopLeftView: UIImageView = {
    let view = UIImageView()
    view.image = UIImage.border_topleft
    view.translatesAutoresizingMaskIntoConstraints = false
    return view
  }()
  
  private lazy var TopRightView: UIImageView = {
    let view = UIImageView()
    view.image = UIImage.border_topright
    view.translatesAutoresizingMaskIntoConstraints = false
    return view
  }()
  
  private lazy var BottomLeftView: UIImageView = {
    let view = UIImageView()
    view.image = UIImage.border_bottomleft
    view.translatesAutoresizingMaskIntoConstraints = false
    return view
  }()
  
  private lazy var BottomRightView: UIImageView = {
    let view = UIImageView()
    view.image = UIImage.border_bottomright
    view.translatesAutoresizingMaskIntoConstraints = false
    return view
  }()
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    // 設置背景透明 否則為黑色
    self.backgroundColor = UIColor.clear
    
    initView()
  }
  
  func initView() {
    addSubview(TopLeftView)
    addSubview(TopRightView)
    addSubview(BottomLeftView)
    addSubview(BottomRightView)
    
    NSLayoutConstraint.activate([
      TopLeftView.widthAnchor.constraint(equalToConstant: 36),
      TopLeftView.heightAnchor.constraint(equalToConstant: 36),
      TopLeftView.leftAnchor.constraint(equalTo: self.leftAnchor),
      TopLeftView.topAnchor.constraint(equalTo: self.topAnchor),
      
      TopRightView.widthAnchor.constraint(equalToConstant: 36),
      TopRightView.heightAnchor.constraint(equalToConstant: 36),
      TopRightView.rightAnchor.constraint(equalTo: self.rightAnchor),
      TopRightView.topAnchor.constraint(equalTo: self.topAnchor),
      
      BottomLeftView.widthAnchor.constraint(equalToConstant: 36),
      BottomLeftView.heightAnchor.constraint(equalToConstant: 36),
      BottomLeftView.leftAnchor.constraint(equalTo: self.leftAnchor),
      BottomLeftView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
      
      BottomRightView.widthAnchor.constraint(equalToConstant: 36),
      BottomRightView.heightAnchor.constraint(equalToConstant: 36),
      BottomRightView.rightAnchor.constraint(equalTo: self.rightAnchor),
      BottomRightView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
    ])
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
