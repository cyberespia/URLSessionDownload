//
//  ViewController.swift
//  DownloadTaskWithNSURLSession
//
//  Created by Malek T. on 11/4/15.
//  Copyright © 2016 Skander Jabouzi. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIDocumentInteractionControllerDelegate, DownloaderObserver {
  
  @IBOutlet weak var speedLabel: UILabel!
  @IBOutlet weak var progressLabel: UILabel!
  @IBOutlet weak var downloadButton: UIButton!
  
  var downloader = Downloader.sharedInstance
  
  @IBAction func startDownload(_ sender: AnyObject) {
    downloader.startDownload()
  }
  
  @IBOutlet var progressView: UIProgressView!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    downloader.setObserver(observer: self)
    downloader.initDownlaod()
  }
  
  func showFileWithPath(path: String){
    let isFileFound:Bool? = FileManager.default.fileExists(atPath: path)
    if isFileFound == true{
      let viewer = UIDocumentInteractionController(url: URL(fileURLWithPath: path))
      viewer.delegate = self
      viewer.presentPreview(animated: true)
    }
  }
 
  //MARK: UIDocumentInteractionControllerDelegate
  func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController
  {
    return self
  }
  
  //MARK: DownlaodObserver
  func downloader(_ downloader: Downloader, didUpdateText text: String) {
    downloadButton.setTitle(text, for: .normal)
  }
  
  func downloader(_ downloader: Downloader, didUpdateProgress value: Float) {
      progressView.setProgress(value, animated: true)
      progressLabel.text = String(format: "%.0f%%", value * 100)
  }
  
  func downloader(_ downloader: Downloader, didUpdateSpeed value: Float) {
    speedLabel.text = String(format: "%.0f MB/S", value)
  }
  
  func downloader(_ downloader: Downloader, didUpdateState state: DownladState) {
    print(state);
  }
  
  func downloader(_ downloader: Downloader, didShowFile file: String) {
    showFileWithPath(path: file)
  }
}

