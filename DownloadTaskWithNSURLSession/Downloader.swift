//
//  Downloader.swift
//  DownloadTaskWithNSURLSession
//
//  Created by dev on 11/8/17.
//  Copyright © 2016 Skander Jabouzi. All rights reserved.
//

import Foundation

struct DownloadableItem{
  var name: String = ""
  var id: Int = 0
}

struct DownloadItemTask{
  var item: DownloadableItem!
  var state: DownladState
}

enum DownladState {
  case queued
  case downloading
  case pauded
  case finished
  case deleted
  case failed
}

protocol DownloaderObserver: class {
  func downloader(_ downloader: Downloader, didUpdateText text: String)
  func downloader(_ downloader: Downloader, didUpdateProgress value: Float)
  func downloader(_ downloader: Downloader, didUpdateSpeed value: Float)
  func downloader(_ downloader: Downloader, didUpdateState state: DownladState)
  func downloader(_ downloader: Downloader, didShowFile file: String)
}

class Downloader: NSObject, URLSessionDownloadDelegate {
  
  static let sharedInstance = Downloader()
  
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
  let defaults = UserDefaults.standard
  var partialData: Data?
  var speed: Int?
  var progress: Int?
  
  weak var observer: DownloaderObserver?
  
  private override init() {
    super.init()
  }
  
  func setObserver(observer: DownloaderObserver?) {
    self.observer = observer
  }

  func initDownlaod() {
    let backgroundSessionConfiguration = URLSessionConfiguration.background(withIdentifier: "backgroundSession")
    backgroundSessionConfiguration.isDiscretionary = true
    backgroundSession = Foundation.URLSession(configuration: backgroundSessionConfiguration, delegate: self, delegateQueue: OperationQueue.main)
    observer?.downloader(self, didUpdateProgress: 0.0)
    let path = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
    documentDirectoryPath = path[0]
    fileManager = FileManager()
    partialData = defaults.object(forKey: "resumeData") as? Data
    debugPrint("partialData \(partialData)")
  }
  
  deinit {
    debugPrint("deinit")
    save()
  }
  
  func startDownload() {
    startTime = Date()
    if downloadStatus == 0 {
      if (partialData != nil) {
        downloadTask = self.backgroundSession.downloadTask(withResumeData: partialData!)
        observer?.downloader(self, didUpdateText: "Resume")
        downloadStatus = 2
      } else {
        downloadTask = backgroundSession.downloadTask(with: url)
      }
      downloadTask.resume()
      debugPrint("START DOWNLOAD")
      downloadStatus = 1
      observer?.downloader(self, didUpdateText: "Pause")
//      downloadButton.setTitle("Pause", for: .normal)
    } else if downloadStatus == 1 {
      pause()
    } else if downloadStatus == 2 {
      resume()
    } else {
      if fileManager.fileExists(atPath: (destinationURLForFile?.path)!){
        observer?.downloader(self, didShowFile: (destinationURLForFile?.path)!)
//        showFileWithPath(path: (destinationURLForFile?.path)!)
      }
    }
  }
  
  func pause() {
    debugPrint("downloadTask \(downloadTask)")
    if downloadTask != nil{
      downloadTask.suspend()
      debugPrint("PAUSE CLICKED")
      observer?.downloader(self, didUpdateText: "Resume")
//      downloadButton.setTitle("Resume", for: .normal)
      downloadStatus = 2
    }
  }
  
  func resume() {
    
    if (partialData != nil) {
      backgroundSession.downloadTask(withResumeData: partialData!)
      partialData = nil
    } else if downloadTask != nil{
      downloadTask.resume()
      debugPrint("RESUME CLICKED")
      observer?.downloader(self, didUpdateText: "Pause")
//      downloadButton.setTitle("Pause", for: .normal)
      downloadStatus = 1
    }
  }
  
  func cancel() {
    if downloadTask != nil{
      downloadTask.cancel()
      debugPrint("CANCEL CLICKED")
    }
  }
  
  func save() {
    //    var tempTask = self.downloadTask
    //    debugPrint("tempTask.downloadTask \(tempTask!)")
    //    if (tempTask === downloadTask) {
    //      debugPrint("OK")
    //    }
    //    else {
    //      debugPrint("NO")
    //    }
    debugPrint("save")
    self.downloadTask?.cancel(byProducingResumeData: {(resumeData) in
      self.defaults.set(resumeData, forKey: "resumeData")
      //      self.downloadTask = self.backgroundSession.downloadTask(withResumeData: resumeData!)
      //      self.downloadTask.resume()
      //      tempTask = nil
      //      self.downloadTask = [inProcessSession downloadTaskWithResumeData:resumeData];
    })
  }
  
//  func showFileWithPath(path: String){
//    let isFileFound:Bool? = FileManager.default.fileExists(atPath: path)
//    if isFileFound == true{
//      let viewer = UIDocumentInteractionController(url: URL(fileURLWithPath: path))
//      viewer.delegate = self
//      viewer.presentPreview(animated: true)
//    }
//  }
  
  //MARK: URLSessionDownloadDelegate
  // 1
  func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
    
    destinationURLForFile = URL(fileURLWithPath: documentDirectoryPath.appendingFormat("/big_buck_bunny_1080p_h264.mov"))
    
    guard fileManager.fileExists(atPath: (destinationURLForFile?.path)!) else {
      do {
        try fileManager.moveItem(at: location, to: destinationURLForFile!)
        observer?.downloader(self, didShowFile: (destinationURLForFile?.path)!)
        // show file
        //        showFileWithPath(path: (destinationURLForFile?.path)!)
      }catch{
        print("An error occurred while moving file to destination url")
      }
      observer?.downloader(self, didUpdateText: "Play")
//      downloadButton.setTitle("Play", for: .normal)
      downloadStatus = 3
      return
    }
  }
  
  // 2
  func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
//    debugPrint("downloadTask.taskIdentifier \(downloadTask.taskIdentifier)")
    endTime = Float(Date().timeIntervalSince(startTime!))
    let speed = (Float(bytesWritten)/1000000.0) / endTime!
    speeds.append(speed)
//    debugPrint("speed  \(speed) / \(speeds.reduce(0, +)/Float(speeds.count)) MB/S")
    let progress = Float(totalBytesWritten)/Float(totalBytesExpectedToWrite)
//    debugPrint("PROGRESS \(progress * 100)")
    observer?.downloader(self, didUpdateProgress: progress)
    observer?.downloader(self, didUpdateSpeed: speeds.reduce(0, +)/Float(speeds.count))
    startTime = Date()
//    progressView.setProgress(progress, animated: true)
//    progressLabel.text = String(format: "%.1f%%", progress * 100)
//    speedLabel.text = String(format: "%.1f%mb/s", speeds.reduce(0, +)/Float(speeds.count))
    //    save()
  }
  
  //MARK: URLSessionTaskDelegate
  func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?){
    downloadTask = nil
    observer?.downloader(self, didUpdateProgress: 0.0)
//    progressView.setProgress(0.0, animated: true)
    if (error != nil) {
      print(error!.localizedDescription)
    }else{
      print("The task finished transferring data successfully")
      observer?.downloader(self, didUpdateText: "Play")
//      downloadButton.setTitle("Play", for: .normal)
      downloadStatus = 3
    }
  }
  
//  //MARK: UIDocumentInteractionControllerDelegate
//  func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController
//  {
//    return self
//  }
  
  
}
