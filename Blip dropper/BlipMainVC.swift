//
//  BlipMainVC.swift
//  Blip dropper
//
//  Created by DANIEL PATRIARCA on 8/31/18.
//  Copyright © 2018 DANIEL PATRIARCA. All rights reserved.
//
// Started playing with default text... need to ensure that you Paceholder/Empty toggles and you know when to post to Parse

import UIKit
import MapKit
import CoreLocation
import AVFoundation
import Photos
import Parse

class BlipMainVC: UIViewController, CLLocationManagerDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UITextViewDelegate, UIScrollViewDelegate {
    // ----------------------------------------
    // IBOUTLETS, ACTIONS, and variables
    private let imagePicker = UIImagePickerController()
    var blipObjectid = ""
    var choosenImage: UIImage?
    var mapImage: UIImage?
    var locationManager = CLLocationManager()
    var currLocation = CLLocation()
    var currDateStamp = Date()
    var location = blipLocation()
    var blipFiles = [blipFile]()
    var locationSet = false
    var snapshotRan = "initialized"
    var newBlipMode = false
    var PhotoMode = false
    var txtIsPlaceHolder = false
    var initialActionComplete = false
    let addrDelim = " "
    var placeHolderText = "Enter some details about your Blip!"
    var blipMode = "photo"
    var exif: Exif?

    // Delete???
    @IBOutlet weak var pickBlipDate: UIButton!
    // ---------
    @IBOutlet weak var scroller: UIScrollView!
    @IBOutlet weak var zoomImage: UIImageView!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var blipDate: UIButton!
    @IBOutlet weak var blipPlace: UIButton!
    @IBOutlet weak var blipChoosePlace: UIButton!
    @IBOutlet weak var blipAddPhoto: UIButton!
    @IBOutlet weak var blipOpenCamera: UIButton!
    @IBOutlet weak var blipSave: UIButton!
    @IBOutlet weak var blipFileCollectionView: UICollectionView!

    @IBAction func pickPlace(_ sender: Any) {
        curBlip.mode = ""
        if curBlip.blip_yelp_id != "" || curBlip.blip_here_id != "" {
            self.performSegue(withIdentifier: "showPlacePicker", sender: self)
        } else {
            self.performSegue(withIdentifier: "showPlacePicker", sender: self)
        }
    }
    @IBAction func actionOpenCamera(_ sender: Any) {
        askCameraPermission()
    }
    @IBAction func actionOpenPhonto(_ sender: UIButton) {
        // actionOpenPhoto(sender)
        checkPhotoLibraryPermission()
    }
    @IBAction func pickBlipDate(_ sender: Any) {
        print("Clicked Pick BlipDate")
    }
    @IBAction func pickBlipPlace(_ sender: Any) {
        print("Clicked Pick BlipPlace")
        self.performSegue(withIdentifier: "showPlaceTimePicker", sender: self)
    }

    // ----------------------------------------
    // SAVE BLIP
    @IBAction func dismissVC(_ sender: Any) {
        // update current blip, loaded blips, and server with new data
        saveBlipChanges()
        self.dismiss(animated: true, completion: nil)
    }
    func saveBlipChanges () {
        if !txtIsPlaceHolder {
            curBlip.blip_note = self.textView.text
        }
        let query = PFQuery(className: "BlipPost")
        query.whereKey("user_id", equalTo: PFUser.current()?.objectId ?? "")
        query.getObjectInBackground(withId: curBlip.blip_id) { (blip, error) in
            if blip != nil && error == nil {
                if curBlip.imageFile != nil {
                    blip!["imageFile"] = curBlip.imageFile
                }
                if curBlip.imageThumbFile != nil {
                    blip!["imageThumbFile"] = curBlip.imageThumbFile
                }
                blip!["blip_msg"] = curBlip.blip_note
                blip!["blip_date"] = curBlip.blip_dt
                // HOW ARE YOU GOING TO GET THE TZ SECONDS FROM EXIF?  HOW IS THIS USED
                //blip!["TZOffset_seconds"] = curBlip.blip_tz_secs
                blip!["blip_address"] = curBlip.blip_addr
                blip!["latitude"] = curBlip.blip_lat
                blip!["longitude"] = curBlip.blip_lon
                blip!["yelp_id"] = curBlip.blip_yelp_id
                blip!["here_id"] = curBlip.blip_here_id
                blip!["place_name"] = curBlip.place_name
                if curBlip.place_lat != nil {
                    blip!["place_lat"] = curBlip.place_lat }
                if curBlip.place_lon != nil {
                    blip!["place_lon"] = curBlip.place_lon }
                blip!["place_addr"] = curBlip.place_addr
                blip!["place_url"] = curBlip.place_url
                blip!.saveInBackground()
            } else {
                print(error?.localizedDescription ?? "")
            }
        }
        loadedBlips[curBlip.arrayPosition].blip_note = curBlip.blip_note
        loadedBlips[curBlip.arrayPosition].imageFile = curBlip.imageFile
        loadedBlips[curBlip.arrayPosition].imageThumbFile = curBlip.imageThumbFile
        loadedBlips[curBlip.arrayPosition].imageUIImage = curBlip.imageUIImage
        loadedBlips[curBlip.arrayPosition].blip_dt = curBlip.blip_dt
        //loadedBlips[curBlip.arrayPosition].blip_tz_secs = curBlip.blip_tz_secs
        loadedBlips[curBlip.arrayPosition].blip_dt_txt = curBlip.blip_dt_txt
        loadedBlips[curBlip.arrayPosition].blip_lat = curBlip.blip_lat
        loadedBlips[curBlip.arrayPosition].blip_lon = curBlip.blip_lon
        loadedBlips[curBlip.arrayPosition].blip_addr = curBlip.blip_addr
        loadedBlips[curBlip.arrayPosition].blip_yelp_id = curBlip.blip_yelp_id
        loadedBlips[curBlip.arrayPosition].blip_here_id = curBlip.blip_here_id
        loadedBlips[curBlip.arrayPosition].place_name = curBlip.place_name
        loadedBlips[curBlip.arrayPosition].place_lat = curBlip.place_lat
        loadedBlips[curBlip.arrayPosition].place_lon = curBlip.place_lon
        loadedBlips[curBlip.arrayPosition].place_addr = curBlip.place_addr
        loadedBlips[curBlip.arrayPosition].place_url = curBlip.place_url
        loadedBlips[curBlip.arrayPosition].place  = curBlip.place

        //found nil wile unwrapping an optional after hitting place off of new no pic blip
        loadedBlips.sort(by: { $0.blip_dt?.compare(($1.blip_dt)!) == .orderedDescending }) // newest to oldest
    }

