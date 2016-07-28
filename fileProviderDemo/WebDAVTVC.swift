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

class WebDAVTVC: UITableViewController {
    
    var username:String!
    var password:String!
    var path:String!
    
    var webdavProvider:WebDAVFileProvider!
    
    override func viewDidLoad() {
        
    }
    
    
    
    func setup(username _name:String?, password _pwd:String?, path _path:String?){
        
        username = _name
        password = _pwd
        path = _path
        
    }
    
    func setupWebDAV(){
        
        let credential = NSURLCredential(user: username, password: password, persistence: NSURLCredentialPersistence.Permanent)
        webdavProvider = WebDAVFileProvider(baseURL: NSURL(string: path), credential: credential)
    }
    
}

extension WebDAVTVC {
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return 10
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        return UITableViewCell()
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        
    }
    
}