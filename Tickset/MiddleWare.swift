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
    static func isValidURL (url_string: String) -> Bool {
        var successful: Bool
        print(url_string)
        if let url = NSURL(string: url_string) {
            successful = UIApplication.shared.canOpenURL(url as URL)
            if successful && url_string.contains("tickset.com/consume_ticket/") {
                successful = true
            } else {
                successful = false
            }
        } else {
            successful = false
        }
        return successful
    }
    
    static func get_status (url: URL, completion: @escaping (_ status: Int, _ error: Error?) -> Void) {
        var final_status: Int = -1001
        var final_error: Error? = nil
        
        var get_request = URLRequest(url: url)
        get_request.httpMethod = "GET"
        get_request.httpShouldHandleCookies = true
        let get_task = URLSession.shared.dataTask(with: get_request) { (data, response, error) in
            if error == nil, let httpResponse = response as? HTTPURLResponse {
                final_status = httpResponse.statusCode
                
                if final_status == 200 {
                    let urlContent = NSString(data: data!, encoding: String.Encoding.utf8.rawValue) as! String
                    if !urlContent.contains("<form method=\"POST\">") {
                        final_status = 202
                    }
                }
            } else {
                final_error = error
            }
            completion(final_status, final_error)
        }
        get_task.resume()
    }
    
    static func get_cookie (url: URL, completion: @escaping (_ cookie: String?, _ error: Error?) -> Void) {
        var final_error: Error? = nil
        var final_cookie: String? = nil
        
        var get_request = URLRequest(url: url)
        get_request.httpMethod = "GET"
        get_request.httpShouldHandleCookies = true
        let get_task = URLSession.shared.dataTask(with: get_request) { (_, response, error) in
            if error == nil, let httpResponse = response as? HTTPURLResponse {
                let raw_cookie = httpResponse.allHeaderFields["Set-Cookie"] as? String
                final_cookie = self.prepare_cookie(raw_cookie: raw_cookie)
            } else {
                final_error = error
            }
            completion(final_cookie, final_error)
        }
        get_task.resume()
    }
    
    static func post_ticket (url: URL, cookie: String, completion: @escaping (_ error: Error?) -> Void) {
        var post_request = URLRequest(url: url)
        post_request.httpMethod = "POST"
        post_request.httpShouldHandleCookies = true
        post_request.addValue(url.absoluteString, forHTTPHeaderField: "Referer")
        post_request.httpBody = "csrfmiddlewaretoken=\(cookie)".data(using: .utf8)
        
        let post_task = URLSession.shared.dataTask(with: post_request) { _, _, error in
            completion(error)
        }
        post_task.resume()
    }
    
    static func prepare_cookie (raw_cookie: String?) -> String? {
        var f_cookie: String? = nil
        if let _r = raw_cookie {
            f_cookie = _r.components(separatedBy: "; ")[0].components(separatedBy: "=")[1]
        }
        return f_cookie
    }
}
