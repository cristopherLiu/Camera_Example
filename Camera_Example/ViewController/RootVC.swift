//
//  RootVC.swift
//  Camera_Example
//
//  Created by hjliu on 2020/9/23.
//

import UIKit

class RootVC: UIViewController {
  
  private lazy var capturePreviewView: UIView = {
    let view = UIView()
    view.backgroundColor = UIColor.bk
    view.translatesAutoresizingMaskIntoConstraints = false
    return view
  }()
  
  private lazy var qrCodeFrameView: CodeFrameView = {
    let view = CodeFrameView()
    view.translatesAutoresizingMaskIntoConstraints = false
    return view
  }()
  
  private lazy var squareMaskView: SquareMaskView = {
    let view = SquareMaskView()
    view.backgroundColor = UIColor.bk_5
    view.translatesAutoresizingMaskIntoConstraints = false
    return view
  }()
  
  private lazy var captureButton: UIButton = {
    let button = UIButton()
    button.layer.cornerRadius = 36
    button.layer.borderWidth = 4
    button.layer.borderColor = UIColor.w.cgColor
    button.clipsToBounds = true
    button.addTarget(self, action: #selector(captureImage), for: .touchUpInside)
    button.translatesAutoresizingMaskIntoConstraints = false
    return button
  }()
  
  private lazy var torchButton: UIButton = {
    let btn = UIButton()
//    btn.addTarget(self, action: #selector(switchTorch), for: .touchUpInside)
    btn.translatesAutoresizingMaskIntoConstraints = false
    return btn
  }()
  
  private lazy var textContentView: UIView = {
    let view = UIView()
    view.backgroundColor = UIColor.w
    view.translatesAutoresizingMaskIntoConstraints = false
    return view
  }()
  
  private lazy var photoReviewer: UIImageView = {
    let view = UIImageView()
    view.layer.cornerRadius = 8
    view.clipsToBounds = true
    view.backgroundColor = UIColor.gy
    view.contentMode = .scaleAspectFill
    view.translatesAutoresizingMaskIntoConstraints = false
    return view
  }()
  
  private lazy var textLabel: UILabel = {
    let label = UILabel()
    label.numberOfLines = 0
    label.textColor = UIColor.bk
    label.textAlignment = .center
    label.font = UIFont.systemFont(ofSize: 16.0)
    label.translatesAutoresizingMaskIntoConstraints = false
    return label
  }()
  
  /// HELPER
  let caremaHelper = CameraHelper()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.initView()
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    capturePreviewView.addObserver(self, forKeyPath: #keyPath(UIView.bounds), options: .new, context: nil) // 監控排版變化
    initCarema()
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    capturePreviewView.removeObserver(self, forKeyPath: #keyPath(UIView.bounds))
  }
  
  func initView() {
    view.addSubview(capturePreviewView)
    view.addSubview(textContentView)
    view.addSubview(captureButton)
    view.addSubview(torchButton)
    
    capturePreviewView.addSubview(qrCodeFrameView)
    capturePreviewView.addSubview(squareMaskView)
    
    textContentView.addSubview(textLabel)
    textContentView.addSubview(photoReviewer)
    
    NSLayoutConstraint.activate([
      
      capturePreviewView.topAnchor.constraint(equalTo: view.topAnchor),
      capturePreviewView.leftAnchor.constraint(equalTo: view.leftAnchor),
      capturePreviewView.rightAnchor.constraint(equalTo: view.rightAnchor),
      
      qrCodeFrameView.centerXAnchor.constraint(equalTo: capturePreviewView.centerXAnchor),
      qrCodeFrameView.centerYAnchor.constraint(equalTo: capturePreviewView.centerYAnchor),
      qrCodeFrameView.heightAnchor.constraint(equalTo: qrCodeFrameView.widthAnchor),
      qrCodeFrameView.widthAnchor.constraint(equalTo: capturePreviewView.widthAnchor, multiplier: 0.8),
      
      squareMaskView.topAnchor.constraint(equalTo: capturePreviewView.topAnchor),
      squareMaskView.leftAnchor.constraint(equalTo: capturePreviewView.leftAnchor),
      squareMaskView.rightAnchor.constraint(equalTo: capturePreviewView.rightAnchor),
      squareMaskView.bottomAnchor.constraint(equalTo: capturePreviewView.bottomAnchor),
      
      captureButton.widthAnchor.constraint(equalToConstant: 72),
      captureButton.heightAnchor.constraint(equalToConstant: 72),
      captureButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      captureButton.bottomAnchor.constraint(equalTo: capturePreviewView.bottomAnchor, constant: -24),
      
      torchButton.rightAnchor.constraint(equalTo: capturePreviewView.rightAnchor, constant: -16),
      torchButton.bottomAnchor.constraint(equalTo: capturePreviewView.bottomAnchor, constant: -44),
      torchButton.widthAnchor.constraint(equalToConstant: 32),
      torchButton.heightAnchor.constraint(equalToConstant: 32),
      
      textContentView.topAnchor.constraint(equalTo: capturePreviewView.bottomAnchor),
      textContentView.leftAnchor.constraint(equalTo: view.leftAnchor),
      textContentView.rightAnchor.constraint(equalTo: view.rightAnchor),
      textContentView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      textContentView.heightAnchor.constraint(equalToConstant: 160),
      
      textLabel.leftAnchor.constraint(equalTo: photoReviewer.rightAnchor, constant: 16),
      textLabel.rightAnchor.constraint(equalTo: textContentView.rightAnchor, constant: -16),
      textLabel.centerYAnchor.constraint(equalTo: textContentView.centerYAnchor),
      
      photoReviewer.widthAnchor.constraint(equalToConstant: 80),
      photoReviewer.heightAnchor.constraint(equalToConstant: 80),
      photoReviewer.leftAnchor.constraint(equalTo: textContentView.leftAnchor, constant: 16),
      photoReviewer.centerYAnchor.constraint(equalTo: textContentView.centerYAnchor),
//      photoReviewer.bottomAnchor.constraint(equalTo: textContentView.bottomAnchor, constant: -16),
    ])
  }
  
  func initCarema() {
    
    caremaHelper.prepare { (error) in
      
      if let _ = error {
      } else {
        self.setMaskView()
      }
    }
    caremaHelper.delegate = self
  }
  
  
  // 設定相機的遮罩畫面
  private func setMaskView() {
    
    if let previewLayer = self.caremaHelper.previewLayer {
      
      capturePreviewView.layer.insertSublayer(previewLayer, at: 0)
      previewLayer.frame = capturePreviewView.bounds
      
      // 遮罩view
      self.squareMaskView.transparentHoleView = self.qrCodeFrameView
      self.squareMaskView.setNeedsDisplay()
      
      // 觸碰手勢
      //      let gesture = UITapGestureRecognizer(target: self, action: #selector(handleTapToFocus(sender:)))
      //      maskView.addGestureRecognizer(gesture)
    }
  }
  
  override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
    if let objectView = object as? UIView, objectView === self.capturePreviewView, keyPath == #keyPath(UIView.bounds) {
      self.caremaHelper.previewLayer?.frame = objectView.bounds
    }
  }
  
