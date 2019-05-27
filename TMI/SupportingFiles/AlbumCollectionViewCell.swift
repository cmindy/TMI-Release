//
//  AlbumCollectionViewCell.swift
//  TMI
//
//  Created by CHOMINJI on 2019. 1. 2..
//  Copyright © 2019년 momo. All rights reserved.
//

import UIKit

class AlbumCollectionViewCell: UICollectionViewCell {
    @IBOutlet var titleImageView: UIImageView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var imageCountLabel: UILabel!
    
    var representedAssetIdentifier: String!
    
    var thumbnailImage: UIImage! {
        didSet {
            titleImageView.image = thumbnailImage
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        titleImageView.image = nil
        titleLabel.text = nil
        imageCountLabel.text = nil
    }
    
//    override func layoutSubviews() {
//        super.layoutSubviews()
//        self.titleImageView.applyImageRadius(radius: 10)
//    }
    /*
 self.titleImageView.layer.cornerRadius = 8
 self.titleImageView.layer.borderWidth = 0.5
 self.titleImageView.layer.borderColor = UIColor.init(red: 0, green: 0, blue: 0, alpha: 0.1).cgColor
 self.titleImageView.layer.masksToBounds = true
 
 self.titleImageView.layer.shadowColor = UIColor.black.cgColor
 self.titleImageView.layer.shadowOffset = CGSize(width: 0, height: 5.0)
 self.titleImageView.layer.shadowRadius = 2.0
 self.titleImageView.layer.shadowOpacity = 0.15
 self.titleImageView.layer.masksToBounds = false
 self.titleImageView.layer.shadowPath = UIBezierPath(roundedRect: self.bounds, cornerRadius: self.layer.cornerRadius).cgPath
 */
}
