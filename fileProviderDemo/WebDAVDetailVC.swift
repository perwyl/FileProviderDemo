//
//  WebDAVDetailVC.swift
//  fileProviderDemo
//
//  Created by perwyl on 28/7/16.
//  Copyright © 2016 perwyl. All rights reserved.
//

import UIKit
import FileProvider


class WebDAVDetailVC: UIViewController {
    
    
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
            username = "temp"
            password = "temp"
            ipAddress = "192.168.1.127"
            folderPath = "MockShare"
        #endif
        
        path = ("http://\(ipAddress)/\(folderPath)")
        
        setupWebDAV()
        
        sleep(10)
        
        getTempFileObject()
        
        
    }
    
    
    func setupWebDAV(){
        
        let credential = NSURLCredential(user: username, password: password, persistence: NSURLCredentialPersistence.Permanent)
        fileProvider = WebDAVFileProvider(baseURL: NSURL(string: path)!, credential: credential)
        
        
        
    }
    
    func getTempFileObject(){
        
        let tempPath = ("\(path)/temp.jpg")
        fileProvider.contentsAtPath(tempPath) { (contents, error) in
            if let img = UIImage(data: contents!){
                print("Img Recv : \(img.size.height)")
            }
        }
    }
    
    
    func getFileObject(){
        
        var tempPath:String!
        
        if fileObject == nil {
            tempPath = ("\(path)/temp.jpg")
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
                    }
                    
                    self.txtView.text = contents.debugDescription
                }
                
            })
        }
        
        
    }
    
    
    
}