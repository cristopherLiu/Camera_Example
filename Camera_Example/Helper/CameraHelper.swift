//
//  CameraHelper.swift
//  Camera_Example
//
//  Created by hjliu on 2020/9/23.
//

import AVFoundation
import UIKit

public protocol CameraHelperDelegate: class {
  
  // 拍照
  func onCaptureImage(image: UIImage)
  
  // 掃描
  func qrcodeCapture(value: String)
  func code128Capture(value: String)
  func code39Capture(value: String)
  
  // Error
  func captureError(error: Error)
}

public class CameraHelper: NSObject {
  
  public var captureSession: AVCaptureSession?{
    get{
      return _captureSession
    }
  }
  
  fileprivate var _captureSession: AVCaptureSession?
  fileprivate var currentCameraPosition: CameraPosition?
  
  // 裝置
  fileprivate var frontCamera: AVCaptureDevice?
  fileprivate var rearCamera: AVCaptureDevice?
  
  // 輸入 用來相片擷取
  fileprivate var frontCameraInput: AVCaptureDeviceInput?
  fileprivate var rearCameraInput: AVCaptureDeviceInput?
  
  // 輸出
  fileprivate var photoOutput: AVCapturePhotoOutput?
  fileprivate var metadataOutput: AVCaptureMetadataOutput?
  
  // 預覽畫面
  public var previewLayer: AVCaptureVideoPreviewLayer?
  
  var flashMode = AVCaptureDevice.FlashMode.off // 閃光燈
  var torchMode = AVCaptureDevice.TorchMode.off
  
  public weak var delegate: CameraHelperDelegate?
}

public extension CameraHelper {
  
  func prepare(completionHandler: @escaping (Error?) -> Void) {
    
    func createCaptureSession() {
      self._captureSession = AVCaptureSession()
    }
    
    // 設定裝置
    func configureCaptureDevices() throws {
      
      // 找出裝置上所有可用的內置相機
      let session = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .unspecified)
      let cameras = session.devices.compactMap { $0 }
      guard !cameras.isEmpty else { throw ControllerError.noCamerasAvailable }
      
      for camera in cameras {
        
        // 前鏡頭
        if camera.position == .front {
          self.frontCamera = camera
        }
        
        // 後鏡頭
        if camera.position == .back {
          self.rearCamera = camera
          
          try camera.lockForConfiguration()
          camera.isSubjectAreaChangeMonitoringEnabled = true
          camera.focusMode = AVCaptureDevice.FocusMode.continuousAutoFocus
          camera.exposureMode = AVCaptureDevice.ExposureMode.continuousAutoExposure
          camera.unlockForConfiguration()
        }
      }
    }
    
    // 設定輸入
    func configureDeviceInputs() throws {
      guard let captureSession = self._captureSession else { throw ControllerError.captureSessionIsMissing }
      
      if let rearCamera = self.rearCamera {
        self.rearCameraInput = try AVCaptureDeviceInput(device: rearCamera)
        
        if captureSession.canAddInput(self.rearCameraInput!) { captureSession.addInput(self.rearCameraInput!) }
        
        self.currentCameraPosition = .rear
      }
      else if let frontCamera = self.frontCamera {
        self.frontCameraInput = try AVCaptureDeviceInput(device: frontCamera)
        
        if captureSession.canAddInput(self.frontCameraInput!) { captureSession.addInput(self.frontCameraInput!) }
        else { throw ControllerError.inputsAreInvalid }
        
        self.currentCameraPosition = .front
      }
      else { throw ControllerError.noCamerasAvailable }
    }
    
    // 設定輸出 拍照
    func configurePhotoOutput() throws {
      guard let captureSession = self._captureSession else { throw ControllerError.captureSessionIsMissing }
      
      self.photoOutput = AVCapturePhotoOutput()
      self.photoOutput!.setPreparedPhotoSettingsArray([AVCapturePhotoSettings(format: [AVVideoCodecKey : AVVideoCodecType.jpeg])], completionHandler: nil)
      
      if captureSession.canAddOutput(self.photoOutput!) { captureSession.addOutput(self.photoOutput!) }
    }
    
    // 設定輸出 掃描Qrcode
    func configureMetadataOutput() throws {
      guard let captureSession = self._captureSession else { throw ControllerError.captureSessionIsMissing }
      
      self.metadataOutput = AVCaptureMetadataOutput()
      
      // 必須先將metadataOutput 加入到session,才能設置metadataObjectTypes,注意順序,不然會crash
      if captureSession.canAddOutput(self.metadataOutput!) { captureSession.addOutput(self.metadataOutput!) }
      self.metadataOutput?.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
      self.metadataOutput?.metadataObjectTypes = [ .qr, .code128, .code39 ]
    }
    
    func configurePreview() throws {
      guard let captureSession = self._captureSession else { throw ControllerError.captureSessionIsMissing }
      
      self.previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
      self.previewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
      self.previewLayer?.connection?.videoOrientation = .portrait
      captureSession.startRunning()
    }
    
    DispatchQueue(label: "prepare").async {
      do {
        createCaptureSession()
        try configureCaptureDevices()
        try configureDeviceInputs()
        try configurePhotoOutput()
        try configureMetadataOutput()
        try configurePreview()
      }
      
      catch {
        DispatchQueue.main.async {
          completionHandler(error)
        }
        return
      }
      DispatchQueue.main.async {
        completionHandler(nil)
      }
    }
  }
}

public extension CameraHelper {
  
  // 變動手電筒模式
  func switchTorch(_ toOpen: Bool){
    self.torchMode = toOpen ? .on : .off
    self.setTorch()
  }
  
