//
//  dataTypes.swift
//  Blip dropper
//
//  Created by DANIEL PATRIARCA on 8/27/18.
//  Copyright © 2018 DANIEL PATRIARCA. All rights reserved.
//

import UIKit
import Parse

/* maybe fix that bug where loading images jump around?
 https://thomashanning.com/the-most-common-mistake-in-using-uitableview/
 https://developer.apple.com/forums/thread/119005
 https://jayeshkawli.ghost.io/using-imagedownloader-library-with-reusable-cells/
*/
// convert lat lon to coordinates/placemarks
// convert lat lon to strings
// present time as a string with or without a TZ override
// turn files into UIImages

// ----------------------------------------
// Global data
var curBlip = blipData()
var loadedBlips = [blipData]()
let yelpApiKey = "Bearer aeLA0m0U9cqOFqgN3CHVOQ_UaJDlB6DCysj23z-woyfmA4Mxf_nMjYO_clogiXE44VF06VohQBO0k-3TFJbEUWqxWr7fJmZJLTz2ojSmljIqsDBCfODqYTKgyK6OW3Yx"
let hereAppId = "u0kMh9pqRbVbIRoRUDUR"
let hereAppCode = "Sm_Nj0Z8V4_Ac-azowbweQ"
var reloadRequired = false


// ----------------------------------------
// Global data structures
public struct blipData {
    var blip_id = ""
    var user_id = ""
    var blip_note = ""
    var blip_dt: Date?
    var blip_dt_txt = ""
    var blip_lat: Double?
    var blip_lon: Double?
    var blip_addr = ""
    var blip_tz_secs = 0
    var blip_yelp_id = ""
    var blip_here_id = ""
    var place_lat: Double?
    var place_lon: Double?
    var place_addr = ""
    var place_name = ""
    var place_url = ""
    var place_imageURL = ""
    var place: blipPlace?
    var create_dt: Date?
    var create_dt_txt = ""
    var create_lat: Double?
    var create_lon: Double?
    var create_addr = ""
    var create_tz_secs = 0
    var blip_status = ""
    var isPublic = true
    var imageFile: PFFileObject?
    var imageUIImage: UIImage?
    var imageThumbFile: PFFileObject?
    var imageThumbUIImage: UIImage?
    var fileCount = 0
    var arrayPosition = Int()
    var mode = ""
}
public struct blipFile {
    var file_id = ""
    var file_type = ""
    var blip_id = ""
    var user_id = ""
    var file_dt: Date?
    var file_dt_txt = ""
    var file_addr = ""
    var file_lat: Double?
    var file_lon: Double?
    var create_dt: Date?
    var create_dt_txt = ""
    var create_lat: Double?
    var create_lon: Double?
    var create_addr = ""
    var imageFile: PFFileObject?
    var imageUIImage: UIImage?
    var imageThumbFile: PFFileObject?
    var imageThumbUIImage: UIImage?
    var fileURL = ""
}
public struct blipLocation {
    var clocation = CLLocation()
    var lat: Double?
    var lon: Double?
    var strLatitude = ""
    var strLongitude = ""
    var strLatLon = ""
    var subThoroughfare = ""
    var thoroughfare = ""
    var subLocality = ""
    var subAdministrativeArea = ""
    var postalCode = ""
    var country = ""
    var strCourse = ""
    var strSpeed = ""
    var strAltitude = ""
    var strAddress = ""
    // create display permeations for blipMain, blip feed cell, map, etc
}
public struct blipPlace {
    var name = ""
    var distance: Double?
    var address1 = ""
    var lat: Double?
    var lon: Double?
    var url = ""
    var iconURL = ""
    var yelpId = ""
    var yelp: yelpBusinessSearch?
    var yelpArrayPosition = Int() // Stand in for order that API gave it to you in and makes some loops easier
    var hereId = ""
    var here: hereItem?
    var hereArrayPosition = Int()
    var type = ""
}
public struct yelpBusinessSearch {
    var name = ""
    var yelpId = ""
    var hereId = ""
    var address = ""
    var lat: Double?
    var lon: Double?
    var phone = ""
    var zip = ""
    var yelpURL = ""
    var imageURL = ""
    var address1 = ""
    var city = ""
    var state = ""
    var country = ""
    var loc: blipLocation?
    var iconUrl = ""
    var category = ""
    var distance: Double?
    var categories = [String]()
    var searchAble = ""
    var arrayPosition = Int()
}
public struct hereItem {
    var title = ""
    var hereId = ""
    var lat: Double?
    var lon: Double?
    var iconUrl = ""
    var href = ""
    var category = ""
    var vicinity = ""
    var distance: Double?
    var alternativeNames = [String]()
    var address1 = ""
    var searchAble = ""
    var arrayPosition = Int()
}

