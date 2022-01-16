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
*/

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
    var blip_location = blipLocation()
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
    var file_location = blipLocation()
    var file_lat: Double?
    var file_lon: Double?
    var create_dt: Date?
    var create_dt_txt = ""
    var create_lat: Double?
    var create_lon: Double?
    var create_addr = ""
    var imageFile: PFFileObject?
    var imageUIImage: UIImage? // This should really be a method not holding image file in memory twice
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
    var thoroughfare = ""
    var subThoroughfare = ""
    var locality = ""
    var subLocality = ""
    var administrativeArea = ""
    var subAdministrativeArea = ""
    var postalCode = ""
    var country = ""
    var strCourse = ""
    var strSpeed = ""
    var strAltitude = ""
    var strAddress = "" // create display permeations for blipMain, blip feed cell, map, etc
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
// Data structure Conversion
func returnBlipPostFromDB (dbRow: PFObject)-> blipData {
    var blipData = blipData()
    blipData.blip_id = (dbRow.objectId!)

    if let blipdate = dbRow["blip_date"] as? Date {
        blipData.blip_dt_txt = returnStringDate(date: blipdate, dateFormat: "")
        blipData.blip_dt = blipdate
    } else {
        print("Error setting date string")
    }
    blipData.create_dt = blipData.blip_dt
    blipData.create_dt_txt = blipData.blip_dt_txt
    blipData.blip_addr = dbRow["blip_address"] as? String ?? ""
    blipData.blip_location.subThoroughfare = dbRow["subThoroughfare"] as? String ?? ""
    blipData.blip_location.thoroughfare = dbRow["thoroughfare"] as? String ?? ""
    blipData.blip_location.subLocality = dbRow["subLocality"] as? String ?? ""
    blipData.blip_location.locality = dbRow["locality"] as? String ?? ""
    blipData.blip_location.subAdministrativeArea = dbRow["subAdministrativeArea"] as? String ?? ""
    blipData.blip_location.administrativeArea = dbRow["administrativeArea"] as? String ?? ""
    blipData.blip_location.postalCode = dbRow["postalCode"] as? String ?? ""
    blipData.blip_location.country = dbRow["country"] as? String ?? ""

    blipData.blip_note = dbRow["blip_msg"] as? String ?? ""
    blipData.imageFile = dbRow["imageFile"] as? PFFileObject
    blipData.imageThumbFile = dbRow["imageThumbFile"] as? PFFileObject
    blipData.blip_lat = dbRow["latitude"] as? Double
    blipData.blip_lon = dbRow["longitude"] as? Double
    if dbRow["yelp_id"] != nil {
        blipData.blip_yelp_id =  dbRow["yelp_id"] as! String }
    if dbRow["here_id"] != nil {
        blipData.blip_here_id =  dbRow["here_id"] as! String }
    if dbRow["place_name"] != nil {
        blipData.place_name = dbRow["place_name"] as! String }
    if dbRow["place_lat"] != nil {
        blipData.place_lat  = dbRow["place_lat"] as? Double }
    if dbRow["place_addr"] != nil {
        blipData.place_addr = dbRow["place_addr"] as! String }
    if dbRow["place_url"] != nil {
        blipData.place_url = dbRow["place_url"] as! String }

    /* ORIGINAL CODE... can delete once know new way not an issue
    if let blipdate = post["blip_date"] as? Date {
        curBlip.blip_dt_txt = returnStringDate(date: blipdate, dateFormat: "")
        curBlip.blip_dt = blipdate
    } else {
        print("Error setting date string")
    }
    curBlip.create_dt = curBlip.blip_dt
    curBlip.create_dt_txt = curBlip.blip_dt_txt
    curBlip.blip_addr = post["blip_address"] as! String
    curBlip.blip_location.subThoroughfare = post["subThoroughfare"] as! String
    curBlip.blip_location.thoroughfare = post["thoroughfare"] as! String
    curBlip.blip_location.subLocality = post["subLocality"] as! String
    curBlip.blip_location.locality = post["locality"] as! String
    curBlip.blip_location.subAdministrativeArea = post["subAdministrativeArea"] as! String
    curBlip.blip_location.administrativeArea = post["administrativeArea"] as! String
    curBlip.blip_location.postalCode = post["postalCode"] as! String
    curBlip.blip_location.country = post["country"] as! String

    curBlip.blip_note = post["blip_msg"] as! String
    curBlip.blip_id = (post.objectId!)
    curBlip.imageFile = post["imageFile"] as? PFFileObject
    curBlip.imageThumbFile = post["imageThumbFile"] as? PFFileObject
    curBlip.blip_lat = post["latitude"] as? Double
    curBlip.blip_lon = post["longitude"] as? Double
    if post["yelp_id"] != nil {
        curBlip.blip_yelp_id =  post["yelp_id"] as! String }
    if post["here_id"] != nil {
        curBlip.blip_here_id =  post["here_id"] as! String }
    if post["place_name"] != nil {
        curBlip.place_name = post["place_name"] as! String }
    if post["place_lat"] != nil {
        curBlip.place_lat  = post["place_lat"] as? Double }
    if post["place_addr"] != nil {
        curBlip.place_addr = post["place_addr"] as! String }
    if post["place_url"] != nil {
        curBlip.place_url = post["place_url"] as! String }
    */

    return blipData
}
func returnBlipFileFromDB (dbRow: PFObject)-> blipFile {
    var blipFile = blipFile()
    blipFile.file_id = (dbRow.objectId!)
    blipFile.file_type = dbRow["file_type"] as? String ?? ""
    blipFile.blip_id = dbRow["blip_id"] as! String
    blipFile.file_dt = dbRow["file_dt"] as? Date
    blipFile.file_dt_txt = dbRow["file_dt_txt"] as? String ?? ""
    blipFile.file_addr = dbRow["file_addr"] as? String ?? ""
    // If a file doesn't have a lat/lon then see if you can pull one from exif?
    blipFile.file_lat = dbRow["latitude"] as? Double
    blipFile.file_lon = dbRow["longitude"] as? Double

    if dbRow["imageFile"] != nil {
        let tempFile = dbRow["imageFile"] as! PFFileObject
        blipFile.imageFile = tempFile

        if dbRow["imageThumbFile"] != nil {
            let tempThumbFile = dbRow["imageThumbFile"] as! PFFileObject
            blipFile.imageThumbFile = tempThumbFile
            }
        }

    return blipFile
}
func saveBlipDataToDb (blip: blipData) {
    let query = PFQuery(className: "BlipPost")
    query.whereKey("user_id", equalTo: PFUser.current()?.objectId ?? "")
    query.getObjectInBackground(withId: blip.blip_id) { (getBlip, error) in
        if let dbBlip = getBlip {
            /* For now just add the address stuff
            if blip.imageFile != nil {
                dbBlip["imageFile"] = blip.imageFile
            }
            if blip.imageThumbFile != nil {
                dbBlip["imageThumbFile"] = blip.imageThumbFile
            }
            dbBlip["blip_msg"] = blip.blip_note
            dbBlip["blip_date"] = blip.blip_dt
            // HOW ARE YOU GOING TO GET THE TZ SECONDS FROM EXIF?  HOW IS THIS USED
            //dbBlip["TZOffset_seconds"] = blip.blip_tz_secs
            dbBlip["blip_address"] = blip.blip_addr
            dbBlip["latitude"] = blip.blip_lat
            dbBlip["longitude"] = blip.blip_lon
            dbBlip["yelp_id"] = blip.blip_yelp_id
            dbBlip["here_id"] = blip.blip_here_id
            dbBlip["place_name"] = blip.place_name
            if blip.place_lat != nil {
                dbBlip["place_lat"] = blip.place_lat }
            if blip.place_lon != nil {
                dbBlip["place_lon"] = blip.place_lon }
            dbBlip["place_addr"] = blip.place_addr
            dbBlip["place_url"] = blip.place_url
            */
            dbBlip["subThoroughfare"] = blip.blip_location.subThoroughfare
            dbBlip["thoroughfare"] = blip.blip_location.thoroughfare
            dbBlip["subLocality"] = blip.blip_location.subLocality
            dbBlip["locality"] = blip.blip_location.locality
            dbBlip["subAdministrativeArea"] = blip.blip_location.subAdministrativeArea
            dbBlip["administrativeArea"] = blip.blip_location.administrativeArea
            dbBlip["postalCode"] = blip.blip_location.postalCode
            dbBlip["country"] = blip.blip_location.country

            dbBlip.saveInBackground()
            
            print("SAVED: \(blip.blip_location.strAddress)")
        } else {
            print(error?.localizedDescription ?? "")
        }
    }
}
func returnLocationFromPlaceMark (pm: CLPlacemark)-> blipLocation {
    var pmLocation = blipLocation()
    let addrDelim = " "
    pmLocation.subThoroughfare = pm.subThoroughfare ?? ""
    pmLocation.thoroughfare = pm.thoroughfare ?? ""
    pmLocation.subLocality = pm.subLocality ?? ""
    pmLocation.locality = pm.locality ?? ""
    pmLocation.subAdministrativeArea = pm.subAdministrativeArea ?? ""
    pmLocation.administrativeArea = pm.administrativeArea ?? ""
    pmLocation.postalCode = pm.postalCode ?? ""
    pmLocation.country = pm.country ?? ""
    // pmLocation.strAltitude = pm.location?.altitude ... needs to be text
    
    if pmLocation.subThoroughfare != "" {
        pmLocation.strAddress += pmLocation.subThoroughfare + addrDelim
    }//Number
    if pmLocation.thoroughfare != "" {
        pmLocation.strAddress += pmLocation.thoroughfare + addrDelim
    }//Street
    if pmLocation.locality != "" {
        pmLocation.strAddress += pmLocation.locality + addrDelim
    }//City
    //if pmLocation.subLocality != "" {
    //    pmLocation.strAddress += pmLocation.subLocality + addrDelim
    //}
    //Neighborhood
    //if pmLocation.subAdministrativeArea != "" {
    //    pmLocation.strAddress += pmLocation.subAdministrativeArea + addrDelim
    //}
    //County
    if pmLocation.administrativeArea != "" {
        pmLocation.strAddress += pmLocation.administrativeArea + addrDelim
    }//State
    if pmLocation.postalCode != "" {
        pmLocation.strAddress += pmLocation.postalCode + addrDelim
    }// Zip
    //if pmLocation.country != "" {
    //    pmLocation.strAddress += pmLocation.country + addrDelim
    //}
    // Country

    return pmLocation
}

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

