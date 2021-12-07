//
//  ViewController.swift
//  SRT-IOS-App
//
//  Created by Sokolov, Alexander on 03.12.2021.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet private weak var srtVersionLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        srtVersionLabel.text = "SRT version: \(SRT_VERSION_STRING)"
    }


}

