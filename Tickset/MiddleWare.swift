//
//  MiddleWare.swift
//  Tickset
//
//  Created by Carlos Martin on 27/2/17.
//  Copyright © 2017 Carlos Martin. All rights reserved.
//

import Foundation
import UIKit

class MiddleWare {
    
    // MARK: - Helpers
    
    static func isValidURL(urlString: String) -> Bool {
        
        print(urlString)
        
        var successful = false
        if let url = NSURL(string: urlString) {
            
            successful = UIApplication.shared.canOpenURL(url as URL)
            if successful && urlString.contains("tickset.com/consume_ticket/") {
                successful = true
            } else {
                successful = false
            }
            
        } else {
            successful = false
        }
        return successful
    }
    
    // MARK: - Status
    
    static func getStatus(url: URL, completion: @escaping (_ status: Int, _ error: Error?) -> Void) {
        
        var finalStatus: Int = -1001
        var finalError: Error? = nil
        
        var getRequest = URLRequest(url: url)
        getRequest.httpMethod = "GET"
        getRequest.httpShouldHandleCookies = true
        
        let getTask = URLSession.shared.dataTask(with: getRequest) { (data, response, error) in
            
            if error == nil, let httpResponse = response as? HTTPURLResponse {
                
                finalStatus = httpResponse.statusCode
                
                if finalStatus == 200 {
                    
                    let urlContent = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)! as String
                    if !urlContent.contains("<form method=\"POST\">") {
                        finalStatus = 202
                    }
                }
                
            } else {
                finalError = error
            }
            completion(finalStatus, finalError)
        }
        getTask.resume()
    }
    
    // MARK: - Cookies
    
    static func getCookie(url: URL, completion: @escaping (_ cookie: String?, _ error: Error?) -> Void) {
        
        var finalError: Error? = nil
        var finalCookie: String? = nil
        
        var getRequest = URLRequest(url: url)
        getRequest.httpMethod = "GET"
        getRequest.httpShouldHandleCookies = true
        let getTask = URLSession.shared.dataTask(with: getRequest) { (_, response, error) in
            
            if error == nil, let httpResponse = response as? HTTPURLResponse {
                
                let rawCookie = httpResponse.allHeaderFields["Set-Cookie"] as? String
                finalCookie = self.prepareCookie(rawCookie: rawCookie)
                
            } else {
                finalError = error
            }
            completion(finalCookie, finalError)
        }
        getTask.resume()
    }
    
    static func prepareCookie(rawCookie: String?) -> String? {
        
        var finalCookie: String?
        if let rawCookie = rawCookie {
            finalCookie = rawCookie.components(separatedBy: "; ")[0].components(separatedBy: "=")[1]
        }
        return finalCookie
    }
    
    // MARK: - Tickets
    
    static func postTicket(url: URL, cookie: String, completion: @escaping (_ error: Error?) -> Void) {
        
        var postRequest = URLRequest(url: url)
        postRequest.httpMethod = "POST"
        postRequest.httpShouldHandleCookies = true
        postRequest.addValue(url.absoluteString, forHTTPHeaderField: "Referer")
        postRequest.httpBody = "csrfmiddlewaretoken=\(cookie)".data(using: .utf8)
        
        let postTask = URLSession.shared.dataTask(with: postRequest) { _, _, error in
            completion(error)
        }
        postTask.resume()
    }
    
}
