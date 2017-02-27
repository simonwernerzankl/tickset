//
//  Colors.swift
//  Tickset
//
//  Created by Carlos Martin on 23/2/17.
//  Copyright © 2017 Carlos Martin. All rights reserved.
//

import Foundation
import UIKit

class Colors {
    static func red () -> UIColor {
        return UIColor(red: 255.0/255.0, green: 59.0/255.0, blue: 48.0/255.0, alpha: 1.0)
        //return UIColor.red
    }
    
    static func green () -> UIColor {
        return UIColor(red: 76.0/255.0, green: 217.0/255.0, blue: 100.0/255.0, alpha: 1.0)
        //return UIColor.green
    }
    
    static func orange () -> UIColor {
        return UIColor(red: 255.0/255.0, green: 149.0/255.0, blue: 0.0, alpha: 1.0)
        //return UIColor.orange
    }
    
    static func gray () -> UIColor {
        return UIColor.gray
    }
    
    static func white () -> UIColor {
        return UIColor.white
    }
    
    static func ticksetGreen () -> UIColor {
        //return UIColor(red: 78/255.0, green: 171/255.0, blue: 144/255.0, alpha: 1)
        return UIColor.green
    }
}
