//
//  BlipDataPickerVC.swift
//  Blip dropper
//
//  Created by DANIEL PATRIARCA on 10/8/18.
//  Copyright © 2018 DANIEL PATRIARCA. All rights reserved.
//

import UIKit

class BlipDataPickerVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var blipFiles = [blipFile]()
    var mode = ""
    @IBOutlet weak var FileTableView: UITableView!
    
    @IBAction func cancelPicker(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return blipFiles.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = FileTableView.dequeueReusableCell(withIdentifier: "fileCell", for: indexPath) as! BlipFileTVCell
        cell.mode = "select"
        cell.placeLabel.text = "\(indexPath.row) - \(blipFiles[indexPath.row].file_addr)"
        
        return cell
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        FileTableView.dataSource = self
        print(blipFiles.count)
    }
}
