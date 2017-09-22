//
//  FacialAnalysisViewController.swift
//  DnA
//
//  Created by Kyoungwon Jo on 2017. 9. 21..
//  Copyright © 2017년 Kyoungwon Jo. All rights reserved.
//

import UIKit
import Vision
import AVFoundation

class FacialAnalysisViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
  let emotionsDic = [
    "Sad" : "슬픔",
    "Fear" : "두려움",
    "Happy" : "기쁨",
    "Angry" : "화남",
    "Neutral" : "보통",
    "Surprise" : "놀람",
    "Disgust" : "역겨움"
  ]
  
  let genderDic = [
    "Male" : "남성",
    "Female" : "여성"
  ]
  
  
  @IBOutlet weak var defaultMessageLabel: UILabel!
  @IBOutlet weak var facesScrollView: UIScrollView!
  @IBOutlet weak var selectedImageView: UIImageView!
  @IBOutlet weak var blurredImageView: UIImageView!
  
  @IBOutlet weak var genderLabel: UILabel!
  @IBOutlet weak var genderIdentifierLabel: UILabel!
  @IBOutlet weak var genderConfidenceLabel: UILabel!
  
  @IBOutlet weak var ageLabel: UILabel!
  @IBOutlet weak var ageIdentifierLabel: UILabel!
  @IBOutlet weak var ageConfidenceLabel: UILabel!
  
  @IBOutlet weak var emotionLabel: UILabel!
  @IBOutlet weak var emotionIdentifierLabel: UILabel!
  @IBOutlet weak var emotionConfidenceLabel: UILabel!
  
  var selectedImage: UIImage? {
    didSet {
      self.blurredImageView.image = selectedImage
      self.selectedImageView.image = selectedImage
    }
  }
  
  var selectedciImage: CIImage? {
    get {
      if let selectedImage = self.selectedImage {
        return CIImage(image: selectedImage)
      } else {
        return nil
      }
    }
  }
  
  var selectedFace: UIImage? {
    didSet {
      if let selectedFace = self.selectedFace {
        DispatchQueue.global(qos: .userInitiated).async {
          self.performFaceAnalysis(on: selectedFace)
        }
        
      }
    }
  }
  var faceImageViews = [UIImageView]()
  var requests = [VNRequest]()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    do {
      let genderModel = try VNCoreMLModel(for: GenderNet().model)
      self.requests.append(VNCoreMLRequest(model: genderModel, completionHandler: handleGenderClassification))
      
      let ageModel = try VNCoreMLModel(for: AgeNet().model)
      self.requests.append(VNCoreMLRequest(model: ageModel, completionHandler: handleAgeClassification))
      
      let emotionModel = try VNCoreMLModel(for: CNNEmotions().model)
      self.requests.append(VNCoreMLRequest(model: emotionModel, completionHandler: handleEmotionClassification))
      
    } catch {
      print(error)
    }
    
    self.hideAllLabels()
    self.defaultMessageLabel.text = "+ 버튼을 눌러 사진을 고르세요."
  }
  
  @IBAction func addPhoto(_ sender: UIBarButtonItem) {
    let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
    
    let importFromAlbum = UIAlertAction(title: "앨범에서 가져오기", style: .default) { _ in
      let picker = UIImagePickerController()
      picker.delegate = self
      picker.sourceType = .savedPhotosAlbum
      picker.allowsEditing = true
      self.present(picker, animated: true, completion: nil)
    }
    
    let takePhoto = UIAlertAction(title: "카메라로 찍기", style: .default) { _ in
      let picker = UIImagePickerController()
      picker.delegate = self
      picker.sourceType = .camera
      picker.cameraCaptureMode = .photo
      picker.allowsEditing = true
      self.present(picker, animated: true, completion: nil)
    }
    
    let cancel = UIAlertAction(title: "취소", style: .cancel)
    
    actionSheet.addAction(importFromAlbum)
    actionSheet.addAction(takePhoto)
    actionSheet.addAction(cancel)
    
    self.present(actionSheet, animated: true, completion: nil)
  }
  
  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
    picker.dismiss(animated: true, completion: nil)
    
    if let uiImage = info[UIImagePickerControllerEditedImage] as? UIImage {
      self.selectedImage = uiImage
      self.removeRectangle()
      self.removeFaceImageViews()
      
      self.hideAllLabels()
      
      self.defaultMessageLabel.text = ""
      
      DispatchQueue.global(qos: .userInitiated).async {
        self.detectFaces()
      }
    }
  }
  
  func detectFaces() {
    if let ciImage = self.selectedciImage {
      let detectFaceRequest = VNDetectFaceRectanglesRequest(completionHandler: self.handleFaces)
      let requestHandler = VNImageRequestHandler(ciImage: ciImage, options: [:])

      do {
        try requestHandler.perform([detectFaceRequest])
      } catch {
        print (error)
      }
      
    }
  }
  
  func handleFaces(request: VNRequest, error: Error?) {
    if let faces = request.results as? [VNFaceObservation] {
      DispatchQueue.main.async {
        self.displayUI(for: faces)
      }
    }
  }
  
  func displayUI(for faces: [VNFaceObservation]) {
    if let faceImage = self.selectedImage {
      let imageRect = AVMakeRect(aspectRatio: faceImage.size, insideRect: self.selectedImageView.bounds)
      
      for (index, face) in faces.enumerated() {
        // make rect each face
        let w = face.boundingBox.size.width * imageRect.width
        let h = face.boundingBox.size.height * imageRect.height
        let x = face.boundingBox.origin.x * imageRect.width
        let y = imageRect.maxY - (face.boundingBox.origin.y * imageRect.height) - h
        
        let layer = CAShapeLayer()
        layer.frame = CGRect(x: x, y: y, width: w, height: h)
        layer.borderColor = UIColor.red.cgColor
        layer.borderWidth = 1
        self.selectedImageView.layer.addSublayer(layer)
        
        // slice face image from each rect
        let w2 = face.boundingBox.size.width * faceImage.size.width
        let h2 = face.boundingBox.size.height * faceImage.size.height
        let x2 = face.boundingBox.origin.x * faceImage.size.width
        let y2 = (1 - face.boundingBox.origin.y) * faceImage.size.height - h2
        let cropRect = CGRect(x: x2 * faceImage.scale, y: y2 * faceImage.scale, width: w2 * faceImage.scale, height: h2 * faceImage.scale)
        
        if let faceCgImage = faceImage.cgImage?.cropping(to: cropRect) {
          let faceUiImage = UIImage(cgImage: faceCgImage, scale: faceImage.scale, orientation: .up)
          let faceImageView = UIImageView(frame: CGRect(x: 90 * index, y: 0, width: 80, height: 80))
          faceImageView.image = faceUiImage
          faceImageView.isUserInteractionEnabled = true
          
          let tap = UITapGestureRecognizer(target: self, action:
            #selector(FacialAnalysisViewController.handleFaceImageViewTap(_:)))
          faceImageView.addGestureRecognizer(tap)
          
          self.faceImageViews.append(faceImageView)
          self.facesScrollView.addSubview(faceImageView)
        }
      }
      
      self.facesScrollView.contentSize = CGSize(width: 90 * faces.count - 10, height: 80)
    }
  }
  
  func removeRectangle() {
    if let sublayers = self.selectedImageView.layer.sublayers {
      for layer in sublayers {
        layer.removeFromSuperlayer()
      }
    }
  }
  
  func removeFaceImageViews() {
    for faceImageView in self.faceImageViews {
      faceImageView.removeFromSuperview()
    }
    
    self.faceImageViews.removeAll()
  }
  
  @objc func handleFaceImageViewTap (_ sender: UITapGestureRecognizer) {
    if let tappedImageView = sender.view as? UIImageView {
      
      // clear every borders
      for faceImageView in self.faceImageViews {
        faceImageView.layer.borderWidth = 0
        faceImageView.layer.borderColor = UIColor.clear.cgColor
      }
      
      tappedImageView.layer.borderWidth = 3
      tappedImageView.layer.borderColor = UIColor.blue.cgColor
      
      self.selectedFace = tappedImageView.image
      
      DispatchQueue.main.async {
        self.genderIdentifierLabel.text = "계산중."
        self.ageIdentifierLabel.text = "계산중."
        self.emotionIdentifierLabel.text = "계산중."
        
        self.genderConfidenceLabel.text = "계산중."
        self.ageConfidenceLabel.text = "계산중."
        self.emotionConfidenceLabel.text = "계산중."
      }
      self.showAllLabels()
    }
  }
  
  func performFaceAnalysis(on image: UIImage) {
    do {
      for request in self.requests {
        let handler = VNImageRequestHandler(cgImage: image.cgImage!, options: [:])
        try handler.perform([request])
      }
    } catch {
      print(error)
    }
    
  }
  
  func handleGenderClassification(request: VNRequest, error: Error?) {
    if let genderObservation = request.results?.first as? VNClassificationObservation {
      DispatchQueue.main.async {
        self.genderIdentifierLabel.text = self.genderDic[genderObservation.identifier]
        self.genderConfidenceLabel.text = "\(String(format: "%.1f", genderObservation.confidence * 100))%"
      }
    }
  }
  
  func handleAgeClassification(request: VNRequest, error: Error?) {
    if let ageObservation = request.results?.first as? VNClassificationObservation {
      DispatchQueue.main.async {
        self.ageIdentifierLabel.text = ageObservation.identifier
        self.ageConfidenceLabel.text = "\(String(format: "%.1f", ageObservation.confidence * 100))%"
      }
    }
  }
  
  func handleEmotionClassification(request: VNRequest, error: Error?) {
    
    if let emotionObservation = request.results?.first as? VNClassificationObservation {
      DispatchQueue.main.async {
        self.emotionIdentifierLabel.text = self.emotionsDic[emotionObservation.identifier]!
        self.emotionConfidenceLabel.text = "\(String(format: "%.1f", emotionObservation.confidence * 100))%"
      }
    }
  }
  
  func hideGenderLabels() {
    self.genderLabel.isHidden = true
    self.genderIdentifierLabel.isHidden = true
    self.genderConfidenceLabel.isHidden = true
  }
  
  func showGenderLabels() {
    self.genderLabel.isHidden = false
    self.genderIdentifierLabel.isHidden = false
    self.genderConfidenceLabel.isHidden = false
  }

  func hideAgeLabels() {
    self.ageLabel.isHidden = true
    self.ageIdentifierLabel.isHidden = true
    self.ageConfidenceLabel.isHidden = true
  }
  
  func showAgeLabels() {
    self.ageLabel.isHidden = false
    self.ageIdentifierLabel.isHidden = false
    self.ageConfidenceLabel.isHidden = false
  }

  func hideEmotionLabels() {
    self.emotionLabel.isHidden = true
    self.emotionIdentifierLabel.isHidden = true
    self.emotionConfidenceLabel.isHidden = true
  }
  
  func showEmotionLabels() {
    self.emotionLabel.isHidden = false
    self.emotionIdentifierLabel.isHidden = false
    self.emotionConfidenceLabel.isHidden = false
  }
  
  func hideAllLabels() {
    self.hideGenderLabels()
    self.hideAgeLabels()
    self.hideEmotionLabels()
  }
  
  func showAllLabels() {
    self.showGenderLabels()
    self.showAgeLabels()
    self.showEmotionLabels()
  }
}
