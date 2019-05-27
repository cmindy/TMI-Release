//
//  AlbumModel.swift
//  TMI
//
//  Created by CHOMINJI on 2019. 1. 3..
//  Copyright © 2019년 momo. All rights reserved.
//
import Photos

class AlbumModel {
    let name: String
    var count: Int
    var image: UIImage
    var collection: [PHAsset]
    
    init(name: String, count: Int, image: UIImage, collection: [PHAsset]) {
        self.name = name
        self.count = count
        self.image = image
        self.collection = collection
    }
}