// ----------------------------------------
// Global Functions
func getBlipFileImage (blipFile: blipFile) {
    blipFile.imageFile?.getDataInBackground { (data, error) in
        if let imageData = data {
            if let imageToDisplay = UIImage(data: imageData) {
                saveBlipFileThumb(objectId: blipFile.file_id, image: returnThumbnail(bigImage: imageToDisplay))
            }
        }
    }
}
func saveBlipFileThumb (objectId: String, image: UIImage) {
    var thumbImageFile: PFFileObject?
    // Load blip to update
    let query = PFQuery(className: "BlipFile")
    query.getObjectInBackground(withId: objectId) { (blipFile, error) in
        if blipFile != nil && error == nil {
            // Encode the image as JPG
            if let imageData = UIImageJPEGRepresentation(image, 0.1) {
                print("start image encode to PFFile \(objectId)")
                if let blipFile = PFFileObject(name: "image.jpg", data: imageData as Data) {
                    thumbImageFile = blipFile
                }
                print("done image encode to PFFile")
            }
            blipFile!["imageThumbFile"] = thumbImageFile
            blipFile!.saveInBackground()
        } else {
            print(error?.localizedDescription ?? "Maybe no blip \(objectId)")
        }
    }
}
func getBlipImage (blip: blipData) {
    blip.imageFile?.getDataInBackground { (data, error) in
        if let imageData = data {
            if let imageToDisplay = UIImage(data: imageData) {
                saveParseThumb(objectId: blip.blip_id, image: returnThumbnail(bigImage: imageToDisplay))
            }
        }
    }
}
func saveParseThumb (objectId: String, image: UIImage) {
    var thumbImageFile: PFFileObject?
    // Load blip to update
    let query = PFQuery(className: "BlipPost")
    query.getObjectInBackground(withId: objectId) { (blip, error) in
        if blip != nil && error == nil {
            // Encode the image as JPG
            if let imageData = UIImageJPEGRepresentation(image, 0.1) {
                print("start image encode to PFFile \(objectId)")
                if let blipFile = PFFileObject(name: "image.jpg", data: imageData as Data) {
                    thumbImageFile = blipFile
                }
                print("done image encode to PFFile")
            }
            blip!["imageThumbFile"] = thumbImageFile
            blip!.saveInBackground()
        } else {
            print(error?.localizedDescription ?? "Maybe no blip \(objectId)")
        }
    }
}
func rotateImage(image: UIImage) -> UIImage {
    if (image.imageOrientation == UIImage.Orientation.up) {
        return image
    }
    UIGraphicsBeginImageContext(image.size)
    image.draw(in: CGRect(origin: .zero, size: image.size))
    let copy = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()

    return copy!
}

func returnThumbnail(bigImage: UIImage) -> UIImage {
    var thumbnail = UIImage()

    if let imageData = UIImagePNGRepresentation(rotateImage(image: bigImage)){
        let options = [
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: 100] as CFDictionary // Specify your desired size at kCGImageSourceThumbnailMaxPixelSize. 100 seems standard
        
        imageData.withUnsafeBytes { ptr in
            guard let bytes = ptr.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
                return
            }
            if let cfData = CFDataCreate(kCFAllocatorDefault, bytes, imageData.count){
                let source = CGImageSourceCreateWithData(cfData, nil)!
                let imageReference = CGImageSourceCreateThumbnailAtIndex(source, 0, options)!
                thumbnail = UIImage(cgImage: imageReference) // You get your thumbail here
            }
        }
    }
    return thumbnail
}