    // ----------------------------------------
    // POST FILE
    func postLocationFile(mapImage: UIImage) {
        // Check Blip id set
        if curBlip.blip_id == "" {
            print("blip_id is nil pal")
        } else if snapshotRan != "done" {
            print("snapshot image wasn't set yet")
        } else {
            print("blip_id = \(curBlip.blip_id) for file")
        }
        var newBlipFile = blipFile()
        newBlipFile.file_type = "mapImage"
        newBlipFile.blip_id = curBlip.blip_id
        newBlipFile.imageUIImage = mapImage

        if let imageData = UIImageJPEGRepresentation(mapImage, 0.1) {
            print("start image encode map to PFFile")
            if let blipFile = PFFileObject(name: "mapImage.jpg", data: imageData as Data) {
                newBlipFile.imageFile = blipFile
                newBlipFile.imageThumbFile = blipFile
                // SET curBlip images if this is first file
                if curBlip.fileCount == 0 {
                    curBlip.imageFile = blipFile
                    curBlip.imageThumbFile = blipFile
                    curBlip.imageUIImage = newBlipFile.imageUIImage
                }
            }
            print("done image encode to PFFile")
        }
        // Post to Server
        let blipFileRow = PFObject(className: "BlipFile")
        blipFileRow["file_type"] = newBlipFile.file_type
        blipFileRow["blip_id"] = newBlipFile.blip_id
        blipFileRow["imageFile"] = newBlipFile.imageFile
        blipFileRow["imageThumbFile"] = newBlipFile.imageThumbFile
        blipFileRow["create_dt"] = curBlip.create_dt
        blipFileRow.saveInBackground(block: { (success, error) in
            if success {
                print("Save in bg MapImage File worked")
            } else {
                print(error?.localizedDescription ?? "")
            }
        })
        // Append to Blip File array
        blipFiles.append(newBlipFile)
        curBlip.fileCount = blipFiles.count
        print("start collection reload filecount:\(curBlip.fileCount)")
        self.blipFileCollectionView.reloadData()
        print("done collection reload")
    }
    func postFile(fileType: String) {
    // Image... get lat/lon/date
        var exifDateOk = false
        var exifPlaceOk = false
        if curBlip.blip_id == "" {
            print("blip_id is nil pal")
        } else {
            print("blip_id = \(curBlip.blip_id) for file")
        }

        // Populate Blip File Struct
        var newBlipFile = blipFile()
        newBlipFile.imageUIImage = choosenImage
        newBlipFile.file_lat = (self.exif?.gps?.latitude)
        newBlipFile.file_lon = (self.exif?.gps?.longitude)
        newBlipFile.blip_id = curBlip.blip_id
        newBlipFile.create_dt = Date()
        newBlipFile.create_dt_txt = time2String(time: newBlipFile.create_dt!)
        // Encode the image
        if let imageData = UIImageJPEGRepresentation(self.choosenImage!, 0.1) {
            print("start image encode to PFFile")
            if let blipFile = PFFileObject(name: "image.jpg", data: imageData as Data) {
                newBlipFile.imageFile = blipFile
                newBlipFile.imageThumbFile = blipFile
                // SET curBlip images if this is first file
                if curBlip.fileCount <= 1 {
                    curBlip.imageFile = blipFile
                    curBlip.imageUIImage = newBlipFile.imageUIImage
                    curBlip.imageThumbFile = blipFile
                }
            }
            print("done image encode to PFFile")
        }
        // Set the Date from the image EXIF if not nil dt, ts, and tz
        if self.exif?.gps?.dateStamp != nil && self.exif?.gps?.timeStamp != nil && self.exif?.gps?.timeZoneAbbreviation != nil {
            let fullDate = "\(self.exif?.gps?.dateStamp ?? "") \(self.exif?.gps?.timeStamp ?? "") \(self.exif?.gps?.timeZoneAbbreviation ?? "")"
            print("full Date is: \(fullDate)")
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy:MM:dd HH:mm:ss zzz"
            let dateFromString = dateFormatter.date(from: fullDate)
            newBlipFile.file_dt = dateFromString
            if newBlipFile.file_dt != nil {
                exifDateOk = true
                newBlipFile.file_dt_txt  = time2String(time: newBlipFile.file_dt!)
            }
        } else {
            print("The dateStamp didn't set")
        }
        // Set Reverse Geo Code and write to server after
        if let lat: CLLocationDegrees = newBlipFile.file_lat, let lon: CLLocationDegrees = newBlipFile.file_lon {
            exifPlaceOk = true
            let LatLonLocation = CLLocation(latitude: lat, longitude: lon)
            CLGeocoder().reverseGeocodeLocation(LatLonLocation) { (placemarks, error) in
                if error != nil {
                    print(error!)
                } else {
                    if let placemark = placemarks?[0] {
                        if placemark.subThoroughfare != nil {
                            newBlipFile.file_addr += placemark.subThoroughfare! + " "
                            self.location.subThoroughfare = placemark.subThoroughfare!
                        }
                        if placemark.thoroughfare != nil {
                            newBlipFile.file_addr += placemark.thoroughfare! + self.addrDelim
                            self.location.thoroughfare = placemark.thoroughfare!
                        }
                        if placemark.subLocality != nil {
                            newBlipFile.file_addr += placemark.subLocality! + self.addrDelim
                            self.location.subLocality = placemark.subLocality!
                        }
                        if placemark.subAdministrativeArea != nil {
                            newBlipFile.file_addr += placemark.administrativeArea! + self.addrDelim
                            self.location.subAdministrativeArea = placemark.administrativeArea!
                        }
                        if placemark.postalCode != nil {
                            newBlipFile.file_addr += placemark.postalCode! + self.addrDelim
                            self.location.postalCode = placemark.postalCode!
                        }
                        if placemark.country != nil {
                            newBlipFile.file_addr += placemark.country! + self.addrDelim
                            self.location.country = placemark.country!
                        }
                        self.location.strAddress = newBlipFile.file_addr
                        print(self.location.strAddress)
                        
                        // Save Blip Row WITH Metadata
                        let blipFileRow = PFObject(className: "BlipFile")
                        blipFileRow["blip_id"] = newBlipFile.blip_id
                        blipFileRow["imageFile"] = newBlipFile.imageFile
                        blipFileRow["imageThumbFile"] = newBlipFile.imageThumbFile
                        blipFileRow["create_dt"] = newBlipFile.create_dt
                        blipFileRow["latitude"] = newBlipFile.file_lat
                        blipFileRow["longitude"] = newBlipFile.file_lon
                        blipFileRow["file_addr"] = newBlipFile.file_addr
                        if exifDateOk {
                            blipFileRow["file_dt"] = newBlipFile.file_dt
                            blipFileRow["file_dt_txt"] = newBlipFile.file_dt_txt
                        }
                        
                        // Set the PlaceTime for Blip if first PhotoMode image initial PostFile completed which declares blip
                        if self.PhotoMode && !self.initialActionComplete {
                            self.blipPlace.setTitle(substr(stringValue: newBlipFile.file_addr, forInt: 30), for: [])
                            curBlip.blip_lat = newBlipFile.file_lat
                            curBlip.blip_lon = newBlipFile.file_lon
                            curBlip.blip_addr = newBlipFile.file_addr
                            
                            if exifDateOk {
                                self.blipDate.setTitle(newBlipFile.file_dt_txt, for: [])
                                
                                curBlip.blip_dt = newBlipFile.file_dt
                                curBlip.blip_dt_txt  = newBlipFile.file_dt_txt
                            }
                            // change the blip placeTime
                            // move the blip from position 0 in the array to a sort of where it should be
                        }
                        blipFileRow.saveInBackground(block: { (success, error) in
                            if success {
                                print("Save in bg worked")
                            } else {
                                print(error?.localizedDescription ?? "")
                            }
                        })
                        self.initialActionComplete = true
                    }
                }
            }
        } else {
            // Save Blip Row NO location metadata
            print("The Lat lon didn't read")
            let blipFileRow = PFObject(className: "BlipFile")
            blipFileRow["blip_id"] = newBlipFile.blip_id
            blipFileRow["imageFile"] = newBlipFile.imageFile
            blipFileRow["imageThumbFile"] = newBlipFile.imageThumbFile
            blipFileRow["create_dt"] = newBlipFile.create_dt
            blipFileRow.saveInBackground(block: { (success, error) in
                if success {
                    print("Save in bg no metadata worked")
                } else {
                    print(error?.localizedDescription ?? "")
                }
            })
            
            if self.PhotoMode && !self.initialActionComplete{
                print("Set curBlip to placetime if this was first post")
            }

            initialActionComplete = true
        }
        
        // Append to Blip File array
        blipFiles.append(newBlipFile)
        curBlip.fileCount = blipFiles.count
        print("start collection reload filecount:\(curBlip.fileCount)")
        self.blipFileCollectionView.reloadData()
        print("done collection reload")
    }
    func actionOpenPhoto (_ sender: UIButton) {
        let alertController = UIAlertController.init(title: "Choose Photo", message: "Choose Photo From", preferredStyle: .actionSheet)
        let photo = UIAlertAction.init(title: "Photo Library", style: .default, handler: { (action) in
            self.checkPhotoLibraryPermission()
        })
        
        let camera = UIAlertAction.init(title: "Camera", style: .default, handler: { (action) in
            self.askCameraPermission()
        })
        
        if let presenter = alertController.popoverPresentationController {
            presenter.sourceView = sender
            presenter.sourceRect = sender.bounds
        }
        
        alertController.addAction(photo)
        alertController.addAction(camera)
        self.present(alertController, animated: true, completion: nil)
    }