  func setTorch() {
    
    guard let device = AVCaptureDevice.default(for: .video) else {
      print("無法獲取到您的設備")
      return
    }
    
    if device.hasTorch && device.isTorchAvailable{
      
      do {
        try device.lockForConfiguration()
        
        if (self.torchMode == .on) {
          try device.setTorchModeOn(level: 1.0)
        } else {
          device.torchMode = AVCaptureDevice.TorchMode.off
        }
        
        device.unlockForConfiguration()
      } catch {
        print(error)
      }
    }
  }
}

/**
 拍照
 */
extension CameraHelper: AVCapturePhotoCaptureDelegate {
  
  // 拍照
  public func captureImage() {
    
    guard let captureSession = _captureSession, captureSession.isRunning else {
      self.delegate?.captureError(error: ControllerError.captureSessionIsMissing)
      return
    }
    
    self.photoOutput?.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
  }
  
  public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
    
    if let error = error {
      self.delegate?.captureError(error: error)
    } else if let imageData = photo.fileDataRepresentation(), let image = UIImage(data: imageData) {
      self.delegate?.onCaptureImage(image: image)
    } else {
      self.delegate?.captureError(error: ControllerError.unknown)
    }
  }
  
  // 切換閃光燈
  public func switchFlash() throws {
    
    guard let currentCameraPosition = currentCameraPosition, let captureSession = self._captureSession, captureSession.isRunning, let rearCamera = rearCamera
    else { throw ControllerError.captureSessionIsMissing }
    
    if (currentCameraPosition == .rear && rearCamera.hasTorch) {
      
      do {
        try rearCamera.lockForConfiguration()
      } catch {
        
      }
      
      if rearCamera.isTorchActive {
        rearCamera.torchMode = AVCaptureDevice.TorchMode.off
      } else {
        rearCamera.torchMode = AVCaptureDevice.TorchMode.on
      }
      
      rearCamera.unlockForConfiguration()
    }
  }
  
  // 切換相機
  public func switchCameras() throws {
    
    guard let currentCameraPosition = currentCameraPosition, let captureSession = self._captureSession, captureSession.isRunning
    else { throw ControllerError.captureSessionIsMissing }
    
    captureSession.beginConfiguration()
    
    switch currentCameraPosition {
    case .front:
      try switchToRearCamera()
      
    case .rear:
      try switchToFrontCamera()
    }
    
    captureSession.commitConfiguration()
  }
  
  private func switchToFrontCamera() throws {
    
    guard let captureSession = self._captureSession, captureSession.isRunning
    else { throw ControllerError.captureSessionIsMissing }
    
    guard let rearCameraInput = self.rearCameraInput, captureSession.inputs.contains(rearCameraInput), let frontCamera = self.frontCamera
    else { throw ControllerError.invalidOperation }
    
    self.frontCameraInput = try AVCaptureDeviceInput(device: frontCamera)
    
    captureSession.removeInput(rearCameraInput)
    
    if captureSession.canAddInput(self.frontCameraInput!) {
      captureSession.addInput(self.frontCameraInput!)
      
      self.currentCameraPosition = .front
    }
    else {
      throw ControllerError.invalidOperation
    }
  }
  
  private func switchToRearCamera() throws {
    
    guard let captureSession = self._captureSession, captureSession.isRunning
    else { throw ControllerError.captureSessionIsMissing }
    
    guard let frontCameraInput = self.frontCameraInput, captureSession.inputs.contains(frontCameraInput),
          let rearCamera = self.rearCamera else { throw ControllerError.invalidOperation }
    
    self.rearCameraInput = try AVCaptureDeviceInput(device: rearCamera)
    
    captureSession.removeInput(frontCameraInput)
    
    if captureSession.canAddInput(self.rearCameraInput!) {
      captureSession.addInput(self.rearCameraInput!)
      self.currentCameraPosition = .rear
    }
    else { throw ControllerError.invalidOperation }
  }
}

/**
 掃描
 */
extension CameraHelper: AVCaptureMetadataOutputObjectsDelegate {
  
  public func startScan() -> Bool{
    if let session = self._captureSession, session.isRunning == false {
      session.startRunning()
      return true
    }
    return false
  }
  
  public func stopScan() {
    if let session = self._captureSession, session.isRunning == true {
      session.stopRunning()
    }
  }
  
  public func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
    
    // 如果 metadataObjects 是空陣列
    if metadataObjects.isEmpty {
      print("Qrcode空資訊")
      return
    }
    
    // 如果能夠取得 metadataObjects 並且能夠轉換成 AVMetadataMachineReadableCodeObject（條碼訊息）
    guard let readableCode = metadataObjects.first as? AVMetadataMachineReadableCodeObject, let code = readableCode.stringValue else { return }
    
    //    if let barcodeObject = previewLayer?.transformedMetadataObject(for: readableCode) {
    //      print("條碼座標:\(barcodeObject.bounds)")
    //      let isInside = CGRect(x: 38, y: 176, width: 300, height: 300).contains(barcodeObject.bounds)
    //    }
    
    //    _ = self.stopScan() // 停止掃描
    
    //掃到後的震動提示
    AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
    
    switch readableCode.type {
    case .qr: // 判斷 metadataObj 的類型是否為 QR Code
      self.delegate?.qrcodeCapture(value: code)
    case .code128: // 身分證
      self.delegate?.code128Capture(value: code)
    case .code39: // 居留證
      self.delegate?.code39Capture(value: code)
    default:
      break
    }
  }
}

public extension CameraHelper {
  
  enum ControllerError: Swift.Error {
    case captureSessionAlreadyRunning
    case captureSessionIsMissing
    case inputsAreInvalid
    case invalidOperation
    case noCamerasAvailable
    case unknown
  }
  
  enum CameraPosition {
    case front
    case rear
  }
}
