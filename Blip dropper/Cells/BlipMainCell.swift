//
//  BlipMainCell.swift
//  Blip dropper
//
//  Created by DANIEL PATRIARCA on 8/26/18.
//  Copyright © 2018 DANIEL PATRIARCA. All rights reserved.
//

import UIKit
import Parse

class BlipMainCell: UICollectionViewCell {
    var curBlipFile = blipFile()
    var prevBlipFile: PFFileObject?

    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var cellLabel: UILabel!
    
    func setBlipCell (file: blipFile) {
        curBlipFile = file

        if file.imageUIImage == nil {
            // Get the image from the image data
            file.imageFile?.getDataInBackground { (data, error) in
                if let isCached = file.imageFile?.isDataAvailable {
                    if isCached || (self.prevBlipFile == file.imageFile) {
                        if let imageData = data {
                            if let imageToDisplay = UIImage(data: imageData) {
                                self.image.image = imageToDisplay
                                self.image.clipsToBounds = true
                                self.image.layer.cornerRadius = self.image.frame.size.width / 8
                            }
                        }
                    } else {
                        print("not already cached or prev <> curr and cell reused")
                    }
                }
            }
        } else {
            image.image = file.imageUIImage
        }
        
        if file.file_type == "mapImage" {
            // print ("map image YES")
            cellLabel.text = curBlip.place_name
        } else {
            // print ("map image NO")
            cellLabel.text = ""
        }
        prevBlipFile = file.imageFile
    }
    
}
