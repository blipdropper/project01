//
//  BlipPlacePickerVC.swift
//  Blip dropper
//
//  Created by DANIEL PATRIARCA on 10/8/18.
//  Copyright © 2018 DANIEL PATRIARCA. All rights reserved.
//
// Exif day light savings?
// Check for match in function, capture any time address matches but not the name, tokenize the name to see if some % of the items match (can use in search resutls gathering)
// BlipPlace data type, custom needs what blip place elements
// Exit cleanly when timer reached
// Load the data for the place/save the data for the place
// Place page for hitting button after setting YelpHere... Yelp Page?  VC with yelp details or blip places?

import UIKit
import MapKit

class BlipPlacePickerVC: UIViewController, UITableViewDelegate, UITextFieldDelegate, UITableViewDataSource, MKMapViewDelegate{
    var blipFiles = [blipFile]()
    var yelpBusinesses = [yelpBusinessSearch]()
    var yelpDone = false
    var hereItems = [hereItem]()
    var hereDone = false
    var blipPlaces = [blipPlace]()
    var curBlipPlace = blipPlace()
    var mapRegionTimer: Timer?
    var scheduledTimertimeInterval = 1.0
    var set = false
    var txtIsPlaceHolder = false
    var placeHolderText = "Enter a text to search map area"
    var test1 = 0
    var mode = ""
    
    @IBOutlet weak var placeOfInterest: UILabel!
    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var searchBox: UITextField!
    @IBOutlet weak var PlaceTableView: UITableView!
    @IBOutlet weak var topLabel: UILabel!
    @IBOutlet weak var searchAreaButton: UIButton!
    @IBOutlet weak var clearButton: UIButton!
    
    @IBAction func cancelPicker(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    @IBAction func searchArea(_ sender: Any) {
        print("Rerun the Yelp places list for map area... if an address is in the text box reset map to there... if its not an address filter?")
        print("Lat = \(map.centerCoordinate.latitude) Lon = \(map.centerCoordinate.longitude)")
        // Refresh the Places list
        searchArea()
    }
    @IBAction func clearPlaceOfInterest(_ sender: Any) {
        let confirmClearPlaceOfInterest = UIAlertController(title: "Confirm", message: "Confirm you want to clear place of interest from Blip", preferredStyle: .alert)
        let ok = UIAlertAction(title: "YES", style: .default, handler: { (action) -> Void in
            print("Ok button tapped")
            let blankPlace = blipPlace()
            self.setPlaceForCurBlip(place: blankPlace)
            self.dismiss(animated: true, completion: nil)
        })
        let cancel = UIAlertAction(title: "NO", style: .cancel) { (action) -> Void in
        }
        //Add OK and Cancel button to dialog message
        confirmClearPlaceOfInterest.addAction(ok)
        confirmClearPlaceOfInterest.addAction(cancel)
        
        // Present dialog message to user
        self.present(confirmClearPlaceOfInterest, animated: true, completion: nil)
    }
    func searchArea() {
        yelpDone = false
        hereDone = false
        blipPlaces = [blipPlace]()
        getYelp(latitude:map.centerCoordinate.latitude, longitude: map.centerCoordinate.longitude)
        getHere(latitude:map.centerCoordinate.latitude, longitude: map.centerCoordinate.longitude)
        runTimer()
    }
    func checkPlaceHolderText() {
        if searchBox.text == "" {
            searchBox.text = placeHolderText
            searchBox.textColor = UIColor.gray
            txtIsPlaceHolder = true
        }
    }
    func textFieldDidEndEditing(_ textField: UITextField) {
        checkPlaceHolderText()
    }
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if searchBox.text == placeHolderText {
            searchBox.text = ""
            searchBox.textColor = UIColor.black
        }
        return true;
    }
    /*
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        print("TextField should clear method called")
        return true;
    }
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        print("TextField should end editing method called")
        return true;
    }
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        print("While entering the characters this method gets called")
        return true;
    }
    */
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // find places using apple map (not interoperable with address search setting map to area)
        let searchRequest = MKLocalSearchRequest()
        searchRequest.naturalLanguageQuery = searchBox.text ?? ""
        searchRequest.region = map.region
        let mapSearch = MKLocalSearch(request: searchRequest)
        mapSearch.start {
            (searchResponse, error) in
            if error != nil {
                print(error ?? "")
            } else if searchResponse!.mapItems.count == 0  {
                print("No search results for that")
            } else {
                var i = 1
                var searchReturnPlaces = [blipPlace]()
                self.map.removeAnnotations(self.map.annotations)

                for singleItem in searchResponse!.mapItems {
                    var returnedBlipPlace = blipPlace()
                    let addr1 = placeMark2Addr1(placemark: singleItem.placemark)
                    // To open apple map: singleItem.openInMaps(launchOptions: nil)
                    let placeCoordinate = CLLocation(latitude: singleItem.placemark.coordinate.latitude, longitude: singleItem.placemark.coordinate.longitude)
                    if let lat = curBlip.blip_lat, let lon = curBlip.blip_lon {
                        let coordinate = CLLocation(latitude: lat, longitude: lon)
                        let distanceInMeters = coordinate.distance(from: placeCoordinate)
                        returnedBlipPlace.distance = distanceInMeters
                    }
                    returnedBlipPlace.type = "apple_search"
                    returnedBlipPlace.name = singleItem.name ?? ""
                    returnedBlipPlace.lat = singleItem.placemark.coordinate.latitude
                    returnedBlipPlace.lon = singleItem.placemark.coordinate.longitude
                    returnedBlipPlace.address1 = addr1
                    returnedBlipPlace.url = singleItem.url?.absoluteString ?? ""
                    print (returnedBlipPlace.url)
                    searchReturnPlaces.append(returnedBlipPlace)
                    i += 1
                }
                // Add Searched Locations to yelp places list
                // self.blipPlaces = searchReturnPlaces + self.blipPlaces
                self.blipPlaces = searchReturnPlaces  // Have "load nearbye places" table tail

                for i in 0..<self.blipPlaces.count {
                    if let lat = self.blipPlaces[i].lat, let lon = self.blipPlaces[i].lon {
                        let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                        let annotation = MKPointAnnotation()
                        annotation.coordinate = coordinate
                        annotation.title = self.blipPlaces[i].name
                        annotation.subtitle = String(i)
                        
                        self.map.addAnnotation(annotation)
                    }
                }
                self.PlaceTableView.reloadData()
            }
        }
        textField.resignFirstResponder()

