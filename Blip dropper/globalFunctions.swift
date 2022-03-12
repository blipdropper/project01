//
//  globalFunctions.swift
//  Blip dropper
//
//  Created by DANIEL PATRIARCA on 12/20/21.
//  Copyright © 2021 DANIEL PATRIARCA. All rights reserved.
//  git token: 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


import Foundation
import UIKit
import Parse
import MapKit

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
// Global Functions For App
func fixMissingBlipFiles (blip: blipData) {
    // Load blip to update
    let query = PFQuery(className: "BlipFile")
    query.whereKey("blip_id", equalTo: blip.blip_id)
    query.order(byDescending: "create_dt") // changed from createdAt... any issue?
    query.findObjectsInBackground(block: { (objects, error) in
        var firstNonMapFile = blipFile()
        var mapFile = blipFile()
        var fileCntr = 0
        var mapCntr = 0
        if objects != nil && error == nil {
            if let blipFiles = objects {
                for blipFile in blipFiles {
                    fileCntr += 1
                    if blipFile["file_type"] as? String == "mapImage" {
                        mapCntr += 1
                        mapFile = returnBlipFileFromDB(dbRow: blipFile)
                    } else if fileCntr == 1 {
                        firstNonMapFile = returnBlipFileFromDB(dbRow: blipFile)
                    }
                }
            }
        } else {
            print(error?.localizedDescription ?? "Maybe no blip \(blip.blip_id)")
        }

        print ("\(blip.blip_id): fileCntr=\(fileCntr) mapCntr=\(mapCntr)")

        // If blip has an image and no thumb create a thumb
        if blip.imageFile != nil && blip.imageThumbFile == nil {
            getBlipImage(blip: blip)
        // If blip has no image set image to non-map if available and map if thats only file
        } else if blip.imageFile == nil && fileCntr > 0 {
            if fileCntr > mapCntr {
                makeBlipFileBlipImage(newBlipIcon: firstNonMapFile)
            } else if mapCntr > 0 {
                makeBlipFileBlipImage(newBlipIcon: mapFile)
            }
        }
        // If you have no Map image for the blip then create a map image from lat/lon and add it as a file
        if mapCntr == 0 {
            print ("    > > Blip: \(blip.blip_id):\(blip.blip_note) has no map")
            getLatLonImageFileForBlip(blip: blip)
        }
    })
}
func getLatLonImageFileForBlip(blip: blipData) {
    // Use the blip lat/lon to get an image for that map area then call function to make that image a blipfile for blip
    if let lat =  blip.blip_lat, let lon = blip.blip_lon {
        let mapSnapshotOptions = MKMapSnapshotOptions()
        // Set the region of the map that is rendered.
        let location = CLLocationCoordinate2DMake(lat, lon)
        let region = MKCoordinateRegionMakeWithDistance(location, 1000, 1000)
        mapSnapshotOptions.region = region
        mapSnapshotOptions.size = CGSize(width: 390, height: 288) // default frame size is: HEIGHT=288.0 and WIDTH=390.0
        mapSnapshotOptions.showsBuildings = true
        mapSnapshotOptions.showsPointsOfInterest = true
        
        let snapShotter = MKMapSnapshotter(options: mapSnapshotOptions)

        snapShotter.start { (snapshot, error) in
            if error == nil {
                print("snapshotter thinks no error on blip:\(blip.blip_id)")
                if let image = snapshot?.image {
                    postBlipLocationFile(mapImage: image, blip: blip)
                } else {
                    print("snapshotter didn't get image for some reason?")
                }
            } else {
                print(error ?? "")
            }
        }
    }
}
func postBlipLocationFile(mapImage: UIImage, blip: blipData) {
    // Insert a new blipFile row for the missing map image using blip create dt
    var newBlipFile = blipFile()
    newBlipFile.file_type = "mapImage"
    newBlipFile.blip_id = blip.blip_id
    newBlipFile.imageUIImage = mapImage

    if let imageData = UIImageJPEGRepresentation(mapImage, 0.1) {
        print("start image encode map to PFFile")
        if let blipFile = PFFileObject(name: "mapImage.jpg", data: imageData as Data) {
            newBlipFile.imageFile = blipFile
            newBlipFile.imageThumbFile = blipFile
            // Really should make a real thumb

            let blipFileRow = PFObject(className: "BlipFile")
            blipFileRow["file_type"] = newBlipFile.file_type
            blipFileRow["blip_id"] = newBlipFile.blip_id
            blipFileRow["imageFile"] = newBlipFile.imageFile
            blipFileRow["imageThumbFile"] = newBlipFile.imageThumbFile
            blipFileRow["create_dt"] = blip.create_dt
            
            blipFileRow.saveInBackground(block: { (success, error) in
                if success {
                    print("Save in bg MapImage File worked for blip: \(blip.blip_id)")
                } else {
                    print(error?.localizedDescription ?? "")
                }
            })
        }
    }
}
func makeBlipFileBlipImage (newBlipIcon: blipFile) {
    print("make object \(newBlipIcon.file_id) the representative for \(newBlipIcon.blip_id)")
    // set the file and the thumb to the blip's main and update it in the loaded blips array too
    let query = PFQuery(className: "BlipPost")
    query.whereKey("user_id", equalTo: PFUser.current()?.objectId ?? "")
    query.getObjectInBackground(withId: newBlipIcon.blip_id) { (blip, error) in
        if blip != nil && error == nil {
            // set the image and thumb then keep everything else
            if newBlipIcon.imageFile != nil {
                blip!["imageFile"] = newBlipIcon.imageFile
            }
            if newBlipIcon.imageThumbFile != nil {
                blip!["imageThumbFile"] = newBlipIcon.imageThumbFile
            }
            blip!.saveInBackground()
        } else {
            print(error?.localizedDescription ?? "")
        }
    }
 }
