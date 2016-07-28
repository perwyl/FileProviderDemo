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
    
    var username:String!
    var password:String!
    var path:String!
    
    override func viewDidLoad() {
        
    }
    
    
    
    func setupWebDAV(username _name:String?, password _pwd:String?, path _path:String?){
        
        username = _name
        password = _pwd
        path = _path
        
    }
    
}