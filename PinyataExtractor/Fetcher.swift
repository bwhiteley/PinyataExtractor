//
//  Fetcher.swift
//  PinyataExtractor
//
//  Created by J. B. Whiteley on 7/7/15.
//  Copyright © 2015 SwiftBit. All rights reserved.
//

import Foundation

public extension NSError {
    public convenience init(_ localizedDescription:String) {
        let errorDomain = "swift-bit"
        let functionKey = "\(errorDomain).function"
        let fileKey = "\(errorDomain).file"
        let lineKey = "\(errorDomain).line"
        let userInfo: [String: AnyObject] = [
            functionKey: __FUNCTION__,
            fileKey: __FILE__,
            lineKey: __LINE__,
            NSLocalizedDescriptionKey: localizedDescription
        ]
        self.init(domain:errorDomain, code: 47, userInfo: userInfo)
    }
}


class Fetcher {
    let api = API()
    
    var targetDirectory:String {
        var dir:String = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true).first!
        dir = dir.stringByAppendingPathComponent("Pinyata")
        return dir
    }
    
    let apiBase = "http://api-new.pinyata.com"
    
    let fileManager = NSFileManager.defaultManager()
    
    func run() throws {
        var obj = try api.getObject(apiBase + "/login", params: nil)
        try fileManager.createDirectoryAtPath(targetDirectory, withIntermediateDirectories: true, attributes: nil)
        let userId:String = obj["id"] as! String
        print("userId: \(userId)")
        
        let url = apiBase + "/v2/currentProfileFlyers?userId=\(userId)"
        obj = try api.getObject(url, params: nil)
        
        try printFlyersFromResult(obj)
        for ;; {
            if let prevUrl = prevUrl(obj) {
                obj = try api.getObject(prevUrl, params: nil)
                try printFlyersFromResult(obj)
            }
            else {
                break
            }
        }
        
    }
    
    func printFlyersFromResult(obj:[String:AnyObject]) throws {
        guard let flyers = obj["results"] as? [[String:AnyObject]] else {
            throw NSError("No flyers in response")
        }
        for flyer in flyers {
            try printFlyer(flyer)
        }
    }
        
    func prevUrl(obj:[String:AnyObject]) -> String? {
        if let prevUri = obj["previousUri"] as? String {
            return apiBase + prevUri
        }
        return nil
    }
    
    var curFlyerPath:String = ""
    
    func printFlyer(obj:[String:AnyObject]) throws {
        guard let title = obj["title"] as? String else {
            throw NSError("No title in flyer")
        }
        print("flyer: \(title)")
        guard let date = obj["dateTime"] as? String else {
            throw NSError("No datetime in flyer")
        }
        let dirName = "\(date)_\(title)"
        curFlyerPath = targetDirectory.stringByAppendingPathComponent(dirName)
        try fileManager.createDirectoryAtPath(curFlyerPath, withIntermediateDirectories: true, attributes: nil)
        let data = try NSJSONSerialization.dataWithJSONObject(obj, options: NSJSONWritingOptions.PrettyPrinted)
        let jsonPath = curFlyerPath.stringByAppendingPathComponent("flyer.json")
        data.writeToFile(jsonPath, atomically: false)
        try printPostsFromFlyer(obj)
    }
    
    func printPostsFromFlyer(obj:[String:AnyObject]) throws {
        guard let id = obj["id"] as? String else {
            throw NSError("No flyerId")
        }
        let url = apiBase + "/v2/flyers/\(id)/posts?mode=all&offset=0&pageSize=1000"
        let postResult = try api.getObject(url, params: nil)
        
        let jsonData = try NSJSONSerialization.dataWithJSONObject(postResult, options: .PrettyPrinted)
        let postsJSONPath = curFlyerPath.stringByAppendingPathComponent("posts.json")
        jsonData.writeToFile(postsJSONPath, atomically: true)
        
        guard let posts = postResult["results"] as? [[String:AnyObject]] else {
            throw NSError("No Posts")
        }
        
        print("Num posts \(posts.count)")
        
        for post in posts {
            guard let id = post["id"] as? String else {
                throw NSError("No post ID")
            }
            //print(" post \(id)")
            try printPost(post)
        }
    }
    
    func printPost(obj:[String:AnyObject]) throws {
        if let imageBase = obj["imageBase"] as? String {
            let imageUrl = imageBase + "image_3x.jpg"
            guard let id = obj["id"] as? String else {
                throw NSError("No Post ID")
            }
            let filePath = curFlyerPath.stringByAppendingPathComponent("\(id).jpg")
            do {
                try api.downloadImage(urlString: imageUrl, toPath: filePath)
                print(".", appendNewline: false)
            }
            catch {
                let x2Url = imageBase + "image_2x.jpg"
                do {
                    try api.downloadImage(urlString: x2Url, toPath: filePath)
                    print(".", appendNewline: false)
                }
                catch {
                    print (error)
                }
            }
            //print("wrote image: \(filePath)")
//            api.downloadImage(urlString: imageUrl, toPath: filePath, callback: { (error) -> Void in
//                if let error = error {
//                    fatalError(error.localizedDescription)
//                }
//            })
        }
    }
    
}


