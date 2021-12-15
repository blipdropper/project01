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
    var prevImage: PFFileObject?

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
        print(prevImage ?? "nil prev File")
        prevImage = thumbFile
    }

}
