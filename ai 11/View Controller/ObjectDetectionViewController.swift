//
//  ObjectDetectionViewController.swift
//  ai 11
//
//  Created by Kyoungwon Jo on 2017. 9. 20..
//  Copyright © 2017년 Kyoungwon Jo. All rights reserved.
//

import UIKit
import Vision

class ObjectDetectionViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
  
  @IBOutlet weak var selectedImageView: UIImageView!
  @IBOutlet weak var categoryLabel: UILabel!
  @IBOutlet weak var confidenceLabel: UILabel!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
  
  @IBOutlet weak var defaultMessageLabel: UILabel!
  var selectedImage: UIImage? {
    didSet {
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

  
  override func viewDidLoad() {
    super.viewDidLoad()
   
    self.activityIndicatorView.hidesWhenStopped = true
    self.activityIndicatorView.stopAnimating()
    self.categoryLabel.text = ""
    self.confidenceLabel.text = ""
    self.defaultMessageLabel.text = "+ 버튼을 눌러 사진을 고르세요."
    
    // Do any additional setup after loading the view.
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
    picker.dismiss(animated: true)
    if let uiImage = info[UIImagePickerControllerEditedImage] as? UIImage {
      self.selectedImage = uiImage
      
      self.categoryLabel.text = ""
      self.confidenceLabel.text = ""
      self.defaultMessageLabel.text = ""
      DispatchQueue.global(qos: .userInitiated).async {
        if #available(iOS 11.0, *) {
          self.activityIndicatorView.startAnimating()
          self.detectObject()
        } else {
          self.confidenceLabel.text = "iOS 11 이하에서는 지원하지 않는 기능입니다."
        }
      }
    }
  }
  
  @available(iOS 11.0, *)
  func detectObject() {
    if let ciImage = self.selectedciImage {
      do {
        let vnCoreMLModel = try VNCoreMLModel(for: Inceptionv3().model)
        let request = VNCoreMLRequest(model: vnCoreMLModel, completionHandler: self.handleObjectDetection)
        request.imageCropAndScaleOption = .centerCrop
        let requsetHandler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        try requsetHandler.perform([request])
      } catch {
        print("here!! : \(error)")
      }
    }
  }
  
  @available(iOS 11.0, *)
  func handleObjectDetection(request: VNRequest, error: Error?) {
    if let result = request.results?.first as? VNClassificationObservation {
      DispatchQueue.main.async {
        self.activityIndicatorView.stopAnimating()
        self.categoryLabel.text = result.identifier
        self.confidenceLabel.text = "\(String(format: "%.1f", result.confidence * 100))%"
      }
    }
  }
  
}