    // ----------------------------------------
    // EXIF and Photo Picker Functions
    public func setExiffrom(url:URL?){
        if url == nil{
            return
        }
        do {
            let imagedata = try Data.init(contentsOf: url!)
            let source: CGImageSource = CGImageSourceCreateWithData((imagedata as CFData), nil)!
            if let object = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any]{
                self.imageView.image = UIImage(data: imagedata)
                // add to the collection view here?
                print("I just set image view")
                self.exif = Exif(object)
                print("set exif call done")
                //self.textView.text = object.description
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    //-- Photo and Camera Library
    private func askCameraPermission() {
        if UIImagePickerController.isSourceTypeAvailable(.camera) == true {
            if AVCaptureDevice.authorizationStatus(for: AVMediaType.video) ==  AVAuthorizationStatus.authorized {
                self.openCameraPicker()
            } else if AVCaptureDevice.authorizationStatus(for: AVMediaType.video) ==  AVAuthorizationStatus.denied {
                self.showCameraPermissionDialog()
            } else {
                AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: { (granted: Bool) -> Void in
                    if granted == true {
                        self.openCameraPicker()
                    } else {
                        self.showCameraPermissionDialog()
                    }
                })
            }
        } else {
            self.alert("Your device does not have camera!")
        }
    }
    //-- For Photos
    private func checkPhotoLibraryPermission() {
        let status = PHPhotoLibrary.authorizationStatus()
        switch status {
        case .authorized:
            self.openPhotoPicker()
            break
        case .denied, .restricted :
            self.showPhotoPermissionDialog()
            break
        case .notDetermined:
            // ask for permissions
            PHPhotoLibrary.requestAuthorization() { (status) -> Void in
                switch status {
                case .authorized:
                    self.openPhotoPicker()
                    break
                // as above
                case .denied, .restricted:
                    self.showPhotoPermissionDialog()
                    break
                // as above
                case .notDetermined:
                    self.alert("Unexpected error occured for accessing photo library")
                    break
                case .limited:
                    self.openPhotoPicker()
                    break
                }
            }
        case .limited:
            self.openPhotoPicker()
            break
        }
    }
    private func alert(_ message:String){
        let controller = UIAlertController.init(title: "Choose Image", message: message, preferredStyle: .alert)
        let actionCancel = UIAlertAction.init(title: "Ok", style: .cancel, handler: nil)
        controller.addAction(actionCancel)
        self.present(controller, animated: true, completion: nil)
    }
    private func showPhotoPermissionDialog(){
        self.alert("Go to settings and grant permission for photos access")
    }
    private func openPhotoPicker(){
        self.imagePicker.sourceType = .photoLibrary
        self.imagePicker.allowsEditing = false
        self.present(self.imagePicker, animated: true, completion: nil)
    }
    private func openCameraPicker(){
        self.imagePicker.sourceType = .camera
        self.imagePicker.allowsEditing = false
        self.present(self.imagePicker, animated: true, completion: nil)
    }
    private func showCameraPermissionDialog(){
        self.alert("")
    }
    
    // ----------------------------------------
    // LOCATION MANAGER for initial Spot
    func setBlipLocationImage(latitude: Double, longitude: Double, mode: String) {
        print("start snapshotter")
        snapshotRan = "started"

        let mapSnapshotOptions = MKMapSnapshotOptions()
        // Set the region of the map that is rendered.
        let location = CLLocationCoordinate2DMake(latitude, longitude)
        let region = MKCoordinateRegionMakeWithDistance(location, 1000, 1000)
        mapSnapshotOptions.region = region
        // Set the size of the image output.
        mapSnapshotOptions.size = imageView.frame.size
        
        // Show buildings and Points of Interest on the snapshot
        mapSnapshotOptions.showsBuildings = true
        mapSnapshotOptions.showsPointsOfInterest = true
        
        let snapShotter = MKMapSnapshotter(options: mapSnapshotOptions)

        snapShotter.start { (snapshot, error) in
            if error == nil {
                print("snapshotter thinks no error")
                if let image = snapshot?.image {
                    self.mapImage = image
                    self.imageView.image = image
                    self.snapshotRan = "done"
                    print("snapshotter thinks image set")
                    if mode == "postfile" {
                        self.postLocationFile(mapImage: image)
                    }
                } else {
                    print("snapshotter didn't get image for some reason?")
                }
            } else {
                print(error ?? "")
            }
        }
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let userLocation: CLLocation = locations[0]
        currLocation = userLocation
        let latitude = userLocation.coordinate.latitude
        let longitude = userLocation.coordinate.longitude
        if snapshotRan == "initialized" {
            setBlipLocationImage(latitude: latitude, longitude: longitude, mode: "nopost")
        }
        location.lat = latitude
        location.lon = longitude
        location.strLatitude = String(format: "%.8f", latitude)
        location.strLongitude = String(format: "%.8f", longitude)
        location.strCourse = String(userLocation.course)
        location.strSpeed = String(userLocation.speed)
        location.strAltitude = String(userLocation.altitude)
        location.strLatLon = location.strLatitude + ", " + location.strLongitude
        
        // Reverse Geo Code for addr
        CLGeocoder().reverseGeocodeLocation(userLocation) { (placemarks, error) in
            if error != nil {
                print(error!)
            } else {
                if let placemark = placemarks?[0] {
                    var address = ""
                    if placemark.subThoroughfare != nil {
                        address += placemark.subThoroughfare! + " "
                        self.location.subThoroughfare = placemark.subThoroughfare!
                    }
                    if placemark.thoroughfare != nil {
                        address += placemark.thoroughfare! + self.addrDelim
                        self.location.thoroughfare = placemark.thoroughfare!
                    }
                    if placemark.subLocality != nil {
                        address += placemark.subLocality! + self.addrDelim
                        self.location.subLocality = placemark.subLocality!
                    }
                    if placemark.subAdministrativeArea != nil {
                        address += placemark.subAdministrativeArea! + self.addrDelim
                        self.location.subAdministrativeArea = placemark.subAdministrativeArea!
                    }
                    if placemark.postalCode != nil {
                        address += placemark.postalCode! + self.addrDelim
                        self.location.postalCode = placemark.postalCode!
                    }
                    if placemark.country != nil {
                        address += placemark.country! + self.addrDelim
                        self.location.country = placemark.country!
                    }
                    self.location.strAddress = address

                    print(self.location.strAddress)

                    if !self.locationSet {
                        print("start posting")
                        self.postInitialBlip()
                        // if snapshot done then post image as file because you have the image already
                        self.locationSet = true
                    } else {
                        print("location already set")
                    }
                }
            }
        }
        // Stop updating location to save battery
        locationManager.stopUpdatingLocation()
    }
    func postInitialBlip() {
        var secondsFromGMT: Int { return TimeZone.current.secondsFromGMT() }

        curBlip.blip_status = "new"
        curBlip.user_id = PFUser.current()?.objectId ?? ""
        curBlip.blip_dt = Date()
        curBlip.blip_dt_txt = time2String(time: curBlip.blip_dt!)
        curBlip.blip_lat = location.lat
        curBlip.blip_lon = location.lon
        curBlip.blip_addr = location.strAddress
        curBlip.blip_tz_secs = secondsFromGMT
        curBlip.create_dt = curBlip.blip_dt
        curBlip.create_dt_txt = curBlip.blip_dt_txt
        curBlip.create_lat = location.lat
        curBlip.create_lon = location.lon
        curBlip.create_addr = location.strAddress
        curBlip.create_tz_secs = secondsFromGMT
        curBlip.isPublic = false
        
        let post = PFObject(className: "BlipPost")
        // need struct2Parse() function
        post["user_id"] = curBlip.user_id
        post["blip_msg"] = curBlip.blip_note
        post["blip_date"] = curBlip.blip_dt
        post["TZOffset_seconds"] = curBlip.blip_tz_secs
        post["blip_address"] = curBlip.blip_addr
        post["latitude"] = curBlip.blip_lat
        post["longitude"] = curBlip.blip_lon
        post["blip_status"] = curBlip.blip_status
        post["IsPublic"] = curBlip.isPublic
  
        post.saveInBackground { (success, error) in
            if success {
                print("Blip instantiated, location set = \(self.locationSet)")
                curBlip.blip_id = post.objectId!
                loadedBlips.insert(curBlip, at: 0)
                if self.snapshotRan == "done" {
                    if let image = self.mapImage {
                        self.postLocationFile(mapImage: image)
                    }
                } else {
                    // if snapshot didn't finish then run it again abut this time do the post at the end
                    if let lat = curBlip.blip_lat, let lon = curBlip.blip_lon {
                        self.setBlipLocationImage(latitude: lat, longitude: lon, mode: "postfile")
                    }
                }
            } else {
                print("\(error?.localizedDescription ?? "")")
            }
        }
        
        blipDate.setTitle(curBlip.blip_dt_txt, for: [])
        blipPlace.setTitle(substr(stringValue: curBlip.blip_addr, forInt: 30), for: [])
        
        if PhotoMode {
            checkPhotoLibraryPermission()
            print("Why didn't this work \(PhotoMode)")
        }
    }
    // ----------------------------------------
    // COLLECTION VIEW FUNCTIONS
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return blipFiles.count
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell:BlipMainCell = collectionView.dequeueReusableCell(withReuseIdentifier: "fileCell", for: indexPath) as! BlipMainCell
        cell.curBlipFile = blipFiles[indexPath.row]

        if blipFiles[indexPath.row].imageUIImage == nil {
            // Get the image from the image data
            blipFiles[indexPath.row].imageFile?.getDataInBackground { (data, error) in
                if let imageData = data {
                    if let imageToDisplay = UIImage(data: imageData) {
                        cell.image.image = imageToDisplay
                    }
                }
            }
        } else {
            cell.image.image = blipFiles[indexPath.row].imageUIImage
        }
        
        if blipFiles[indexPath.row].file_type == "mapImage" {
            print ("map image YES")
            cell.cellLabel.text = curBlip.place_name
        } else {
            print ("map image NO")
            cell.cellLabel.text = ""
        }
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedCell:BlipMainCell = collectionView.cellForItem(at: indexPath) as! BlipMainCell
        print(selectedCell.curBlipFile.file_type)
        imageView.image = selectedCell.image.image

        var appleMapPin = ""
        // Open and show coordinate
        if curBlip.place_name == "" {
            appleMapPin = "Blip&ll=\(curBlip.blip_lat ?? 0.0),\(curBlip.blip_lon ?? 0.0)"
        } else {
            appleMapPin = "\(curBlip.place_name)"
            appleMapPin = appleMapPin.addingPercentEncoding(withAllowedCharacters: CharacterSet(charactersIn: "!*'();:@&=+$,/?%#[]{} ").inverted) ?? ""
            appleMapPin = "\(appleMapPin)&sll=\(curBlip.blip_lat ?? 0.0),\(curBlip.blip_lon ?? 0.0)"
        }
        print(appleMapPin)
        let urlString = "http://maps.apple.com/?q=\(appleMapPin)"
//        let urlString = "http://maps.apple.com/?q=\(appleMapPin)&ll=\(curBlip.blip_lat ?? 0.0),\(curBlip.blip_lon ?? 0.0)"
        print(urlString)
        if let url = URL(string: urlString), selectedCell.curBlipFile.file_type == "mapImage" {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
                //If you want handle the completion block than
                UIApplication.shared.open(url, options: [:], completionHandler: { (success) in
                    print("Open url : \(success)")
                })
            }
        }
    }
    
    // ---------------------------------------- 
    // VIEW DID LOAD
    override func viewDidAppear(_ animated: Bool) {
        print("View Did Apear says \(curBlip.place_name)")
        // reload so that the place information updates the cell
        blipFileCollectionView.reloadData()

        if curBlip.mode == "newPlace", let newBlipPlace = curBlip.place {
            print("Add blipFile for: \(newBlipPlace.name)  \(newBlipPlace.yelp?.imageURL ?? "") " )
            if let strURL = newBlipPlace.yelp?.imageURL {
                let url = URL(string: strURL)
                // Get place image snippet, needs error checking
                /*
                DispatchQueue.global().async {
                    let data = try? Data(contentsOf: url!) //make sure your image in this url does exist, otherwise unwrap in a if let check / try-catch
                    DispatchQueue.main.async {
                        self.imageView.image = UIImage(data: data!)
                    }
                }
                */
                // does this place already exist as a blip file... maybe only keep one and overwrite it
                // turn the url into an image
                // place into blipFile array (position 0) tapping on IT loads a URL instead of full screen image?
            }
        } else {
            print("No new place selected")
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        print("View Did Load says \(curBlip.place_name)")
        scroller.delegate = self
        scroller.maximumZoomScale = 1
        scroller.maximumZoomScale = 4
        scroller.contentSize = zoomImage.frame.size
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(imageTapped))
        tapGesture.numberOfTapsRequired = 1
        imageView.addGestureRecognizer(tapGesture)
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(doubleTapped))
        doubleTap.numberOfTapsRequired = 2
        imageView.addGestureRecognizer(doubleTap)
        imageView.isUserInteractionEnabled = true
        tapGesture.require(toFail: doubleTap)
        let longTapGesture = UILongPressGestureRecognizer (target: self, action: #selector(imageLongTapped))
        longTapGesture.minimumPressDuration = 0.5
        longTapGesture.delaysTouchesBegan = true
        self.imagePicker.delegate = self
        textView.delegate = self
        blipFileCollectionView.delegate = self
        blipFileCollectionView.dataSource = self
        blipFileCollectionView.addGestureRecognizer(longTapGesture)

        print("Photo mode: \(PhotoMode)")

        if curBlip.blip_id  == "" {
            newBlipMode = true
            print("New Blip Mode")
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.requestWhenInUseAuthorization()
            locationManager.startUpdatingLocation()
            // postInitialBlip called from location manager since we need to wait for lat/lon/geo code
            checkPlaceHolderText()
        } else {
            newBlipMode = false
            print("Update Blip Mode: blip \(curBlip.blip_id)")
            updateBlipMode()
            blipFileCollectionView.reloadData()
        }
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
        blipChoosePlace.isUserInteractionEnabled = true
        blipAddPhoto.isUserInteractionEnabled = true
        blipOpenCamera.isUserInteractionEnabled = true
        blipSave.isUserInteractionEnabled = true
        print("Ending touches began")
    }
    func textViewDidChange(_ ttextView: UITextView) {
        //textView(Sender)
        if(ttextView == self.textView)
        {
            print("textView main was used")
        } else {
            print("some other text view was altered?")
        }
        blipAltered()
    }
    func textViewDidEndEditing(_ textView: UITextView) {
        print("Ending editing")
        // checkPlaceHolderText()
    }
    func textViewDidBeginEditing(_ textView: UITextView) {
        if txtIsPlaceHolder {
            textView.text = ""
            textView.textColor = UIColor.black
            txtIsPlaceHolder = false
        }
        blipChoosePlace.isUserInteractionEnabled = false
        blipAddPhoto.isUserInteractionEnabled = false
        blipOpenCamera.isUserInteractionEnabled = false
        blipSave.isUserInteractionEnabled = false
    }
    func blipAltered() {
        blipSave.setTitle("SAVE", for: [])
    }
    
    // ----------------------------------------
    // GESTURE and STUFF
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return zoomImage
    }
    @objc func doubleTapped(_ sender: UITapGestureRecognizer) {
        scroller.setZoomScale(0.0, animated: true)
    }
    @objc func imageLongTapped(_ sender: UITapGestureRecognizer) {
        if (sender.state != UIGestureRecognizerState.ended){
            return
        }
        let p = sender.location(in: blipFileCollectionView)

        // Delete the file if user confirms
        if let indexPath = blipFileCollectionView.indexPathForItem(at: p) {
            let alert = UIAlertController(title: "Delete?", message: "You sure you want delete file?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { action in
                // drop the file from the server
                let file_id = self.blipFiles[indexPath.row].file_id
                print(file_id)
                self.blipFiles.remove(at: indexPath.row)
                self.blipFileCollectionView.reloadData()
                // Delete the blip from the server
                let query = PFQuery(className: "BlipFile")
                query.getObjectInBackground(withId: file_id) { (object, error) in
                    if object != nil && error == nil {
                        object?.deleteInBackground()
                    } else {
                        print("Something went wrong \(error?.localizedDescription ?? "")")
                    }
                }

            }))
            alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
            self.present(alert, animated: true)
        } else {
            print("couldn't find index path")
        }
    }
    @objc func imageTapped(_ sender: UITapGestureRecognizer) {
        print("BlipeFile Image Tapped")
        zoomImage.backgroundColor = .black
        zoomImage.isUserInteractionEnabled = true
        zoomImage.image = imageView.image
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissFullscreenImage))
        zoomImage.addGestureRecognizer(tap)
        scroller.isHidden = false
    }
    @objc func dismissFullscreenImage(_ sender: UITapGestureRecognizer) {
        scroller.isHidden = true
        scroller.setZoomScale(0.0, animated: true)
    }
    func checkPlaceHolderText() {
        textView.layer.borderWidth = 1
        textView.layer.borderColor = UIColor.red.cgColor

        if textView.text == "" {
            textView.text = placeHolderText
            textView.textColor = UIColor.gray
            txtIsPlaceHolder = true
        }
    }
    
    // ----------------------------------------
    // UPDATE MODE
    func updateBlipMode() {
        print("Update Blip Mode- Instantiate the form")
        blipObjectid = curBlip.blip_id
        
        //-- Get Labels for text and image from Blip
        blipDate.setTitle(curBlip.blip_dt_txt, for: [])
        blipPlace.setTitle(substr(stringValue: curBlip.blip_addr, forInt: 30), for: [])

        textView.text = curBlip.blip_note
        checkPlaceHolderText()

        if curBlip.imageFile != nil {
            curBlip.imageFile!.getDataInBackground { (data, error) in
                if let imageData = data {
                    if let imageToDisplay = UIImage(data: imageData) {
                        self.imageView.image = imageToDisplay
                    }
                }
            }
        }
        
        // Get Blip Files for the existing blip
        let query = PFQuery(className: "BlipFile")
        query.whereKey("blip_id", equalTo: curBlip.blip_id)
        query.order(byAscending: "createdAt")
        query.findObjectsInBackground(block: { (objects, error) in
            // Get files array of objects
            if let files = objects {
                var curFile = blipFile()
                for blipFileRow in files {
                    curFile.file_id = (blipFileRow.objectId!)
                    curFile.file_type = blipFileRow["file_type"] as? String ?? ""
                    curFile.blip_id = blipFileRow["blip_id"] as! String
                    curFile.file_dt = blipFileRow["file_dt"] as? Date
                    curFile.file_addr = blipFileRow["file_addr"] as? String ?? ""
                    if blipFileRow["latitude"] == nil { print("blipFileRow latitude is nil")}
                    curFile.file_lat = blipFileRow["latitude"] as? Double
                    curFile.file_lon = blipFileRow["longitude"] as? Double
                    if blipFileRow["imageFile"] != nil {
                        let tempFile = blipFileRow["imageFile"] as! PFFileObject
                        // NEED LOGIC FOR imageThumbFile
                        curFile.imageFile = tempFile
                        self.blipFiles.append(curFile)
                        curBlip.fileCount += 1
                    }
                }
                self.blipFileCollectionView.reloadData()
            }
        })
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showPlaceTimePicker" {
            let vc = segue.destination as! BlipDataPickerVC
            print(blipFiles.count)
            print(blipFiles[0].file_addr) // bug causes a crash!
            vc.blipFiles = blipFiles
        } else if segue.identifier == "showPlacePicker" {
            let vc = segue.destination as! BlipPlacePickerVC

            if let lat = curBlip.blip_lat, let lon = curBlip.blip_lon {
                print("\(lat), \(lon)")
                vc.getYelp(latitude:lat, longitude: lon)
                vc.getHere(latitude:lat, longitude: lon)
            }
            vc.runTimer()
        }
    }
}

