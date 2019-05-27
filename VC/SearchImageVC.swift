//
//  SearchImageVC.swift
//  TMI
//
//  Created by CHOMINJI on 24/02/2019.
//  Copyright © 2019 momo. All rights reserved.
//

import UIKit

class SearchImageVC: UIViewController {

    var searchImageUrlString: String?
    @IBOutlet weak var searchImageView: UIImageView!
    var searchImage: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
//        if let searchImageUrl = URL(string: searchImageUrlString!) {
//            searchImageView.setImage(withUrl: searchImageUrl)
//        }
        
        searchImageView.image = searchImage
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if #available(iOS 8.0, *) {
            self.navigationController?.hidesBarsOnTap = true
        } else {
            // Fallback on earlier versions
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.navigationController?.hidesBarsOnTap = false
    }
}
