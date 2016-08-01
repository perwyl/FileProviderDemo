//
//  WebDAVDetailVC.swift
//  fileProviderDemo
//
//  Created by perwyl on 28/7/16.
//  Copyright © 2016 perwyl. All rights reserved.
//

import UIKit
import FileProvider


class WebDAVDetailVC: UIViewController , FileProviderDelegate{
    
    
    @IBOutlet weak var imgView: UIImageView!
    
    var fileObject: FileObject!
    
    var username:String!
    var password:String!
    var path:String!
    var ipAddress:String!
    var folderPath:String!
    
    var fileProvider: WebDAVFileProvider!
    
    var img:UIImage?
    
    @IBOutlet weak var lblMsg: UILabel!
    @IBOutlet weak var txtView: UITextView!
    
    
    override func viewDidLoad() {
        
        
        #if PERWYL
            username = "algoaccess"
            password = "algoaccess123"
            ipAddress = "192.168.1.102"
            folderPath = "dav"
        #endif
        
        path = ("http://\(ipAddress)")
        
       
        
        setupWebDAV()
        

        
        getFileObject()
        
        
        
    }
    
    func fileproviderSucceed(fileProvider: FileProviderOperations, operation: FileOperation){
        
        switch operation {
        case .Copy(source: let source, destination: let dest):
            NSLog("\(source) copied to \(dest).")
        case .Remove(path: let path):
            NSLog("\(path) has been deleted.")
        default:
            break
        }
        
    }
    func fileproviderFailed(fileProvider: FileProviderOperations, operation: FileOperation){
        
        switch operation {
        case .Copy(source: let source, destination: let dest):
            NSLog("copy of \(source) failed.")
        case .Remove(path: let path):
            NSLog("\(path) can't be deleted.")
        default:
            break
        }
        
    }
    func fileproviderProgress(fileProvider: FileProviderOperations, operation: FileOperation, progress: Float){
        
        
        switch operation {
        case .Copy(source: let source, destination: let dest):
            NSLog("Copy\(source) to \(dest): \(progress * 100) completed.")
        default:
            break
        }
    }

    
    
    
    func setupWebDAV(){
        
        let credential = NSURLCredential(user: username, password: password, persistence: NSURLCredentialPersistence.Permanent)
        fileProvider = WebDAVFileProvider(baseURL: NSURL(string: path)!, credential: credential)
         fileProvider.delegate = self
        
        
    }
    
    func getTempFileObject(){
        
        let tempPath = ("\(folderPath)/hello2.txt")
        fileProvider.contentsAtPath(tempPath) { (contents, error) in
            if let img = UIImage(data: contents!){
                print("Img Recv : \(img.size.height)")
            }
        }
    }
    
    
    func getFileObject(){
        
        var tempPath:String!
        
        if fileObject == nil {
            tempPath = ("\(folderPath)/hello2.txt")
        }else {
            tempPath = fileObject.path
        }
        
        print("path: \(tempPath)")
        
        
        fileProvider.contentsAtPath(tempPath) { (contents, error) in
            
            
            
            dispatch_async(dispatch_get_main_queue(),{
                if (error != nil) {
                    
                    self.txtView.text = error.debugDescription
                    
                }else {
                    
                    if let img = UIImage(data: contents!){
                        
                        self.lblMsg.text = "Image File"
                        self.imgView.image = img
                    }else {
                        
                        self.lblMsg.text = "Not Image File"
                        
                        let datastring = String(data: contents!, encoding: NSUTF8StringEncoding)
                        
                        self.txtView.text = datastring
                    }
                    
                }
                
            })
        }
        
        
    }
    
}
