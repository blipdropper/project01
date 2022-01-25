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
    func setBlipRow (blip: blipData) {
        blipImage.image = UIImage(named: "bLightGrey")
        blipTS.text = blip.blip_dt_txt
        blipLatLon.text = returnLocationString(location: blip.blip_location)

        let noteBreak = breakOutHeadingFromString(fullString: blip.blip_note, charBreakPoint: 30)
        blipLabel.text = noteBreak.remainingText
        blipUsername.text = noteBreak.heading
        
        blipImage.layer.cornerRadius = 0.0
        blipImage.clipsToBounds = false
        blipImage.layer.borderColor = UIColor.gray.cgColor
        blipImage.layer.borderWidth = 0.0

        // Reset Index 0 table row for new blips with no image
        /*
        if blip.imageFile == nil {
            //print("image NIL")
//            blipImage.image = nil
            blipImage.layer.cornerRadius = 0.0
            blipImage.clipsToBounds = false
            blipImage.layer.borderColor = UIColor.gray.cgColor
            blipImage.layer.borderWidth = 0.0
        }
         */

        if blip.imageUIImage != nil {
            // this needs to be in a format function to clean up code
            blipImage.image = blip.imageUIImage
            blipImage.layer.cornerRadius = blipImage.frame.size.width / 4
            blipImage.clipsToBounds = true
            blipImage.layer.borderColor = UIColor.gray.cgColor
            blipImage.layer.borderWidth = 1.0
        } else {
            // UI image for cell was NULL... not sure why it ever wouldn't be? Load from Cached data?
            blip.imageThumbFile?.getDataInBackground { (data, error) in
                if let isCached = blip.imageThumbFile?.isDataAvailable {
                    if isCached || (self.prevImageFile == blip.imageThumbFile) {
                        if let imageData = data {
                            if let imageToDisplay = UIImage(data: imageData) {
                                self.blipImage.image = imageToDisplay
                                self.blipImage.layer.cornerRadius = self.blipImage.frame.size.width / 4
                                self.blipImage.clipsToBounds = true
                                self.blipImage.layer.borderColor = UIColor.gray.cgColor
                                self.blipImage.layer.borderWidth = 1.0
                                //self.blipImage.layer.cornerRadius = 10.0;
                                //self.blipImage.borderColor = UIColor( red: 0.5, green: 0.5, blue:0, alpha: 1.0 )
                            }
                        } else {
                            print(error?.localizedDescription ?? "")
                        }
                    } else {
                        print("not already cached or prev <> curr and row reused")
                    }
                } else {
                    print("imageFile was nil")
                }
            }
        }
    prevImageFile = blip.imageThumbFile
    }
}
