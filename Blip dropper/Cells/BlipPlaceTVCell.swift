//
//  BlipPlaceTVCell.swift
//  Blip dropper
//
//  Created by DANIEL PATRIARCA on 10/8/18.
//  Copyright © 2018 DANIEL PATRIARCA. All rights reserved.
//

import UIKit

class BlipPlaceTVCell: UITableViewCell {
    var mode: String?
    
    @IBOutlet weak var placeLabel: UILabel!
    @IBOutlet weak var placeInfoButton: UIButton!
    
    @IBAction func placeInfo(_ sender: Any) {
        print("You hit info for \(placeLabel.text ?? "")")
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