func getBlipFileImage (file: blipFile) {
    file.imageFile?.getDataInBackground { (data, error) in
        print("attempt to create thumb for blip:\(file.blip_id) file: \(file.file_id)")
        if error != nil {print("Err:\(error?.localizedDescription ?? "")")}
        if let imageData = data {
            if let imageToDisplay = UIImage(data: imageData) {
                saveBlipFileThumb(objectId: file.file_id, image: returnThumbnail(bigImage: imageToDisplay))
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
            print ("done \(objectId)")
        } else {
            print ("ERROR")
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
func getBlipAddrFromLatLon (blip: blipData) {
    // this is only to be used to fill any details about a placemark you didn't originally grab
    var center : CLLocationCoordinate2D = CLLocationCoordinate2D()
    var updatedBlip = blip
    if let lat = blip.blip_lat, let lon = blip.blip_lon {
        let ceo: CLGeocoder = CLGeocoder()
        center.latitude = lat
        center.longitude = lon

        let loc: CLLocation = CLLocation(latitude:center.latitude, longitude: center.longitude)
        ceo.reverseGeocodeLocation(loc, completionHandler: {(placemarks, error) in
            if (error != nil) {
                print("reverse geodcode fail: \(error!.localizedDescription) lat:\(lat)/lon:\(lon) blipAddr:\(blip.blip_addr)")
            }
            if let pm = placemarks?[0] {
                updatedBlip.blip_location = returnLocationFromPlaceMark(pm: pm)
                /*
                print("street #    :", pm.subThoroughfare ?? "")
                print("street      :", pm.thoroughfare ?? "")
                print("neighborhood:", pm.subLocality ?? "")
                print("city        :", pm.locality ?? "")
                print("state       :", pm.administrativeArea ?? "")
                print("county      :", pm.subAdministrativeArea ?? "")
                print("zip code    :", pm.postalCode ?? "")
                print("country     :", pm.country ?? "")
                */
                // what is this areas of interest array! developer.apple.com/documentation/corelocation/clplacemark
                saveBlipDataToDb(blip: updatedBlip)
            }
        })
    } else {print("Error unwrapping lat/lon... Either Lat or Lon is missing on Blip, or no address deets?")}
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
    let nameMatch = false
    let addrMatch = false
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

// ----------------------------------------
// Universal Swift Functions
func returnStringDate (date: Date, dateFormat: String) -> String {
    // www.datetimeformatter.com/how-to-format-date-time-in-swift/
    let dateFormatter = DateFormatter()
    // "E, d MMM yyyy h:mm a" Sun, 26 Dec 2021 12:10 pm
    dateFormatter.dateFormat = "MMM d yyyy h:mma"
    var strDate = dateFormatter.string(from: date)
    strDate = strDate.replacingOccurrences(of: "AM", with: "am")
    strDate = strDate.replacingOccurrences(of: "PM", with: "pm")
 return strDate
}
func returnLocationString (location: blipLocation) -> String {
    var addrTxt = ""
    let addrDelim = " "
    
    //if location.subThoroughfare != "" {
    //    addrTxt += location.subThoroughfare + addrDelim
    //}
    //Number
    if location.thoroughfare != "" {
        addrTxt += location.thoroughfare + addrDelim
    }
    //Street
    if location.locality != "" {
        addrTxt += location.locality + addrDelim
    }
    //City
    //if location.subLocality != "" {
    //    addrTxt += location.subLocality + addrDelim
    //}
    //Neighborhood
    //if location.subAdministrativeArea != "" {
    //    addrTxt += location.subAdministrativeArea + addrDelim
    //}
    //County
    if location.administrativeArea != "" {
        addrTxt += location.administrativeArea + addrDelim
    }
    //State
    //if location.postalCode != "" {
    //    addrTxt += location.postalCode + addrDelim
    //}
    // Zip
    //if location.country != "" {
    //    addrTxt += location.country + addrDelim
    //}
    // Country
    
    return addrTxt
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
func breakOutHeadingFromString(fullString: String, charBreakPoint: Int) -> (heading: String, remainingText: String, breakChar: String) {
    var heading = fullString
    var remainingText = ""
    var breakChar = ""

    // If the Full string has less characters than break point then just return full blurb as heading and blank out 2
    if fullString.count > charBreakPoint {
        // Get N characters out of total char count (hardcoded to 30 can this be dynamic?)
        var prefix = String(fullString.prefix(charBreakPoint))
        // Find the last space in heading so you can continue message there
        let lastSpace = prefix.lastIndex(of: " ") ?? prefix.endIndex
        var breakPoint = lastSpace
        breakChar = " "

        // If there is a /n clip there
        if let newLine = prefix.firstIndex(of: "\n") {
            prefix = String(prefix[..<newLine])
            breakPoint = newLine
            breakChar = "\n"
        }
        // Use the Break Point to split the message in 2
        var breakPointInt: Int = fullString.distance(from: fullString.startIndex, to: breakPoint)
        // if the prefix of string has a eliptical ... then the break point is off by 2 but only in iOS not playgrounds?
        if prefix.contains("…") {
            breakPointInt = breakPointInt - 2
        }
        heading = String(fullString.prefix(breakPointInt))
        remainingText = String(fullString.suffix(fullString.count - breakPointInt - 1))
    }

    return (heading,remainingText,breakChar)
}
// if a string contains any of the characters from a custom set" and not checking for all characters in the custom set.
func check(in string: String, forAnyIn characters: String) -> Bool {
    /* USAGE:
     check(in: "abc", forAnyIn: "A") // false
     check(in: "abc", forAnyIn: "b") // true
     */
    // create one character set
    let customSet = CharacterSet(charactersIn: characters)
    // use the rangeOfCharacter(from: CharacterSet) function
    return string.rangeOfCharacter(from: customSet) != nil
}
func mergeCenterImage (bgImage: UIImage, centerImage: UIImage, scaleFactor: Double, alpha: Double) -> UIImage {
    var returnImage = UIImage()
    // use the max of h/w to create 2 squares in order to calculate proportionality then: areaCenter ( X ) /areaBg = ScaleFactor
    var areaBg: Double
    var areaCenter: Double
    // The larger size is the one that creates the square you are proportioning
    if bgImage.size.height > bgImage.size.width {
        areaBg = bgImage.size.height
    } else {
        areaBg = bgImage.size.width
    }
    if centerImage.size.height > centerImage.size.width {
        areaCenter = centerImage.size.height
    } else {
        areaCenter = centerImage.size.width
    }
    let adjustPct = areaBg/areaCenter * scaleFactor
    let centerPointWidth = centerImage.size.width * adjustPct
    let centerPointHeight = centerImage.size.height * adjustPct
    
    UIGraphicsBeginImageContext(bgImage.size)
    let areaSize = CGRect(x: 0, y: 0, width: bgImage.size.width, height: bgImage.size.height)
    let centerPointAreaSize = CGRect(x: areaSize.width / 2 - centerPointWidth / 2, y: areaSize.height / 2 - centerPointHeight / 2, width: centerPointWidth, height: centerPointHeight)
    bgImage.draw(in: areaSize)
    centerImage.draw(in: centerPointAreaSize, blendMode: .normal, alpha: alpha)
    if let finalImage = UIGraphicsGetImageFromCurrentImageContext() {
        returnImage = finalImage
    }
    UIGraphicsEndImageContext()

    return returnImage
}
func showAlertFromAppDelegate(title: String, message: String){
    var topWindow: UIWindow? = UIWindow(frame: UIScreen.main.bounds)
    topWindow?.rootViewController = UIViewController()
    //topWindow?.windowLevel = UIWindow.Level.alert + 1
    let alert: UIAlertController =  UIAlertController(title: title, message: message, preferredStyle: .alert)
    alert.addAction(UIAlertAction.init(title: "OK", style: .default, handler: { (alertAction) in
        topWindow?.isHidden = true
        topWindow = nil
    }))
    topWindow?.makeKeyAndVisible()
    topWindow?.rootViewController?.present(alert, animated: true, completion:nil)
    // showAlertFromAppDelegate(title: "No Images Returned", message: "Adding that filter wouldn't return any images, please try again")
}
