//
//  BlipFileTVCell.swift
//  Blip dropper
//
//  Created by DANIEL PATRIARCA on 10/8/18.
//  Copyright © 2018 DANIEL PATRIARCA. All rights reserved.
//

import UIKit

class BlipFileTVCell: UITableViewCell {
    var mode: String?
    
    @IBOutlet weak var placeLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
