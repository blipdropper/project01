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
import PhotosUI
import Parse

class BlipMainVC: UIViewController, CLLocationManagerDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UITextViewDelegate, UIScrollViewDelegate {
    // ----------------------------------------
    // IBOUTLETS, ACTIONS, and variables
    private let imagePicker = UIImagePickerController()
    var blipObjectid = ""
    var mapImage: UIImage?
    var location = blipLocation()
    var snapshotRan = "initialized"
    var photoMapImage: UIImage?
    var photoLocation = blipLocation()
    var photoSnapshotRan = "initialized"
    var locationManager = CLLocationManager()
    var currLocation = CLLocation()
    var currDateStamp = Date()
    var blipFiles = [blipFile]()
    var locationSet = false
    var newBlipMode = false
    var PhotoMode = false
    var cameraPhotoSwitch = ""
    var txtIsPlaceHolder = false
    var txtIsEditing = false
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
        //self.performSegue(withIdentifier: "showPlaceTimePicker", sender: self)
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
        // Why are you regetting the post you already had to acces to fill in data or do initial save on load?
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
                blip!["icon_file_id"] = curBlip.icon_file_id
                blip!["icon_file_type"] = curBlip.icon_file_type
                blip!["blip_init_source"] = curBlip.blip_init_source
                blip!["blip_date"] = curBlip.blip_dt
                // HOW ARE YOU GOING TO GET THE TZ SECONDS FROM EXIF?  HOW IS THIS USED
                //blip!["TZOffset_seconds"] = curBlip.blip_tz_secs
                blip!["blip_address"] = curBlip.blip_location.strAddress
                blip!["subThoroughfare"] = curBlip.blip_location.subThoroughfare
                blip!["thoroughfare"] = curBlip.blip_location.thoroughfare
                blip!["subLocality"] = curBlip.blip_location.subLocality
                blip!["locality"] = curBlip.blip_location.locality
                blip!["subAdministrativeArea"] = curBlip.blip_location.subAdministrativeArea
                blip!["administrativeArea"] = curBlip.blip_location.administrativeArea
                blip!["postalCode"] = curBlip.blip_location.postalCode
                blip!["country"] = curBlip.blip_location.country
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
        loadedBlips[curBlip.arrayPosition] = curBlip
        //found nil wile unwrapping an optional after hitting place off of new no pic blip?
        print(curBlip.blip_dt ?? "")
        loadedBlips.sort(by: { $0.blip_dt?.compare(($1.blip_dt)!) == .orderedDescending }) // newest to oldest
    }

    // ----------------------------------------
    // POST FILE
    func postLocationFile(mapImage: UIImage, mapType: String) {
        var newBlipFile = blipFile()
        // Check Blip id set
        if curBlip.blip_id == "" {
            print("blip_id is nil pal")
        } else if snapshotRan != "done" {
            print("snapshot image wasn't set yet")
        } else {
            print("blip_id = \(curBlip.blip_id) for file")
        }
        // Differentiate photo derived maps from locaton ones
        if mapType == "photo" {
            newBlipFile.file_type = "mapImageFromPhoto"
        } else {
            newBlipFile.file_type = "mapImage"
        }
        newBlipFile.blip_id = curBlip.blip_id
        newBlipFile.imageUIImage = mapImage

        if let imageData = UIImageJPEGRepresentation(mapImage, 0.1) {
            print("start image encode map to PFFile")
            if let blipFile = PFFileObject(name: "mapImage.jpg", data: imageData as Data) {
                newBlipFile.imageFile = blipFile
                newBlipFile.imageThumbFile = blipFile
                // SET curBlip images if this is first file
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
                if let newFileObjectId = blipFileRow.objectId {
                    newBlipFile.file_id = newFileObjectId
                    if curBlip.fileCount == 0 {
                        makeBlipFileBlipIcon(newIconFile: newBlipFile)
                    }
                }
            } else {
                print(error?.localizedDescription ?? "")
            }
            // Append to Blip File array
            self.blipFiles.insert(newBlipFile, at: 0)
            curBlip.fileCount = self.blipFiles.count
            print("start collection reload filecount:\(curBlip.fileCount)")
            self.blipFileCollectionView.reloadData()
        })
    }
    func postFile(chosenImage: UIImage, fileType: String) {
        var exifDateOk = false
        var exifPlaceOk = false
        let dateFormatter = DateFormatter()
        var newBlipFile = blipFile()
        let blipFileRow = PFObject(className: "BlipFile")

        // Populate Blip File Struct
        newBlipFile.blip_id = curBlip.blip_id
        newBlipFile.file_type = cameraPhotoSwitch
        newBlipFile.imageUIImage = chosenImage
        newBlipFile.create_dt = Date()
        newBlipFile.create_dt_txt = time2String(time: newBlipFile.create_dt!)
        // Get image file
        if let imageData = UIImageJPEGRepresentation(chosenImage, 0.1) {
            print("start image encode to PFFile")
            if let blipFile = PFFileObject(name: "image.jpg", data: imageData as Data) {
                newBlipFile.imageFile = blipFile
                newBlipFile.imageThumbFile = blipFile
            }
        }
        // Get file create date
        if let fileCreationDate = exif?.assetCreateDate {
            exifDateOk = true
            newBlipFile.file_dt = fileCreationDate
            newBlipFile.file_dt_txt  = time2String(time: newBlipFile.file_dt!)
        } else if let fileDateStamp = self.exif?.gps?.dateStamp, let fileTz = self.exif?.gps?.timeZoneAbbreviation {
            dateFormatter.dateFormat = "yyyy:MM:dd HH:mm:ss zzz"
            if let dateFromString = dateFormatter.date(from: "\(fileDateStamp) \(fileTz)") {
                exifDateOk = true
                newBlipFile.file_dt = dateFromString
                newBlipFile.file_dt_txt  = time2String(time: newBlipFile.file_dt!)
            }
        } else if let fileDateStamp = self.exif?.timeOrigional, let fileTz = self.exif?.gps?.timeZoneAbbreviation {
            dateFormatter.dateFormat = "yyyy:MM:dd HH:mm:ss zzz"
            if let dateFromString = dateFormatter.date(from: "\(fileDateStamp) \(fileTz)") {
                exifDateOk = true
                newBlipFile.file_dt = dateFromString
                newBlipFile.file_dt_txt  = time2String(time: newBlipFile.file_dt!)
            }
        }
        // Get file location
        if let lat: CLLocationDegrees = self.exif?.assetLocation?.coordinate.latitude, let lon: CLLocationDegrees = self.exif?.assetLocation?.coordinate.longitude {
            newBlipFile.file_lat = lat
            newBlipFile.file_lon = lon
            exifPlaceOk = true
        } else if let lat: CLLocationDegrees = self.exif?.gps?.latitude, let lon: CLLocationDegrees = self.exif?.gps?.longitude {
            newBlipFile.file_lat = lat
            newBlipFile.file_lon = lon
            exifPlaceOk = true
        }
        // Get Image file Object
        if let imageData = UIImageJPEGRepresentation(chosenImage, 0.1) {
            if let blipFile = PFFileObject(name: "image.jpg", data: imageData as Data) {
                newBlipFile.imageFile = blipFile
                newBlipFile.imageThumbFile = blipFile
            }
        }
        blipFileRow["blip_id"] = newBlipFile.blip_id
        blipFileRow["imageFile"] = newBlipFile.imageFile
        blipFileRow["imageThumbFile"] = newBlipFile.imageThumbFile
        blipFileRow["create_dt"] = newBlipFile.create_dt
        blipFileRow["file_addr"] = newBlipFile.file_addr
        blipFileRow["file_type"] = newBlipFile.file_type
        if exifPlaceOk {
            blipFileRow["latitude"] = newBlipFile.file_lat
            blipFileRow["longitude"] = newBlipFile.file_lon
        }
        if exifDateOk {
            blipFileRow["file_dt"] = newBlipFile.file_dt
            blipFileRow["file_dt_txt"] = newBlipFile.file_dt_txt
        }

        blipFileRow.saveInBackground(block: { (success, error) in
            if success {
                // SET curBlip images if this is first file... if its photoMode then set the blip as the file
                if let newFileObjectId = blipFileRow.objectId {
                    newBlipFile.file_id = newFileObjectId
                }
                if curBlip.fileCount <= 1 {
                    makeBlipFileBlipIcon(newIconFile: newBlipFile)
                    if self.PhotoMode {
                        if exifDateOk {
                            curBlip.blip_dt = newBlipFile.file_dt
                            curBlip.blip_dt_txt  = newBlipFile.file_dt_txt
                            self.blipDate.setTitle(newBlipFile.file_dt_txt, for: [])
                        }
                        if exifPlaceOk {
                            // Ask the user if they want to use the photo or the date?
                            curBlip.blip_lat = newBlipFile.file_lat
                            curBlip.blip_lon = newBlipFile.file_lon
                            self.setBlipLocationImage(latitude: curBlip.blip_lat!, longitude: curBlip.blip_lon!, mode: "photoMap")
                        } else if let image = self.mapImage { // If you didn't get a photo location use the location one
                            self.postLocationFile(mapImage: image, mapType: "location" )
                        }
                        self.PhotoMode = false
                    }
                }
            } else {
                print(error?.localizedDescription ?? "")
            }
            self.blipFiles.append(newBlipFile)
            curBlip.fileCount = self.blipFiles.count
            self.blipFileCollectionView.reloadData()
        })
        exif = nil
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
                /*
                AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: { (granted: Bool) -> Void in
                    if granted == true {
                        self.openCameraPicker()
                    } else {
                        self.showCameraPermissionDialog()
                    }
                })
                 */
                //------------ Maybe
                /*
                func requestCameraPermission() {
                2    AVCaptureDevice.requestAccess(for: .video, completionHandler: {accessGranted in
                3        guard accessGranted == true else { return }
                4        self.presentCamera()
                5    })
                6}
                */ //------------ Maye
                
                AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: { (granted: Bool)
                    in
                    DispatchQueue.main.async {
                        if granted == true {
                            self.openCameraPicker()
                        } else {
                            self.showCameraPermissionDialog()
                        }
                    }
                })
            }
        } else {
            self.alert("Your device does not have camera!")
        }
    }
    //-- For Photos
    private func checkPhotoLibraryPermission() {
        // This is how to check which version of iOS you are running
        if #available(iOS 14, *) {
             print("running on ios 14 or beyond")
        } else {
            print("running on old ios from before phpicker")
        }
        let status = PHPhotoLibrary.authorizationStatus()
        switch status {
        case .authorized:
            self.openPhotoPicker()
            break
        case .denied, .restricted:
            self.showPhotoPermissionDialog()
            break
        case .notDetermined:
            // ask for permissions
            PHPhotoLibrary.requestAuthorization({
                    (status) in
                DispatchQueue.main.async {
                    switch status {
                    case .authorized:
                        self.openPhotoPicker()
                        break
                    case .denied, .restricted:
                        self.showPhotoPermissionDialog()
                        break
                    case .notDetermined:
                        self.alert("Unexpected error occured for accessing photo library")
                        break
                    case .limited:
                        self.openPhotoPicker()
                        break
                    }
                }
            })
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
        cameraPhotoSwitch = "Photo"
        self.imagePicker.sourceType = .photoLibrary
        self.imagePicker.allowsEditing = false
        self.present(self.imagePicker, animated: true, completion: nil)
    }
    private func openCameraPicker(){
        cameraPhotoSwitch = "Camera"
        self.imagePicker.sourceType = .camera
        self.imagePicker.allowsEditing = false
        self.present(self.imagePicker, animated: true, completion: nil)
    }
    private func showCameraPermissionDialog(){
        self.alert("")
    }
    
    // ----------------------------------------
    // LOCATION MANAGER for initial Spot
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let userLocation: CLLocation = locations[0]
        currLocation = userLocation
        let latitude = userLocation.coordinate.latitude
        let longitude = userLocation.coordinate.longitude
        if snapshotRan == "initialized" {
            setBlipLocationImage(latitude: latitude, longitude: longitude, mode: "nopost")
        }
        print("Location set: \(latitude)")
        print(longitude)

        // Reverse Geo Code for addr
        CLGeocoder().reverseGeocodeLocation(userLocation) { (placemarks, error) in
            if error != nil {
                print(error!)
            } else {
                if let placemark = placemarks?[0] {
                    self.location = returnLocationFromPlaceMark(pm: placemark)
                    self.location.lat = latitude
                    self.location.lon = longitude
                    self.location.strLatitude = String(format: "%.8f", latitude)
                    self.location.strLongitude = String(format: "%.8f", longitude)
                    self.location.strCourse = String(userLocation.course)
                    self.location.strSpeed = String(userLocation.speed)
                    self.location.strAltitude = String(userLocation.altitude)
                    self.location.strLatLon = self.location.strLatitude + ", " + self.location.strLongitude
                    print(self.location.strAddress)

                    if self.locationSet {
                        print("location already set")
                    } else {
                        print("start posting")
                        self.postInitialBlip()
                        // if snapshot done then post image as file because you have the image already
                        self.locationSet = true
                    }
                }
            }
        }
        // Stop updating location to save battery
        locationManager.stopUpdatingLocation()
    }
    func setBlipLocationImage(latitude: Double, longitude: Double, mode: String) {
        if mode == "photoMap" {
            photoSnapshotRan = "started"
        } else {
            snapshotRan = "started"
        }

        let mapSnapshotOptions = MKMapSnapshotOptions()
        let location = CLLocationCoordinate2DMake(latitude, longitude)
        let region = MKCoordinateRegionMakeWithDistance(location, 1000, 1000)
        mapSnapshotOptions.region = region
        mapSnapshotOptions.size = imageView.frame.size
        mapSnapshotOptions.showsBuildings = true
        mapSnapshotOptions.pointOfInterestFilter = MKPointOfInterestFilter(including: [.bank, .atm, .restaurant, .amusementPark, .bakery])
        let snapShotter = MKMapSnapshotter(options: mapSnapshotOptions)
        
        snapShotter.start { (snapshot, error) in
            if let image = snapshot?.image {
                if mode == "photoMap" {
                    self.photoMapImage = image
                    let loc: CLLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
                    let ceo: CLGeocoder = CLGeocoder()
                    ceo.reverseGeocodeLocation(loc, completionHandler: {(placemarks, error) in
                        if let pm = placemarks?[0] {
                            self.photoLocation = returnLocationFromPlaceMark(pm: pm)
                            curBlip.blip_location = self.photoLocation
                            self.blipPlace.setTitle(returnLocationString(location: curBlip.blip_location), for: [])
                        } else {
                            print(error?.localizedDescription ?? "Error is Nil?")
                        }
                        self.photoSnapshotRan = "done"
                        self.postLocationFile(mapImage: image, mapType: "photo" )
                   })
                } else {
                    self.mapImage = image
                    self.imageView.image = image
                    self.snapshotRan = "done"
                    if mode == "postfile", !self.PhotoMode { // don't post if its photo mode
                        self.postLocationFile(mapImage: image, mapType: "location" )
                    }
                }
            } else {
                print("Snapshotter didn't get image for some reason? \(error?.localizedDescription ?? "Error is Nil?")")
            }
        }
    }
    func postInitialBlip() {
        var secondsFromGMT: Int { return TimeZone.current.secondsFromGMT() }
        
        curBlip.blip_status = "new"
        if PhotoMode {curBlip.blip_init_source = "photo"} else {curBlip.blip_init_source = "map"}
        curBlip.user_id = PFUser.current()?.objectId ?? ""
        curBlip.blip_dt = Date()
        curBlip.blip_dt_txt = time2String(time: curBlip.blip_dt!)
        curBlip.blip_lat = location.lat
        curBlip.blip_lon = location.lon
        curBlip.blip_location = location
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
        post["subThoroughfare"] = curBlip.blip_location.subThoroughfare
        post["thoroughfare"] = curBlip.blip_location.thoroughfare
        post["subLocality"] = curBlip.blip_location.subLocality
        post["locality"] = curBlip.blip_location.locality
        post["subAdministrativeArea"] = curBlip.blip_location.subAdministrativeArea
        post["administrativeArea"] = curBlip.blip_location.administrativeArea
        post["postalCode"] = curBlip.blip_location.postalCode
        post["country"] = curBlip.blip_location.country
        post["blip_address"] = curBlip.blip_location.strAddress
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
                        self.postLocationFile(mapImage: image, mapType: "location" )
                    }
                } else {
                    // if snapshot didn't finish then run it again but this time do the post at the end
                    if let lat = curBlip.blip_lat, let lon = curBlip.blip_lon {
                        self.setBlipLocationImage(latitude: lat, longitude: lon, mode: "postfile")
                    }
                }
            } else {
                print("\(error?.localizedDescription ?? "")")
                showAlertFromAppDelegate(title: "Connection Error", message: error?.localizedDescription ?? "Error retrieving error message")
            }
        }
        
        blipDate.setTitle(curBlip.blip_dt_txt, for: [])
        blipPlace.setTitle(returnLocationString(location: curBlip.blip_location), for: [])
        
        if PhotoMode {
            checkPhotoLibraryPermission()
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
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
            let width  = (collectionView.frame.width-30)/4
            let height = width
            return CGSize(width: width, height: height)
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell:BlipMainCell = collectionView.dequeueReusableCell(withReuseIdentifier: "fileCell", for: indexPath) as! BlipMainCell
        cell.delegateToMain = self
        cell.setBlipCell(file: blipFiles[indexPath.row])
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
            appleMapPin = curBlip.place_name
            appleMapPin = appleMapPin.addingPercentEncoding(withAllowedCharacters: CharacterSet(charactersIn: "!*'();:@&=+$,/?%#[]{} ").inverted) ?? ""
            appleMapPin = "\(appleMapPin)&sll=\(curBlip.place_lat ?? 0.0),\(curBlip.place_lon ?? 0.0)"
        }
        print(appleMapPin)
        let urlString = "http://maps.apple.com/?q=\(appleMapPin)"
        print("URL String: \(urlString)")

        if let url = URL(string: urlString), (selectedCell.curBlipFile.file_type == "mapImage" || selectedCell.curBlipFile.file_type == "mapImageFromPhoto") {
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
        setUpView()
        print("View Did Load says \(curBlip.place_name)")
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
    func setUpView() {
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
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
        userInteractionEnabledToggle(isEnabled: true)
        print("Ending touches began")
    }
    func textViewDidChange(_ ttextView: UITextView) {
        //textView(Sender)
        if(ttextView == self.textView) {
            // I think this fires every time you type... commentign out
            // print("textView main was used")
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
        userInteractionEnabledToggle(isEnabled: false)
    }
    func blipAltered() {
        //blipSave.setTitle("SAVE", for: [])
        print("Save Mode")
    }
    func userInteractionEnabledToggle(isEnabled: Bool) {
        imageView.isUserInteractionEnabled = isEnabled
        blipChoosePlace.isUserInteractionEnabled = isEnabled
        blipAddPhoto.isUserInteractionEnabled = isEnabled
        blipOpenCamera.isUserInteractionEnabled = isEnabled
        blipSave.isUserInteractionEnabled = isEnabled
        txtIsEditing = !isEnabled
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
            if blipFiles[indexPath.row].file_type == "mapImage" || blipFiles[indexPath.row].file_type == "mapImageFromPhoto", indexPath.row == 0 {
                // what options does a map need, all else you can delete
            } else {
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
                            makeBlipFileBlipIcon(newIconFile: self.blipFiles[indexPath.row-1])
                        } else {
                            print("Something went wrong \(error?.localizedDescription ?? "")")
                        }
                    }
                }))
                alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
                self.present(alert, animated: true)
            }
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
        //textView.layer.borderWidth = 1
        //textView.layer.borderColor = UIColor.red.cgColor

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
        blipPlace.setTitle(returnLocationString(location: curBlip.blip_location), for: [])

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
        query.order(byAscending: "create_dt")
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
                    // If a file doesn't have a lat/lon then see if you can pull one from exif?
                    // if blipFileRow["latitude"] == nil { print("blipFileRow latitude is nil")}
                    curFile.file_lat = blipFileRow["latitude"] as? Double
                    curFile.file_lon = blipFileRow["longitude"] as? Double

                    // You should skip everything if the image file is null, not just skip the append part
                    if blipFileRow["imageFile"] != nil {
                        let tempFile = blipFileRow["imageFile"] as! PFFileObject
                        curFile.imageFile = tempFile
                        // All files with an image file should have a thumb to use for the collection View
                        if blipFileRow["imageThumbFile"] == nil {
                            print ("Missing thumb on \(curFile.file_id)")
                            // Create a thumb so its on the server for next time
                            getBlipFileImage(file: curFile)
                        }
                        self.blipFiles.append(curFile)
                        curBlip.fileCount += 1
                    } else { print ("how does a file row have no file? for \(curFile.blip_id): file=\(curFile.file_id)")}
                }
                self.blipFileCollectionView.reloadData()
                if curBlip.fileCount == 1 {
                    print("1 file means that its the map, need to set a delegate back to here after the map image loads")
                }
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
            if let lat = curBlip.place_lat, let lon = curBlip.place_lon {
                print("\(lat), \(lon)")
                vc.getYelp(latitude:lat, longitude: lon)
                vc.getHere(latitude:lat, longitude: lon)
            } else if let lat = curBlip.blip_lat, let lon = curBlip.blip_lon {
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
extension BlipMainVC:UIImagePickerControllerDelegate, UINavigationControllerDelegate, PHPickerViewControllerDelegate {
    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true, completion: nil)
    }
    
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            self.imageView.image = image
            
            if imagePicker.sourceType == .photoLibrary {
                if let asset = info[UIImagePickerControllerPHAsset] as? PHAsset {
                    print(asset.creationDate ?? "")
                    //let imageThumb  = self.getAssetThumbnail(asset: asset)
                    let options = PHContentEditingInputRequestOptions()
                    options.isNetworkAccessAllowed = true //download asset metadata from iCloud if needed
                    asset.requestContentEditingInput(with: options) { (contentEditingInput: PHContentEditingInput?, _) -> Void in
                        let fullImage = CIImage(contentsOf: contentEditingInput!.fullSizeImageURL!, options: nil)
                        // Extract EXIF while you have UIImagePickerController info access
                        if let properties = fullImage?.properties {
                            self.exif = Exif(properties)
                            self.exif?.assetCreateDate = asset.creationDate
                            self.exif?.assetLocation = asset.location
                            // Check for valid placetime
                            //if self.exif?.gps?.dateStamp != nil && self.exif?.gps?.timeStamp != nil && self.exif?.gps?.timeZoneAbbreviation != nil {}
                            //if self.exif?.gps?.latitude != nil && self.exif?.gps?.longitude != nil {}
                        }
                        self.postFile(chosenImage: image, fileType: "image")
                    }
                } else {
                    showAlertFromAppDelegate(title: "Need Photo Permission", message: "Please go to Settings>> Blip dropper>> Photos>> All Photos in order to upoad photos")
                }
            } else if imagePicker.sourceType == .camera {
                cameraPhotoSwitch = "camera"
                postFile(chosenImage: image, fileType: "camera")
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
    @objc func pickPhotos(){
            var config = PHPickerConfiguration()
            config.selectionLimit = 1 // only 1 image per blip for now
            config.filter = PHPickerFilter.images
            
            let pickerViewController = PHPickerViewController(configuration: config)
            pickerViewController.delegate = self
            self.present(pickerViewController, animated: true, completion: nil)
    }
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true, completion: nil)
        print(picker)
        print(results)

        // NSItemProvider what are item provider vs. Results? Something about letting use video or Photo? A way to retain live image?
        let itemProviders = results.map(\.itemProvider)
        for item in itemProviders {
                if item.canLoadObject(ofClass: UIImage.self) {
                    item.loadObject(ofClass: UIImage.self) { (image, error) in
                        DispatchQueue.main.async {
                            if let image = image as? UIImage {
                                self.imageView.image = nil
                                self.imageView.image = image
                            }
                        }
                    }
                }
            }
        
        for result in results {
            print(result.assetIdentifier)
            print(result.itemProvider)

            if let assetId = result.assetIdentifier {
                let assetResults = PHAsset.fetchAssets(withLocalIdentifiers: [assetId], options: nil)
                print(assetResults.firstObject?.creationDate ?? "No date")
                print(assetResults.firstObject?.location?.coordinate ?? "No location")
            }
            
            result.itemProvider.loadObject(ofClass: UIImage.self, completionHandler: { (object, error) in
                print(object)
                print(error)
                
                if let image = object as? UIImage {
                    DispatchQueue.main.async {
                        // you have the selected image(s), now do something with it
                        // how will you get the exif off it?
                        /*
                        let imv = self.newImageView(image: image)
                        self.imageViews.append(imv)
                        self.scrollView.addSubview(imv)
                        self.view.setNeedsLayout()
                        */
                    }
                }
            })
        }
    }
}
extension BlipMainVC: blipMainCellDelegate {
    func resetMapImage(mergedMapImage: UIImage){
        // if there is only 1 file we assume its the mapImage
        if blipFiles.count == 1 {
            self.imageView.image = mergedMapImage
        }
    }
}


