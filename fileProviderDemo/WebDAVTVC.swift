//
//  WebDAVTVC.swift
//  fileProviderDemo
//
//  Created by perwyl on 28/7/16.
//  Copyright © 2016 perwyl. All rights reserved.
//

import Foundation
import UIKit

import FileProvider
import SCLAlertView



class WebDAVTVC: UITableViewController {
    
    var username:String!
    var password:String!
    var path:String!
    var ipAddress:String!
    var folderPath:String!
    
    var fileProvider: FileProvider!
    
    var dirData:[FileObject]!
    
    var tempImg:UIImage!
    
    override func viewDidLoad() {
        
        dirData = [FileObject]()
    }
    
    
    
    func setup(username _name:String?, password _pwd:String?, ipAddress _address:String?, folderPath _fPath:String?){
        
        username = _name
        password = _pwd
        ipAddress = _address
        folderPath = _fPath
        
        #if PERWYL
            username = "algoaccess"
            password = "algoaccess123"
            ipAddress = "192.168.1.102" //"192.168.1.102"
            folderPath = "dav" //"dav"
        #endif
        
        path = ("http://\(ipAddress)")
        
    }
    
    func setupWebDAV(){
        
        let credential = NSURLCredential(user: username, password: password, persistence: NSURLCredentialPersistence.Permanent)
        fileProvider = WebDAVFileProvider(baseURL: NSURL(string: path)!, credential: credential) as! FileProvider
  
    }
    
    @IBAction func btnConnectSelected(sender: AnyObject) {
        
        setupWebDAV()
        
        getDirData()

    }
    

    


    func getDirData(){
        
        fileProvider.contentsOfDirectoryAtPath("/\(folderPath)") { (contents, error) in
            
            if error != nil {
                
                debugPrint(error.debugDescription)
            }else {
                
                for item in contents {
                    
                    print(item.name)
                }
                
                self.dirData = contents
                
                self.tableView.reloadData()
            }
            
   
        }
    }
    
}

extension WebDAVTVC {
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return dirData.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = UITableViewCell()
        
        cell.textLabel?.text = dirData[indexPath.row].name
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        
    }
    
}