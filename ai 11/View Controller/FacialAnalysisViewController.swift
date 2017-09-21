//
//  FacialAnalysisViewController.swift
//  ai 11
//
//  Created by Kyoungwon Jo on 2017. 9. 21..
//  Copyright © 2017년 Kyoungwon Jo. All rights reserved.
//

import UIKit

class FacialAnalysisViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
 
  
  @IBOutlet weak var selectedImageView: UIImageView!
  @IBOutlet weak var blurredImageView: UIImageView!
  var selectedImage: UIImage? {
    didSet {
      self.blurredImageView.image = selectedImage
      self.selectedImageView.image = selectedImage
    }
  }
  
  override func viewDidLoad() {
        super.viewDidLoad()

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
    picker.dismiss(animated: true, completion: nil)
    
    if let uiImage = info[UIImagePickerControllerEditedImage] as? UIImage {
      self.selectedImage = uiImage
    }
    
    
  }
}
