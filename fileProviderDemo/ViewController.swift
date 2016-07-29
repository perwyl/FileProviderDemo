//
//  ViewController.swift
//  fileProviderDemo
//
//  Created by perwyl on 28/7/16.
//  Copyright © 2016 perwyl. All rights reserved.
//

import UIKit
import SCLAlertView


enum SegueIdentifier: String {
    
    case SegueToLocalList = "segueToLocalList"
    case SegueToWebDAVList = "segueToWebDAVList"
    case SegueToLocalDetail = "segueToLocalDetail"
    case SegueToWebDAVDetail = "segueToWebDAVDetail"
}

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    


}


extension ViewController {
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        switch segue.identifier! {
            
        case SegueIdentifier.SegueToWebDAVList.rawValue:
            
            let alert = SCLAlertView()
            let username = alert.addTextField("username")
            let password = alert.addTextField("password")
            let ipAddr = alert.addTextField("IP Address")
            let folderPath = alert.addTextField("Folder Path")
            
            alert.showEdit("WebDAV Settings", subTitle: "Enter your WebDAV Settings")
            
            let vc = segue.destinationViewController as! WebDAVTVC
            vc.setup(username: username.text, password: password.text, ipAddress: ipAddr.text, folderPath: folderPath.text)
            
        case SegueIdentifier.SegueToWebDAVDetail.rawValue:
 
            
            let vc = segue.destinationViewController as! WebDAVDetailVC

            
            
        case SegueIdentifier.SegueToLocalList.rawValue:
            
            break
            
        default:
            break
        }
    }


    
  }
