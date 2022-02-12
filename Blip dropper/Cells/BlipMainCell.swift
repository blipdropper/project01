//
//  BlipMainCell.swift
//  Blip dropper
//
//  Created by DANIEL PATRIARCA on 8/26/18.
//  Copyright © 2018 DANIEL PATRIARCA. All rights reserved.
//

import UIKit
import Parse

protocol blipMainCellDelegate {
    func resetMapImage(mergedMapImage: UIImage)
}

class BlipMainCell: UICollectionViewCell {
    var curBlipFile = blipFile()
    var prevBlipFile: PFFileObject?
    var delegateToMain: blipMainCellDelegate?

    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var cellLabel: UILabel!
    
    func setBlipCell (file: blipFile) {
        curBlipFile = file

        if let alreadyLoadedImage = file.imageUIImage {
            setUpImageCellOfType(imageToSetUp: alreadyLoadedImage)
        } else {
            // Get the image from the image data
            file.imageFile?.getDataInBackground { (data, error) in
                if let isCached = file.imageFile?.isDataAvailable {
                    if isCached || (self.prevBlipFile == file.imageFile) {
                        if let imageData = data {
                            if let imageToDisplay = UIImage(data: imageData) {
                                self.setUpImageCellOfType(imageToSetUp: imageToDisplay)
                            }
                        }
                    } else {
                        print("not already cached or prev <> curr and cell reused")
                    }
                }
            }
        }

        prevBlipFile = file.imageFile
    }
    func setUpImageCellOfType(imageToSetUp: UIImage) {
        image.clipsToBounds = true
        image.layer.cornerRadius = self.image.frame.size.width / 8

        if curBlipFile.file_type == "mapImage", let mapCenterImage = UIImage(named: "bPurpleAnnotation") {
            let centerImage = mergeCenterImage(bgImage: imageToSetUp, centerImage: mapCenterImage, scaleFactor: 0.15, alpha: 0.4)
            image.image = centerImage
            delegateToMain?.resetMapImage(mergedMapImage: centerImage)
            cellLabel.text = curBlip.place_name
        } else {
            image.image = imageToSetUp
        }
    }
}
