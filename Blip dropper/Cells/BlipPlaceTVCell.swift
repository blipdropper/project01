//
//  BlipPlaceTVCell.swift
//  Blip dropper
//
//  Created by DANIEL PATRIARCA on 10/8/18.
//  Copyright © 2018 DANIEL PATRIARCA. All rights reserved.
//

import UIKit

protocol customCellDelegate {
    func didTapButton1(msg: String, indexPath: Int)
    func didTapButton2(alert: String)
}

class BlipPlaceTVCell: UITableViewCell {
    var mode: String?
    var delegate: customCellDelegate?
    var rowNumber = Int()

    @IBOutlet weak var placeLabel: UILabel!
    @IBOutlet weak var placeInfoButton: UIButton!
    @IBAction func clickInfo(_ sender: Any) {
        print("click info tapped")
        delegate?.didTapButton1(msg: "Info 1 tapped", indexPath: rowNumber)
    }
    func setBlipPlaceRow (placeRow: blipPlace){
        mode = "select"
        var distanceString = ""
        if let distance = placeRow.distance {
            distanceString = String(format: " (%.1f m away)", distance)
        }
        placeLabel.text = "\(placeRow.name)\(distanceString)"
    }
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        setUpRow()
    }
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    func setUpRow() {
        placeInfoButton.layer.cornerRadius = placeInfoButton.frame.size.width / 2
    }
}
