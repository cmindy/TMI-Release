//
//  SelectedAlbumCollectionViewCell.swift
//  TMI
//
//  Created by CHOMINJI on 2019. 1. 18..
//  Copyright © 2019년 momo. All rights reserved.
//

import UIKit

class AssetGridViewCell: UICollectionViewCell {
    @IBOutlet weak var detailImageView: UIImageView!
    
    @IBOutlet weak var checkImageView: UIImageView!
    
    var isChecked = false
    
    var thumbnailImage: UIImage! {
        didSet {
            detailImageView.image = thumbnailImage
        }
    }
    
    var checkImage: UIImage! {
        didSet {
            checkImageView.image =  checkImage
        }
    }
    
    
    override func prepareForReuse() {
        
        super.prepareForReuse()
//        detailImageView.image = nil
        checkImageView.image = nil
    }
}