        return true
    }
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        setMapRegionTimer()
    }
    func setMapRegionTimer() {
        mapRegionTimer?.invalidate()
        // Configure delay as bet fits your application
        mapRegionTimer = Timer.scheduledTimer(timeInterval: scheduledTimertimeInterval, target: self, selector: #selector(mapRegionTimerFired), userInfo: nil, repeats: false)
    }
    @objc func mapRegionTimerFired(sender: AnyObject) {
        // Load markers for current region:
        //   mapView.centerCoordinate or mapView.region
        print("timer did a thing")
        searchArea()
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return blipPlaces.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = PlaceTableView.dequeueReusableCell(withIdentifier: "fileCell", for: indexPath) as! BlipPlaceTVCell
        cell.delegate = self
        cell.rowNumber = indexPath.row
        cell.setBlipPlaceRow(placeRow: blipPlaces[indexPath.row])

        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // how can you move this to a button tap on the tableview cell class
        setPlaceForCurBlip(place: blipPlaces[indexPath.row])
        self.dismiss(animated: true, completion: nil)
    }
    func setPlaceForCurBlip(place: blipPlace) {
        curBlipPlace = place
        print("You selected \(curBlipPlace.name) \(curBlipPlace.yelpId) \(curBlipPlace.lat ?? 0) \(curBlipPlace.lon ?? 0)")
        curBlip.mode = "newPlace"
        curBlip.place = curBlipPlace
        curBlip.blip_yelp_id = curBlipPlace.yelpId
        curBlip.blip_here_id = curBlipPlace.hereId
        curBlip.place_lat = curBlipPlace.lat
        curBlip.place_lon = curBlipPlace.lon
        curBlip.place_addr = curBlipPlace.address1
        curBlip.place_name = curBlipPlace.name
        curBlip.place_url = curBlipPlace.url
    }
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpForm()
        printLog(stringValue: "View Did load happened")
        self.map.delegate = self
        self.searchBox.delegate = self
        PlaceTableView.dataSource = self
        topLabel.text = "Loading Nearby Places..."
        checkPlaceHolderText()
        if let lat = curBlip.blip_lat, let lon = curBlip.blip_lon {
            let mapCenter = CLLocationCoordinate2DMake(lat, lon)
            let mapSpan = MKCoordinateSpanMake(0.01, 0.01)
            let mapRegion = MKCoordinateRegionMake(mapCenter, mapSpan)
            self.map.setRegion(mapRegion, animated: true)

            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            annotation.title = "Your Blips Location"
            annotation.subtitle = "Subtitle Placeholder"
        }
        if curBlip.place_name == "" {
            placeOfInterest.text = "Select a place of interest for your blip"
            clearButton.isHidden = true
        } else {
            placeOfInterest.text = curBlip.place_name
            clearButton.isHidden = false
        }
    }
    func setUpForm () {
        searchAreaButton.layer.cornerRadius = 5
        searchAreaButton.layer.borderWidth = 1
        searchAreaButton.layer.borderColor = UIColor.black.cgColor
        clearButton.layer.cornerRadius = 5
        clearButton.layer.backgroundColor = UIColor.lightGray.cgColor

    }
    func runTimer() {
        var runCount = 0
        printLog(stringValue: "Timer function received   ")
        Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { timer in
            printLog(stringValue: "Timer for runcount \(runCount) fired")
            runCount += 1
            if self.yelpDone && self.hereDone {
                for yelp in self.yelpBusinesses {
                    var nameMatch = false
                    var addrMatch = false
                    var curBlipPlace = blipPlace()
                    //print ("----------\nChecking:\n\(yelp.name) :at \(yelp.address1) \(yelp.categories) \(yelp.imageURL) \(yelp.yelpURL)\n----------\n")

                    for i in 0..<self.hereItems.count {
                        // print("\(i) of \(self.hereItems.count)")
                        let here = self.hereItems[i]

                        // Does the Here/Yelp address line 1 match
                        if yelp.address1 == here.address1 {
                            // print("YES- \(here.address1)=\(yelp.address1)")
                            addrMatch = true
                        } else {
                            //print("no - \(here.address1)=\(yelp.address1)")
                            addrMatch = false
                        }
                        // Does the Here/Yelp title/name match
                        if yelp.name == here.title {
                            //print("YES- \(here.title)=\(yelp.name)")
                            nameMatch = true
                        } else {
                            // print("no - \(here.title)=\(yelp.name)")
                            nameMatch = false
                            // Do any of the alternative Here names match Yelp
                            for name in here.alternativeNames {
                                if yelp.name == name {
                                    print("  but YES- \(name)=\(yelp.name)")
                                    nameMatch = true
                                } else {
                                    //print("  no - \(name)=\(yelp.name)")
                                    nameMatch = false
                                }
                            }
                        }
                        if nameMatch && addrMatch {
                            // Here Place Match: set here and remove from here array
                            curBlipPlace.hereId = here.hereId
                            curBlipPlace.here = here
                            curBlipPlace.hereArrayPosition = here.arrayPosition
                            //print("REMOVING \(self.hereItems[i].title) from \(here.arrayPosition)")
                            self.hereItems.remove(at: i)
                            break
                        }
                    }
                    curBlipPlace.name = yelp.name
                    curBlipPlace.distance = yelp.distance
                    curBlipPlace.address1 = yelp.address1
                    curBlipPlace.lat = yelp.lat
                    curBlipPlace.lon = yelp.lon
                    curBlipPlace.url = yelp.yelpURL
                    curBlipPlace.yelpId = yelp.yelpId
                    curBlipPlace.yelp = yelp
                    curBlipPlace.yelpArrayPosition = yelp.arrayPosition
                    self.blipPlaces.append(curBlipPlace)
                }
                // Add Here only items into Blip Places (Make Func)
                for here in self.hereItems {
                    var curBlipPlace = blipPlace()
                    // print ("\(here.arrayPosition): \(here.title)")
                    self.topLabel.text = "Found \(self.hereItems.count) places, click to select"
                    curBlipPlace.name = here.title
                    curBlipPlace.distance = here.distance
                    curBlipPlace.address1 = here.address1
                    curBlipPlace.lat = here.lat
                    curBlipPlace.lon = here.lon
                    curBlipPlace.hereId = here.hereId
                    curBlipPlace.here = here
                    curBlipPlace.hereArrayPosition = here.arrayPosition
                    // Commented out to reduce annotation clutter
                    //                    self.blipPlaces.append(curBlipPlace)
                }
                // Add a spot on the array for Add Your Own Place
                self.blipPlaces.sort { $0.distance ?? 9999 < $1.distance ?? 9999 }
                for i in 0..<self.blipPlaces.count {
                    if let lat = self.blipPlaces[i].lat, let lon = self.blipPlaces[i].lon {
                        let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                        let annotation = MKPointAnnotation()
                        annotation.coordinate = coordinate
                        annotation.title = self.blipPlaces[i].name
                        annotation.subtitle = String(i)
                        
                        self.map.addAnnotation(annotation)
                    }
                }
                
                self.PlaceTableView.reloadData()
                timer.invalidate()
            }
            if runCount == 20 { //
                print("This took too long, notify user and die cleanly")
                timer.invalidate()
            }
        }
    }
    func getYelp(latitude: Double, longitude: Double) {
        // let appId = "7OyP1OAh76FSPkKVRnoC2w"
        let link = "https://api.yelp.com/v3/businesses/search?sort_by=distance&latitude=\(latitude)&longitude=\(longitude)"
        if let url = URL(string: link) {
            // Set headers
            var request = URLRequest(url: url)
            request.setValue("Accept-Language", forHTTPHeaderField: "en-us")
            request.setValue(yelpApiKey, forHTTPHeaderField: "Authorization")
            
            print("Attempting to get places around location from Yelp")
            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                if error != nil {
                    print(error!)
                } else {
                    if let urlContent = data {
                        do {
                            let jsonResult = try JSONSerialization.jsonObject(with: urlContent, options: JSONSerialization.ReadingOptions.mutableContainers) as AnyObject
                            if let places = jsonResult["businesses"] as? NSArray {
                                // -- Get the Yelp Busnesses
                                self.yelpBusinesses = parseYelpBusinessesArray(arrayValue: places)
                                self.yelpDone = true
                            }
                        } catch {
                            print("-------------------------\nJSON Processing Failed\n--------------------------")
                        }
                    }
                }
            }
            task.resume()
        } else {
            print("-------------------------\nYelp API Link failed\n--------------------------")
        }
    }
    func getHere(latitude: Double, longitude: Double) {
        if let url = URL(string: "https://places.cit.api.here.com/places/v1/discover/around?at=\(latitude)%2C\(longitude)&Accept-Language=en-us%2Cen%3Bq%3D0.9&app_id=\(hereAppId)&app_code=\(hereAppCode)") {
            print("Attempting to get places around location from Here")
            let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
                if error != nil {
                    print(error!)
                } else {
                    if let urlContent = data {
                        do {
                            let jsonResult = try JSONSerialization.jsonObject(with: urlContent, options: JSONSerialization.ReadingOptions.mutableContainers) as AnyObject
                            if let places = (jsonResult["results"] as? NSDictionary)?["items"] as? NSArray {
                                self.hereItems = printHereItem(arrayValue: places)
                                self.hereDone = true

                                DispatchQueue.main.async {
                                    self.topLabel.text = "Found \(self.hereItems.count) places, click to select"
                                }
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
    // ----------------------------------------
    // Maps and Annotations
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let tempString = (view.annotation?.subtitle) as? String {
            print("clicked on... \(tempString)")
            if let tempInt = Int(tempString) {
                setPlaceForCurBlip(place: blipPlaces[tempInt])
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        test1 += 1

        if set, test1 != 5 {
            return nil
        } else {
            let view = MKAnnotationView(annotation: annotation, reuseIdentifier: "annotationId")
            view.image = UIImage(named: "locationArea50")
            view.canShowCallout = true
            view.displayPriority = .required
            set = true

            return nil
        }
    }
}
extension BlipPlacePickerVC: customCellDelegate {
    func didTapButton1(msg: String, indexPath: Int) {
        self.topLabel.text = "\(msg)... selected row \(indexPath)"
        
        let urlString = blipPlaces[indexPath].url
        print("URL String: \(urlString)")

        if let url = URL(string: urlString) {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
                //If you want handle the completion block than
                UIApplication.shared.open(url, options: [:], completionHandler: { (success) in
                    print("Open url : \(success)")
                })
            }
        }
    }
    func didTapButton2(alert: String) {
        // self.topLabel.text = alert
        print("\(alert)")
    }
}


