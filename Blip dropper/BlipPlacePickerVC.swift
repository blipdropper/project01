//
//  BlipPlacePickerVC.swift
//  Blip dropper
//
//  Created by DANIEL PATRIARCA on 10/8/18.
//  Copyright © 2018 DANIEL PATRIARCA. All rights reserved.
//

import UIKit

class BlipPlacePickerVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var blipFiles = [blipFile]()
    var yelpBusinesses = [yelpBusinessSearch]()

    var mode = ""
    
    @IBOutlet weak var PlaceTableView: UITableView!
    @IBAction func cancelPicker(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return yelpBusinesses.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = PlaceTableView.dequeueReusableCell(withIdentifier: "fileCell", for: indexPath) as! BlipFileTVCell
        cell.mode = "select"
        cell.placeLabel.text = "\(indexPath.row) - \(yelpBusinesses[indexPath.row].name)"
        print("table loaded....")
        return cell
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        PlaceTableView.dataSource = self
        if let lat = curBlip.blip_lat, let lon = curBlip.blip_lon {
            getYelp(latitude: lat, longitude: lon)
        }
        print("After load: \(yelpBusinesses.count)")
    }
    
    func getYelp(latitude: Double, longitude: Double) {
        // let appId = "7OyP1OAh76FSPkKVRnoC2w"
        let appSecret = "Bearer aeLA0m0U9cqOFqgN3CHVOQ_UaJDlB6DCysj23z-woyfmA4Mxf_nMjYO_clogiXE44VF06VohQBO0k-3TFJbEUWqxWr7fJmZJLTz2ojSmljIqsDBCfODqYTKgyK6OW3Yx"
        let link = "https://api.yelp.com/v3/businesses/search?sort_by=distance&latitude=\(latitude)&longitude=\(longitude)"
        if let url = URL(string: link) {
            // Set headers
            var request = URLRequest(url: url)
            request.setValue("Accept-Language", forHTTPHeaderField: "en-us")
            request.setValue(appSecret, forHTTPHeaderField: "Authorization")
            
            print("Attempting to get places around location from Yelp")
            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                if error != nil {
                    print(error!)
                } else {
                    if let urlContent = data {
                        do {
                            let jsonResult = try JSONSerialization.jsonObject(with: urlContent, options: JSONSerialization.ReadingOptions.mutableContainers) as AnyObject
                            if let places = jsonResult["businesses"] as? NSArray {
                                self.yelpBusinesses = printYelpBusiness(arrayValue: places)
                                print("Count is \(self.yelpBusinesses.count)")
                            }
                        } catch {
                            print("-------------------------\nJSON Processing Failed\n--------------------------")
                        }
                    }
                }
            }
            task.resume()
        } else {
            print("Couldn't get YELP")
        }
    }
    
    func getHere(latitude: Double, longitude: Double) {
        print("Run Here")
        let app_id = "u0kMh9pqRbVbIRoRUDUR"
        let app_code = "Sm_Nj0Z8V4_Ac-azowbweQ"
        if let url = URL(string: "https://places.cit.api.here.com/places/v1/discover/around?at=\(latitude)%2C\(longitude)&Accept-Language=en-us%2Cen%3Bq%3D0.9&app_id=\(app_id)&app_code=\(app_code)") {
            let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
                if error != nil {
                    print(error!)
                } else {
                    if let urlContent = data {
                        do {
                            let jsonResult = try JSONSerialization.jsonObject(with: urlContent, options: JSONSerialization.ReadingOptions.mutableContainers) as AnyObject
                            if let places = (jsonResult["results"] as? NSDictionary)?["items"] as? NSArray {
                                printHereItem(arrayValue: places)
                            }
                        } catch {
                            print("JSON Processing Failed/n/n//n--------------------------")
                        }
                    }
                }
            }
            task.resume()
        } else {
            print("Couldn't get results from Here")
        }
    }
}
