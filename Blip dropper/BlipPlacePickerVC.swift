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
    var set = false
    var test1 = 0
    var mode = ""
    
    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var searchBox: UITextField!
    @IBOutlet weak var PlaceTableView: UITableView!
    @IBOutlet weak var topLabel: UILabel!
    @IBOutlet weak var searchAreaButton: UIButton!
    
    @IBAction func cancelPicker(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    @IBAction func searchArea(_ sender: Any) {
        print("Rerun the Yelp places list for map area... if an address is in the text box reset map to there... if its not an address filter?")
        print("Lat = \(map.centerCoordinate.latitude) Lon = \(map.centerCoordinate.longitude)")

        // Refresh the Places list
        yelpDone = false
        hereDone = false
        blipPlaces = [blipPlace]()
        getYelp(latitude:map.centerCoordinate.latitude, longitude: map.centerCoordinate.longitude)
        getHere(latitude:map.centerCoordinate.latitude, longitude: map.centerCoordinate.longitude)
        runTimer()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
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

                for singleItem in searchResponse!.mapItems {
                    var curBlipPlace = blipPlace()
            
                    let addr1 = placeMark2Addr1(placemark: singleItem.placemark)
                    // Add these search items to blipPlaces array
                    // opens in apple map app singleItem.openInMaps(launchOptions: nil)
                    curBlipPlace.type = "apple_search"
                    curBlipPlace.name = singleItem.name ?? ""
                    curBlipPlace.lat = singleItem.placemark.coordinate.latitude
                    curBlipPlace.lon = singleItem.placemark.coordinate.longitude
                    curBlipPlace.address1 = addr1
                    curBlipPlace.url = singleItem.url?.absoluteString ?? ""
                    print (curBlipPlace.url)
                    searchReturnPlaces.append(curBlipPlace)
                    /*
                    print("\(singleItem.placemark)")
                    print("\(singleItem.name)")
                    print("\(singleItem.phoneNumber)")
                    print("\(singleItem.url?.absoluteString)")
                    print("\(singleItem.timeZone)")
                    */
                    i += 1
                }
                self.blipPlaces = searchReturnPlaces + self.blipPlaces
                self.PlaceTableView.reloadData()
            }
        }
        
        textField.resignFirstResponder()

        return true
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return blipPlaces.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = PlaceTableView.dequeueReusableCell(withIdentifier: "fileCell", for: indexPath) as! BlipFileTVCell
        cell.mode = "select"
        cell.placeLabel.text = "\(indexPath.row): \(blipPlaces[indexPath.row].name) - \(blipPlaces[indexPath.row].distance ?? 999)"
        //\(blipPlaces[indexPath.row].yelpArrayPosition) \(blipPlaces[indexPath.row].hereArrayPosition)- \(blipPlaces[indexPath.row].distance ?? 999) - \(blipPlaces[indexPath.row].name)"
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        curBlipPlace = blipPlaces[indexPath.row]
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
        print(curBlip.place_url)
        self.dismiss(animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        printLog(stringValue: "View Did load happened")
        self.map.delegate = self
        PlaceTableView.dataSource = self
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
            
            self.map.addAnnotation(annotation)
            searchAreaButton.layer.cornerRadius = 5
            searchAreaButton.layer.borderWidth = 1
            searchAreaButton.layer.borderColor = UIColor.black.cgColor
        }
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
                    self.topLabel.text = "Count is \(self.hereItems.count)"
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
                                    self.topLabel.text = "Count is \(self.hereItems.count)"
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
                curBlipPlace = blipPlaces[tempInt]
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
            print(annotation.title)
            return view
        }
    }

    /*
     func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
     if let annotation = views.first(where: { $0.reuseIdentifier == "annotationId" })?.annotation {
     mapView.selectAnnotation(annotation, animated: true)
     }
     }
     */
    /*
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation
        {
            return nil
        }
        var annotationView = self.map.dequeueReusableAnnotationView(withIdentifier: "Pin")
        if annotationView == nil{
            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "Pin")
            annotationView!.canShowCallout = true
        }else{
            annotationView?.annotation = annotation
        }
        if set {
            print("I wonder how this works")
            //annotationView?.image = UIImage(named: "starbucks")
        } else {
            print("So it set the first one here")
            annotationView?.image = UIImage(named: "locationArea50")
        }
        annotationView?.image = UIImage(named: "locationArea50")
        set = true
        return annotationView
    }
 */
}


