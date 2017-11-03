//
//  ViewController.swift
//  DownloadTaskWithNSURLSession
//
//  Created by Malek T. on 11/4/15.
//  Copyright © 2015 Medigarage Studios LTD. All rights reserved.
//

import UIKit

class ViewController: UIViewController, URLSessionDownloadDelegate, UIDocumentInteractionControllerDelegate {
  
  
  @IBOutlet weak var speedLabel: UILabel!
  @IBOutlet weak var progressLabel: UILabel!
  @IBOutlet weak var downloadButton: UIButton!
  var downloadTask: URLSessionDownloadTask!
  var backgroundSession: URLSession!
  var destinationURLForFile: URL?
  var downloadStatus = 0
  var startTime: Date?
  var endTime: Float?
  var speeds = [Float]()
  let url = URL(string: "http://download.blender.org/peach/bigbuckbunny_movies/big_buck_bunny_1080p_h264.mov")!
  var documentDirectoryPath:String!
  var fileManager:FileManager!
  @IBAction func startDownload(_ sender: AnyObject) {
    startTime = Date()
    if downloadStatus == 0 {
      downloadTask = backgroundSession.downloadTask(with: url)
      downloadTask.resume()
      debugPrint("START DOWNLOAD")
      downloadStatus = 1
      downloadButton.setTitle("Pause", for: .normal)
    } else if downloadStatus == 1 {
      pause()
    } else if downloadStatus == 2 {
      resume()
    } else {
      if fileManager.fileExists(atPath: (destinationURLForFile?.path)!){
        showFileWithPath(path: (destinationURLForFile?.path)!)
      }
    }
  }
  
  func pause() {
    if downloadTask != nil{
      downloadTask.suspend()
      debugPrint("PAUSE CLICKED")
      downloadButton.setTitle("Resume", for: .normal)
      downloadStatus = 2
    }
  }
  
  func resume() {
    if downloadTask != nil{
      downloadTask.resume()
      debugPrint("RESUME CLICKED")
      downloadButton.setTitle("Pause", for: .normal)
      downloadStatus = 1
    }
  }
  
  func cancel() {
    if downloadTask != nil{
      downloadTask.cancel()
      debugPrint("CANCEL CLICKED")
    }
  }
  
  @IBOutlet var progressView: UIProgressView!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    let backgroundSessionConfiguration = URLSessionConfiguration.background(withIdentifier: "backgroundSession")
    backgroundSession = Foundation.URLSession(configuration: backgroundSessionConfiguration, delegate: self, delegateQueue: OperationQueue.main)
    progressView.setProgress(0.0, animated: false)
    let path = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
    documentDirectoryPath = path[0]
    fileManager = FileManager()
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  
  func showFileWithPath(path: String){
    let isFileFound:Bool? = FileManager.default.fileExists(atPath: path)
    if isFileFound == true{
      let viewer = UIDocumentInteractionController(url: URL(fileURLWithPath: path))
      viewer.delegate = self
      viewer.presentPreview(animated: true)
    }
  }
  
  //MARK: URLSessionDownloadDelegate
  // 1
  func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {

    destinationURLForFile = URL(fileURLWithPath: documentDirectoryPath.appendingFormat("/big_buck_bunny_1080p_h264.mov"))
    
    guard fileManager.fileExists(atPath: (destinationURLForFile?.path)!) else {
      do {
        try fileManager.moveItem(at: location, to: destinationURLForFile!)
        // show file
//        showFileWithPath(path: (destinationURLForFile?.path)!)
      }catch{
        print("An error occurred while moving file to destination url")
      }
      
      downloadButton.setTitle("Play", for: .normal)
      downloadStatus = 3
      return
    }
  }
  
  // 2
  func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
    endTime = Float(Date().timeIntervalSince(startTime!))
    let speed = (Float(totalBytesWritten)/1000000.0) / endTime!
    speeds.append(speed)
    debugPrint("speed  \(speed) / \(speeds.reduce(0, +)/Float(speeds.count)) MB/S")
    let progress = Float(totalBytesWritten)/Float(totalBytesExpectedToWrite)
    debugPrint("PROGRESS \(progress * 100)")
    progressView.setProgress(progress, animated: true)
    progressLabel.text = String(format: "%.1f%%", progress * 100)
    speedLabel.text = String(format: "%.1f%mb/s", speeds.reduce(0, +)/Float(speeds.count))
  }
  
  //MARK: URLSessionTaskDelegate
  func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?){
    downloadTask = nil
    progressView.setProgress(0.0, animated: true)
    if (error != nil) {
      print(error!.localizedDescription)
    }else{
      print("The task finished transferring data successfully")
      downloadButton.setTitle("Play", for: .normal)
      downloadStatus = 3
    }
  }
  
  //MARK: UIDocumentInteractionControllerDelegate
  func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController
  {
    return self
  }
}