// ----------------------------------------
// EXTENSION for EXIF IMAGE PICKER CONTROLLER
extension BlipMainVC:UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true, completion: nil)
    }
    
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            self.imageView.image = image
            print("image view set")
            self.choosenImage = image
            
            if imagePicker.sourceType == .photoLibrary {
                print("Photo Library Mode")
                // Extract Exif Data from Phone
                let asset = info[UIImagePickerControllerPHAsset] as! PHAsset
                //let imageThumb  = self.getAssetThumbnail(asset: asset)
                let options = PHContentEditingInputRequestOptions()
                options.isNetworkAccessAllowed = true //download asset metadata from iCloud if needed
                asset.requestContentEditingInput(with: options) { (contentEditingInput: PHContentEditingInput?, _) -> Void in
                    let fullImage = CIImage(contentsOf: contentEditingInput!.fullSizeImageURL!, options: nil)
                    // EXTRACT EXIF PROPERTIES
                    if let properties = fullImage?.properties {
                        print("start exif on selected image")
                        self.exif = Exif(properties)
                        // Check for valid placetime
                        if self.exif?.gps?.dateStamp != nil && self.exif?.gps?.timeStamp != nil && self.exif?.gps?.timeZoneAbbreviation != nil {
                            print("EXIF time set")
                        } else {
                            print("missing time on exif")
                        }
                        if self.exif?.gps?.latitude != nil && self.exif?.gps?.latitude != nil {
                          print("EXIF lat/lon set")
                        } else {
                            print("missing lat/lon")
                        }
                        print("done exif on selected image")
                        // POST SELECTED FILE TO SERVER
                        self.postFile(fileType: "image")
                    } else {
                        self.postFile(fileType: "image")
                    }
                }
            } else if imagePicker.sourceType == .camera {
                postFile(fileType: "image")
            }
        } else {
            print("Something went wrong with imagePickerController")
        }
        self.dismiss(animated: true, completion: nil)
    }
    func getAssetThumbnail(asset: PHAsset) -> UIImage {
        let manager = PHImageManager.default()
        let option = PHImageRequestOptions()
        var thumbnail = UIImage()
        option.isSynchronous = true
        
        manager.requestImage(for: asset, targetSize: CGSize(width: 100, height: 100), contentMode: .aspectFit, options: option, resultHandler: {(result, info)->Void in
            thumbnail = result!
        })
        return thumbnail
    }
}

