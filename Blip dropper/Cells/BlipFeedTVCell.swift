//
//  BlipFeedTVC.swift
//  Blip dropper
//
//  Created by DANIEL PATRIARCA on 8/18/18.
//  Copyright © 2018 DANIEL PATRIARCA. All rights reserved.
//

import UIKit
import Parse

class BlipFeedTVCell: UITableViewCell {
    var prevImageFile: PFFileObject?

    @IBOutlet weak var blipLabel: UILabel!
    @IBOutlet weak var blipImage: UIImageView!
    @IBOutlet weak var blipTS: UILabel!
    @IBOutlet weak var blipLatLon: UILabel!
    @IBOutlet weak var blipUsername: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func applyThumb (thumbFile: PFFileObject?) {
        print(thumbFile ?? "nil file?")
        print(prevImageFile ?? "nil prev File")
        prevImageFile = thumbFile
        // if you have no thumb but have an image then create a thumb
        // if your thumb file object is not nil but UIImage is then download
        
    }
    
    func setBlipCell (blip: blipData) {
        blipImage.image = UIImage(named: "bLightGrey")
        blipTS.text = blip.blip_dt_txt
        blipLabel.text = blip.blip_note
        blipLatLon.text = blip.blip_addr
        blipUsername.text = blip.blip_id

        // Reset Index 0 table row for new blips with no image
        if blip.imageFile == nil {
            print("image NIL")
            blipImage.image = nil
            blipImage.layer.cornerRadius = 0.0
            blipImage.clipsToBounds = false
            blipImage.layer.borderColor = UIColor.gray.cgColor
            blipImage.layer.borderWidth = 0.0
        }
        
        if blip.imageUIImage != nil {
            // this needs to be in a format function to clean up code
            blipImage.image = blip.imageUIImage
            blipImage.layer.cornerRadius = blipImage.frame.size.width / 2
            blipImage.clipsToBounds = true
            blipImage.layer.borderColor = UIColor.gray.cgColor
            blipImage.layer.borderWidth = 3.0
        } else {
            print("UI image for cell was NULL")
            blip.imageFile?.getDataInBackground { (data, error) in
                if let isCached = blip.imageFile?.isDataAvailable {
                    if isCached || (self.prevImageFile == blip.imageFile) {
                        if let imageData = data {
                            if let imageToDisplay = UIImage(data: imageData) {
                                self.blipImage.image = imageToDisplay
                            }
                        } else {
                            print(error?.localizedDescription ?? "")
                        }
                    } else {
                        print("not already cached or prev <> curr and cell reused")
                    }
                } else {
                    print("imageFile was nil")
                }
            }
        }
    prevImageFile = blip.imageFile
    }

}
