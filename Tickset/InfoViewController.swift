//
//  InfoViewController.swift
//  Tickset
//
//  Created by Niels Lemmens on 2017-04-04.
//  Copyright © 2017 Carlos Martin. All rights reserved.
//

import UIKit

class InfoViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func closeButtonPressed(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }

}
