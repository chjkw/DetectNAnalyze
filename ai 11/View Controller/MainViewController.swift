//
//  MainViewController.swift
//  ai 11
//
//  Created by Kyoungwon Jo on 2017. 9. 20..
//  Copyright © 2017년 Kyoungwon Jo. All rights reserved.
//

import UIKit

class MainViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

  @IBOutlet weak var tableView: UITableView!
  
  let sampleData = SampleData()
  
  override func viewDidLoad() {
    super.viewDidLoad()
  
    self.tableView.tableFooterView = UIView(frame: .zero)
    self.tableView.dataSource = self
    self.tableView.delegate = self
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    if #available(iOS 11.0, *) {
      self.navigationController?.navigationBar.prefersLargeTitles = true
    } else {
      // Fallback on earlier versions
    }
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    
    if #available(iOS 11.0, *) {
      self.navigationController?.navigationBar.prefersLargeTitles = false
    } else {
      // Fallback on earlier versions
    }
    
  }
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.sampleData.samples.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "mainFeatureCell", for: indexPath) as! MainFeatureCell
    
    let sample = self.sampleData.samples[indexPath.row]
    cell.titleLabel.text = sample.title
    cell.descriptionLabel.text = sample.description
    cell.featureImageView.image = UIImage(named: sample.image)
  
    return cell
  }
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    switch indexPath.row {
    case 0: self.performSegue(withIdentifier: "photoObjectDetection", sender: nil)
    case 1: self.performSegue(withIdentifier: "realTimeObjectDetection", sender: nil)
    case 2: self.performSegue(withIdentifier: "facialAnalysis", sender: nil)
    default:
      return
    }
  }
}
