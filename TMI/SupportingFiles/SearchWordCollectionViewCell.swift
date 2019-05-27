//
//  SearchWordCollectionViewCell.swift
//  TMI
//
//  Created by CHOMINJI on 21/03/2019.
//  Copyright © 2019 momo. All rights reserved.
//

import UIKit

class SearchWordCollectionViewCell: UICollectionViewCell {
    
    var searchWordLabel:UILabel = {
        var textLabel = UILabel()
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        textLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        
        return textLabel
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(searchWordLabel)
        
        NSLayoutConstraint.activate([
            searchWordLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            searchWordLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
            ])
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        addSubview(searchWordLabel)
        
        NSLayoutConstraint.activate([
            searchWordLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            searchWordLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
            ])
    }
}