func time2String (time: Date) -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "E, d MMM yyyy h:mm a"
    let strDate = dateFormatter.string(from: time)
    return strDate
}
func substr (stringValue: String, forInt: Int) -> String {
    let returnString = stringValue[..<stringValue.index(stringValue.startIndex, offsetBy: forInt)]
    return String(returnString)
}
func printLog (stringValue: String) {
    let now = time2String(time: Date())
    print("\(now): \(stringValue)")
}
func placeMark2Addr1 (placemark: CLPlacemark) -> String {
    let addrDelim = " "
    var address1 = ""
    
    if placemark.subThoroughfare != nil {
        address1 += placemark.subThoroughfare! + " "
    }
    if placemark.thoroughfare != nil {
        address1 += placemark.thoroughfare! + addrDelim
    }
    return address1
}

func placeMark2Postal (placemark: CLPlacemark) -> String {
    let addrDelim = " "
    var address = ""
    
    address = placeMark2Addr1(placemark: placemark)

    if placemark.subLocality != nil {
        address += placemark.subLocality! + addrDelim
    }
    if placemark.subAdministrativeArea != nil {
        address += placemark.administrativeArea! + addrDelim
    }
    if placemark.postalCode != nil {
        address += placemark.postalCode! + addrDelim
    }
    if placemark.country != nil {
        address += placemark.country! + addrDelim
    }

    return address
}
func runDelayTimer() {
    // turn current date into an integer
    // calculate end time of period
    // have emergency escape on loop count or modding the end of the time so that last digit will be 0 1-10 times or something
    var runCount = 0
    printLog(stringValue: "Delay Timer function received   ")

    Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { timer in
        printLog(stringValue: "Timer for runcount \(runCount) fired")
        runCount += 1
        if runCount == 20 { //
            print("This took too long, notify user and die cleanly")
            timer.invalidate()
        }
    }
}

// COMPARE
func compareYelpHere (yelp: yelpBusinessSearch, here: hereItem) -> (nameMatch: Bool, addrMatch: Bool) {
    var nameMatch = false
    var addrMatch = false
    return (nameMatch, addrMatch)
}

// YELP
func parseYelpBusinessesArray (arrayValue: NSArray) -> [yelpBusinessSearch] {
    var yelpBusinesses = [yelpBusinessSearch]()
    for i in 0..<arrayValue.count {
        var curYelp = yelpBusinessSearch()
        curYelp.arrayPosition = i
        if let yelpId = (arrayValue[i] as? NSDictionary)?["id"] as? String {
            curYelp.yelpId = yelpId     }
        if let name = (arrayValue[i] as? NSDictionary)?["name"] as? String {
            curYelp.name = name         }
        if let imageURL = (arrayValue[i] as? NSDictionary)?["image_url"] as? String {
            curYelp.imageURL = imageURL }
        if let url = (arrayValue[i] as? NSDictionary)?["url"] as? String {
            curYelp.yelpURL = url       }
        if let latitude = ((arrayValue[i] as? NSDictionary)?["coordinates"] as? NSDictionary)?["latitude"] as? Double {
            curYelp.lat = latitude      }
        if let longitude = ((arrayValue[i] as? NSDictionary)?["coordinates"] as? NSDictionary)?["longitude"] as? Double {
            curYelp.lon = longitude     }
        if let addr1 = ((arrayValue[i] as? NSDictionary)?["location"] as? NSDictionary)?["address1"] as? String {
            curYelp.address1 = addr1    }
        if let city = ((arrayValue[i] as? NSDictionary)?["location"] as? NSDictionary)?["city"] as? String {
            curYelp.city = city         }
        if let state = ((arrayValue[i] as? NSDictionary)?["location"] as? NSDictionary)?["state"] as? String {
            curYelp.state = state       }
        if let zip = ((arrayValue[i] as? NSDictionary)?["location"] as? NSDictionary)?["zip_code"] as? String {
            curYelp.zip = zip           }
        if let country = ((arrayValue[i] as? NSDictionary)?["location"] as? NSDictionary)?["country"] as? String {
            curYelp.country = country   }
        if let distance = (arrayValue[i] as? NSDictionary)?["distance"] as? Double {
            curYelp.distance = distance }
        if let categories = (arrayValue[i] as? NSDictionary)?["categories"] as? NSArray {
            var categoryList = [String]()
            for i in 0..<categories.count {
                if let category = categories[i] as? NSDictionary {
                    if let cat = category["title"] as? String {
                        categoryList.append(cat)
                    }
                }
            }
            curYelp.categories = categoryList
        }

        // phone // address match field // categories
        curYelp.address = "\(curYelp.address1) \(curYelp.city) \(curYelp.state) \(curYelp.zip) \(curYelp.country)"
        
        yelpBusinesses.append(curYelp)
        // print("\(i) Yelp func: \(curYelp.name) \(curYelp.yelpId) \(curYelp.URL) \(curYelp.address) \(curYelp.distance ?? 0)")
        // load an array of places that will be traversed?
    }
    return yelpBusinesses
}

