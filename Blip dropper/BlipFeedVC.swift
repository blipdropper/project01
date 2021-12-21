//
//  BlipFeedVC.swift
//  Blip dropper
//
//  Created by DANIEL PATRIARCA on 8/18/18.
//  Copyright © 2018 DANIEL PATRIARCA. All rights reserved.

//  This will CRASH because of all the ! force unwraps... what happens when crazy things like blip with no file happen?
//  Create blip from email... parse text, images, when, and turn image files into blip file.  A blip is really just an email and that is how to import blips

import UIKit
import Parse

class BlipFeedVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    // ----------------------------------------
    // IBOUTLETS, ACTIONS, and variables
    var PhotoModeButton = false

    @IBOutlet weak var FeedTableView: UITableView!

    @IBAction func logOut(_ sender: Any) {
        PFUser.logOut()
        // Wipe memory becasuse we are loggin out
        curBlip = blipData()
        loadedBlips = [blipData]()
        self.performSegue(withIdentifier: "logOutUnwind", sender: self)
    }
    @IBAction func newBlipPhoto(_ sender: Any) {
        PhotoModeButton = true
        curBlip = blipData()
        self.performSegue(withIdentifier: "showBlip", sender: self)
    }
    
    @IBAction func newBlip(_ sender: Any) {
        // Blank out the current Blip because we want new one
        PhotoModeButton = false
        curBlip = blipData()
        self.performSegue(withIdentifier: "showBlip", sender: self)
    }

    // ----------------------------------------
    // VIEW DID LOAD
    override func viewDidLoad() {
        super.viewDidLoad()
        print("ViewDidLoad.BlipFeedVC")
        FeedTableView.dataSource = self

        // Query Parse Server... need to clean up what you need to check for nil on curBlip so you can post changes to Blip
        let query = PFQuery(className: "BlipPost")
//        query.whereKey("user_id", equalTo: PFUser.current()?.objectId ?? "")
//        query.whereKeyDoesNotExist("imageFile")
        query.order(byDescending: "blip_date")
        query.limit = 10000
        query.findObjectsInBackground(block: { (objects, error) in
        var strDate = ""
            // Build Data Arrays
            if let posts = objects {
                for post in posts {
                    if let blipdate = post["blip_date"] {
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "E, d MMM yyyy h:mm a"
                        strDate = dateFormatter.string(from: blipdate as! Date)
                        curBlip.blip_dt = blipdate as? Date
                    } else {
                        print("Error setting date string")
                    }
                    curBlip.blip_dt_txt = strDate
                    curBlip.blip_addr = post["blip_address"] as! String
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

                    loadedBlips.append(curBlip)

                    // --------------------------------
                    // Lets do some house keeping here
                    // --------------------------------
                    if curBlip.imageFile == nil {
                        print ("no image lets check if there are any image files...  \(curBlip.blip_id)- \(curBlip.blip_note)")
                        // should have a map one... if not use the lat lon to create one... if you have a non map one make that the image
                    }
                }
            }
            if reloadRequired {
                DispatchQueue.main.async {
                    self.FeedTableView.reloadData()
                }
            }
        })
        print("ViewDidLoad all done")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.FeedTableView.reloadData()
      }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showBlip"{
            let vc = segue.destination as! BlipMainVC
            vc.PhotoMode = PhotoModeButton
        }
    }
    // ----------------------------------------
    // TABLE VIEW Controller Functions
    internal func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if loadedBlips.count == 0 {
            reloadRequired = true
            print("Table did appear beat the parse server call!")
        }
        return loadedBlips.count
    }
    internal func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "blipCell", for: indexPath) as! BlipFeedTVCell
        cell.setBlipCell(blip: loadedBlips[indexPath.row])
        
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        curBlip = loadedBlips[indexPath.row]
        curBlip.arrayPosition = indexPath.row
        self.performSegue(withIdentifier: "showBlip", sender: self)
    }
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let blip_id = loadedBlips[indexPath.row].blip_id
            
            // Delete the blip from the server
            let query = PFQuery(className: "BlipPost")
            query.getObjectInBackground(withId: blip_id) { (object, error) in
                if object != nil && error == nil {
                    object?.deleteInBackground()
                }
            }
            // Remove the blip from the table arrays
            loadedBlips.remove(at: indexPath.row)
            FeedTableView.beginUpdates()
            FeedTableView.deleteRows(at: [indexPath], with: .automatic)
            FeedTableView.endUpdates()
            // Remove the files that go with the blip too!
            let query2 = PFQuery(className: "BlipFile")
            query2.whereKey("blip_id", equalTo: blip_id)
            query2.findObjectsInBackground(block: { (objects, error) in
                if error == nil {
                    PFObject.deleteAll(inBackground: objects, block: { (success, error) in
                        if success {
                            print("Success, if it was an error you would have to deal with data mismatch?")
                        }
                    })
                }
            })
        }
    }

    /* Alternate Back Button (self.dismiss currently)
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    @IBAction func backToBlipFeed(segue: UIStoryboardSegue) {}
    */

}