  // 拍照
  @objc func captureImage() {
    caremaHelper.captureImage()
  }
  
  func setText(_ text: String) {
    self.textLabel.text = text
  }
  
  // 動畫
  func scaleUp(_ view: UIView) {
    
//    view.alpha = 0
//    view.transform = CGAffineTransform(scaleX: 0.67, y: 0.67)
//
////    let springTiming = UISpringTimingParameters(mass: 1.0, stiffness: 2.0, damping: 0.2, initialVelocity: .zero)
////    let animator = UIViewPropertyAnimator(duration: 0.33, timingParameters: springTiming)
//
//    let animator = UIViewPropertyAnimator(duration: 0.33, curve: .easeInOut)
//    animator.addAnimations {
//      view.alpha = 1
//    }
//    animator.addAnimations {
//      view.transform = .identity
//    }
//    animator.addCompletion { (end) in
//    }
//    animator.startAnimation()
    
    
    let animator = UIViewPropertyAnimator(duration: 0.5, curve: .easeInOut)
    animator.addAnimations {
      view.transform = CGAffineTransform(scaleX: 0.67, y: 0.67)
    }
    animator.addAnimations({
      view.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
    }, delayFactor: 0.2)
    animator.addAnimations({
      view.transform = .identity
    }, delayFactor: 0.4)
    animator.startAnimation()
  }
}

extension RootVC: CameraHelperDelegate {
  
  // 拍照
  func onCaptureImage(image: UIImage) {
    self.photoReviewer.image = image
    self.scaleUp(self.photoReviewer)
  }
  
  // 掃描
  func qrcodeCapture(value: String) {
    self.setText(value)
  }
  
  func code128Capture(value: String) {
    self.setText(value)
  }
  
  func code39Capture(value: String) {
    self.setText(value)
  }
  
  // Error
  func captureError(error: Error) {
    self.photoReviewer.image = nil
  }
}

//extension RootVC {
//
//  @IBAction func handleTapToFocus(sender: UITapGestureRecognizer) {
//
//    if let device = self.controller.captureDevice, let previewLayer = self.controller.previewLayer {
//
//      let focusPoint = sender.location(in: capturePreviewView)
//      let focusScaledPointX = focusPoint.x / capturePreviewView.frame.size.width
//      let focusScaledPointY = focusPoint.y / capturePreviewView.frame.size.height
//
//      if device.isFocusModeSupported(.autoFocus) && device.isFocusPointOfInterestSupported {
//        do {
//          try device.lockForConfiguration()
//        } catch {
//          print("ERROR: Could not lock camera device for configuration")
//          return
//        }
//        device.focusMode = .autoFocus
//        device.focusPointOfInterest = CGPoint(x: focusScaledPointX, y: focusScaledPointY)
//
//        device.unlockForConfiguration()
//      }
//    }
//  }
//}