// HERE
func printHereItem (arrayValue: NSArray) -> [hereItem]{
    var hereItems = [hereItem]()
    for i in 0..<arrayValue.count {
        var curHere = hereItem()
        curHere.arrayPosition = i
        if let hereId = (arrayValue[i] as? NSDictionary)?["id"] as? String {
            curHere.hereId = hereId
        }
        if let latitude = ((arrayValue[i] as? NSDictionary)?["position"] as? NSArray)?[0] as? Double {
            curHere.lat = latitude
        }
        if let longitude = ((arrayValue[i] as? NSDictionary)?["position"] as? NSArray)?[1] as? Double {
            curHere.lon = longitude
        }
        if let title = (arrayValue[i] as? NSDictionary)?["title"] as? String {
            curHere.title = title
        }
        if let icon = (arrayValue[i] as? NSDictionary)?["icon"] as? String {
            curHere.iconUrl = icon
        }
        if let vicinity = (arrayValue[i] as? NSDictionary)?["vicinity"] as? String {
            curHere.vicinity = vicinity
            let addressLines = vicinity.components(separatedBy: "<br/>")
            curHere.address1 = addressLines[0]
        }
        if let href = (arrayValue[i] as? NSDictionary)?["href"] as? String {
            curHere.href = href
        }
        if let category = ((arrayValue[i] as? NSDictionary)?["category"] as? NSDictionary)?["id"] as? String {
            curHere.category = category
        }
        if let distance = (arrayValue[i] as? NSDictionary)?["distance"] as? Double {
            curHere.distance = distance
        }
        if let alternativeNames = ((arrayValue[i] as? NSDictionary)?["alternativeNames"] as? NSArray) {
            var nameList = [String]()
            for i in 0..<alternativeNames.count {
                if let altName = alternativeNames[i] as? NSDictionary {
                    if let name = altName["name"] as? String {
                        nameList.append(name)
                    }
                }
            }
            curHere.alternativeNames = nameList
        }
        
        // address has a <br>, parse it out? 231 Franklin St<br/>San Francisco, CA 94102
        // Alternate names //Categories
        hereItems.append(curHere)

        // print("\(curHere.title) \(curHere.lat ?? 0) \(curHere.lon ?? 0) \(curHere.category) \(curHere.hereId)")
        // print("\(curHere.distance ?? 0)")
    }
    return hereItems
}

