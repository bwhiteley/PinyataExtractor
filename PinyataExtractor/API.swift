//
//  API.swift
//  PinyataExtractor
//
//  Created by J. B. Whiteley on 7/7/15.
//  Copyright (c) 2015 SwiftBit. All rights reserved.
//

import Foundation


class API {
    
//    let urlSession:NSURLSession = {
//        let conf = NSURLSessionConfiguration.defaultSessionConfiguration()
//        return NSURLSession(configuration: conf)
//    }()
    
    
    
    
    func getObject(urlStr:String, params:[String:String]?) throws -> [String:AnyObject] {
        let urlComps = NSURLComponents(string: urlStr)!
        urlComps.password = "secret"
        urlComps.user = "user@example.com"
        let url = urlComps.URL!

        let request = NSMutableURLRequest(URL: url)
        var response: NSURLResponse?
        let data = try NSURLConnection.sendSynchronousRequest(request, returningResponse: &response)
        let json = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
        return json as! [String:AnyObject]
    }
    
    func downloadImage(urlString urlString:String, toPath path:String) throws {
        let url = NSURL(string:urlString)!
        let request = NSMutableURLRequest(URL: url)
        var response: NSURLResponse?
        let data = try NSURLConnection.sendSynchronousRequest(request, returningResponse: &response)
        let hr = response as! NSHTTPURLResponse
        if hr.statusCode != 200 {
            throw NSError("\(urlString) -> \(hr.statusCode)")
        }
        if data.length == 0 {
            throw NSError("zero length for \(urlString)")
        }
        if data.writeToFile(path, atomically: false) == false {
            throw NSError("writeToFile returned false")
        }
    }
    
    func downloadImage(urlString urlString:String, toPath path:String, callback:(NSError?) -> Void) {
        let session = NSURLSession.sharedSession()
        guard let url = NSURL(string:urlString) else {
            callback(NSError("bad URL: \(urlString)"))
            return
        }
        
        let task = session.downloadTaskWithURL(url) { (location, response, error) -> Void in
            if let location = location {
                let fm = NSFileManager.defaultManager()
                do {
                    try fm.moveItemAtPath(location.path!, toPath: path)
                }
                catch {
                    print(error)
                }
                callback(.None)
            }
        }
        task?.resume()
    }
    
}