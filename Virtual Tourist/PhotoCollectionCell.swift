//
//  PhotoCollectionCell.swift
//  Virtual Tourist
//
//  Created by ziming li on 2017-08-09.
//  Copyright © 2017 ziming li. All rights reserved.
//

import UIKit

class PhotoCollectionCell: UICollectionViewCell {
    // Outlet
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    func turnOnActivityIndicator(turnOn: Bool) {
        if turnOn {
            // turnOn = true
            activityIndicator.isHidden = false
            activityIndicator.startAnimating()
            
        } else {
            // turnOn = false
            activityIndicator.stopAnimating()
            activityIndicator.isHidden = true
        }
    }
}