// TEST and DEBUGGING
func getHereTest(latitude: Double, longitude: Double) {
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
func getYelpTest(latitude: Double, longitude: Double) {
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
                            var yelpBusinesses = [yelpBusinessSearch]()
                            yelpBusinesses = parseYelpBusinessesArray(arrayValue: places)
                            print("Count is \(yelpBusinesses.count)")
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
var hereAPIHtml = """
https://places.cit.api.here.com/places/v1/autosuggest
?at=40.74917,-73.98529
&q=chrysler
&app_id=u0kMh9pqRbVbIRoRUDUR
&app_code=Sm_Nj0Z8V4_Ac-azowbweQ
"""
/* MEMORY QUEUES
 1.0 If you can't Log On then
 2.0 Read Available Blips
 3.0 Get Details for selected Blip
 4.0 Read current location
 5.0 Reverse GeoCode locatoin
 6.0 Get jpg of map location
 7.0 Edit Blip information (description), (file add)
 8.0 Get nearbye locations from yelp
 8.1 Get Apple locatoions from search
 8.2 Get image from location image metadata
 */

/*
When I come back from selecting a yelp place I get use their image as icon for place file type
When ever text is read, evaluate if there is a url... ask if they want to add te URL.  Only ask once
Put a 3 circles buton at the bottom right of the text box, on tap make the text full box screen and scrollable with DONE to go back
/*

/*
 yelp and here are blipdropper S$etupu4
 Client ID Yelp
 7OyP1OAh76FSPkKVRnoC2w
 
 API Key Yelp
 aeLA0m0U9cqOFqgN3CHVOQ_UaJDlB6DCysj23z-woyfmA4Mxf_nMjYO_clogiXE44VF06VohQBO0k-3TFJbEUWqxWr7fJmZJLTz2ojSmljIqsDBCfODqYTKgyK6OW3Yx

 App name
 Blip dropper 00

 Here and get request entrypoints get same data?
//https://places.cit.api.here.com/places/v1/discover/around?at=40.74917%2C-73.98529&Accept-Language=en-us%2Cen%3Bq%3D0.9&app_id=u0kMh9pqRbVbIRoRUDUR&app_code=Sm_Nj0Z8V4_Ac-azowbweQ
//https://places.cit.api.here.com/places/v1/discover/around?at=37.776169%2C-122.421267&Accept-Language=en-us%2Cen%3Bq%3D0.9&app_id=u0kMh9pqRbVbIRoRUDUR&app_code=Sm_Nj0Z8V4_Ac-azowbweQ
//https://places.cit.api.here.com/places/v1/discover/here?at=37.776169%2C-122.421267&Accept-Language=en-us%2Cen%3Bq%3D0.9&app_id=u0kMh9pqRbVbIRoRUDUR&app_code=Sm_Nj0Z8V4_Ac-azowbweQ
//https://places.cit.api.here.com/places/v1/discover/here?app_id=u0kMh9pqRbVbIRoRUDUR&app_code=Sm_Nj0Z8V4_Ac-azowbweQ&at=37.776169%2C-122.421267&pretty
*/

// debug that prints out the message and TS
// ----------------------------------------
// Bugs and stories
/*
 - clean up Post/File data (add placeTime for file create, placetime for manually set)
 - change time by selecting an image’s data
 - tap on photo... see in zoom and scroll view
 - bug where add has dup photo for a second while uploading
 - resort the array after changing blip time
 - establish server placemark data type instead of reverse geocoding every time
 - tap loads the collection cell image
 - add a camera button
 - How will user pick a different icon photo... how to manage file metadata and options
 - Differenitate file that image has a time/place somehow, store in DB
 - how do you lay out the collection view so it ain't uggo
 - Play with a swiping gesture... even just recording and printing would be cool... tinder lesson
 - Should detect if any of the changeable things changed instead of always posting
 
 /*
 let lpgr : UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: "handleLongPress:")
 lpgr.minimumPressDuration = 0.5
 lpgr.delegate = self
 lpgr.delaysTouchesBegan = true
 self.collectionView?.addGestureRecognizer(lpgr)
 */
 //  -- Get image and parse exif from URL approachvself.setExiffrom(url: URL(string: "https://image.ibb.co/jh9Y8K/IMG_0633.jpg"))
 //self.textView.text  = self.exif?.gps?.getFormattedString(valueSeperator: " = ", lineSeperator: "")
 //print("Dt=\("\(self.exif?.gps?.dateStamp ?? "") \(self.exif?.gps?.timeStamp ?? "") \(self.exif?.gps?.timeZoneAbbreviation ?? "")")")

 //- bug where add has dup photo for a second while uploading
 //- change time by selecting an image’s data
 //- resort the array
 //- tap loads the collection cell image
 //- add a camera button
 //  Play with letting user chnage icon photo
 //  Indicate if the image has a time/place somehow, store in DB
 //  Change the pick new blip date/time buttons
 //  tap on photo... see in scroll view
 //  how do you lay out the collection view so it ain't uggo
 //  Play with a swiping gesture... even just recording and printing would be cool... tinder lesson
 //  Should detect if any of the changeable things changed instead of always posting
 
 // If you post a file before the blip gets its object id the file will be effed... maybe check for nil Blip id and just slow them down with an alert

 // Parameterize reverse geocode
 // create new "Update Blip" function for updating time/location before back
 
 //self.textView.text  = self.exif?.gps?.getFormattedString(valueSeperator: " = ", lineSeperator: "")
 //print("Dt=\("\(self.exif?.gps?.dateStamp ?? "") \(self.exif?.gps?.timeStamp ?? "") \(self.exif?.gps?.timeZoneAbbreviation ?? "")")")
 self.view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
 // what am I doing when I () declare a variable of custom type? var arrayPosition = Int() or var clocation = CLLocation()
 */

/*
BRIAN QUESTIONS

 App getting accepted on app store... what I need to make sure of
 
 Correct way to store images for production
 
 How to handle pulling up on last blip and loading next 5 (destroy old or app takes care of that)
 
 How do I make it secure (HTTPS?)
 
 
 cache images not cool?
 Can I cache data from the API?
 Yes, although with great power comes great responsibility. You may cache Yelp API content for up a maximum of 24 hours. Business ids can be stored indefinitely.
 

*/
/*
 for yelp in self.yelpBusinesses {
 var curBlipPlace = blipPlace()
 curBlipPlace.name = yelp.name
 curBlipPlace.yelpId = yelp.yelpId
 curBlipPlace.distance = yelp.distance
 curBlipPlace.yelpArrayPosition = yelp.arrayPosition
 // loop through the here id, if the name/address match merge the data, and remove from the here array
 self.blipPlaces.append(curBlipPlace)
 }
 for here in self.hereItems {
 var curBlipPlace = blipPlace()
 print("\(here.alternativeNames.count) \(here.title) \(here.lat ?? 0), \(here.lon ?? 0) \(here.distance ?? 0)")
 for i in 0..<here.alternativeNames.count {
 print(here.alternativeNames[i])
 }
 curBlipPlace.name = here.title
 curBlipPlace.yelpId = here.hereId
 curBlipPlace.distance = here.distance
 curBlipPlace.hereArrayPosition = here.arrayPosition
 self.blipPlaces.append(curBlipPlace)
 }
 // Null out the array to toggle
 */
 //                var blipPlaces2 = [blipPlace]()*/*/
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
https://stackoverflow.com/questions/40675640/creating-a-thumbnail-from-uiimage-using-cgimagesourcecreatethumbnailatindex
 
 let imageData = UIImagePNGRepresentation(image)!
 let options = [
 kCGImageSourceCreateThumbnailWithTransform: true,
 kCGImageSourceCreateThumbnailFromImageAlways: true,
 kCGImageSourceThumbnailMaxPixelSize: 300] as CFDictionary
 let source = CGImageSourceCreateWithData(imageData, nil)!
 let imageReference = CGImageSourceCreateThumbnailAtIndex(source, 0, options)!
 let thumbnail = UIImage(cgImage: imageReference)

 */

