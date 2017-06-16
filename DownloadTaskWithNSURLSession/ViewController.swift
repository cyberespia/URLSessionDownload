//
//  ViewController.swift
//  DownloadTaskWithNSURLSession
//
//  Created by Malek T. on 11/4/15.
//  Copyright © 2015 Medigarage Studios LTD. All rights reserved.
//

import UIKit

class ViewController: UIViewController, URLSessionDownloadDelegate, UIDocumentInteractionControllerDelegate {

    
    @IBOutlet weak var downloadButton: UIButton!
    var downloadTask: URLSessionDownloadTask!
    var backgroundSession: URLSession!
    var downloadStatus = 0
    let url = URL(string: "http://download.blender.org/peach/bigbuckbunny_movies/big_buck_bunny_1080p_h264.mov")!

    @IBAction func startDownload(_ sender: AnyObject) {
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
    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL){
        
        let path = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        let documentDirectoryPath:String = path[0]
        let fileManager = FileManager()
        let destinationURLForFile = URL(fileURLWithPath: documentDirectoryPath.appendingFormat("/big_buck_bunny_1080p_h264.mov"))
        
        if fileManager.fileExists(atPath: destinationURLForFile.path){
            showFileWithPath(path: destinationURLForFile.path)
        }
        else{
            do {
                try fileManager.moveItem(at: location, to: destinationURLForFile)
                // show file
                showFileWithPath(path: destinationURLForFile.path)
            }catch{
                print("An error occurred while moving file to destination url")
            }
        }
    }
    // 2
    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64,
                    totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64){
        let progress = Float(totalBytesWritten)/Float(totalBytesExpectedToWrite)
        debugPrint("PROGRESS \(progress * 100)")
        progressView.setProgress(progress, animated: true)
    }
    
    //MARK: URLSessionTaskDelegate
    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    didCompleteWithError error: Error?){
        downloadTask = nil
        progressView.setProgress(0.0, animated: true)
        if (error != nil) {
            print(error!.localizedDescription)
        }else{
            print("The task finished transferring data successfully")
            downloadButton.setTitle("Play", for: .normal)
            downloadStatus = 0
        }
    }
    
    //MARK: UIDocumentInteractionControllerDelegate
    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController
    {
        return self
    }
}

