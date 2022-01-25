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
    var foundCntr = 0
    var missingCntr = 0
    var PhotoModeButton = false

    @IBOutlet weak var FeedTableView: UITableView!
    @IBOutlet weak var newBlip: UIButton!
    @IBOutlet weak var newBlipPhoto: UIButton!

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
    override func viewDidLoad() {
        super.viewDidLoad()
        print("ViewDidLoad.BlipFeedVC")
        FeedTableView.dataSource = self

        // Query Parse Server... need to clean up what you need to check for nil on curBlip so you can post changes to Blip
        let query = PFQuery(className: "BlipPost")
        query.whereKey("user_id", equalTo: PFUser.current()?.objectId ?? "")
        query.order(byDescending: "blip_date")
        query.limit = 1000 // Need to change this to smooth updating of infinite value like instagram/facebook
        query.findObjectsInBackground(block: { (objects, error) in
            // Build Data Arrays
            if let posts = objects {
                for post in posts {
                    curBlip = returnBlipPostFromDB(dbRow: post)
                    // need to add the new blip post to rules and only run
                    loadedBlips.append(curBlip)
 
                    // Lets do some house keeping for when new blip files don't post
                    if curBlip.imageFile == nil {
                        // Every blip should have an image file and definitely have a lat/lon, fix if it doesn't
                        fixMissingBlipFiles(blip: curBlip) // if this is a perm fix then need to update icon in loaded blip array
                    }
                }
            }
            if reloadRequired {
                DispatchQueue.main.async {
                    self.FeedTableView.reloadData()
                }
            }
            print ("FOUND=\(self.foundCntr) MISSING=\(self.missingCntr)")
        })
        setViewLayout()
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
        cell.setBlipRow(blip: loadedBlips[indexPath.row])
        
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
    func setViewLayout (){
        newBlip.clipsToBounds = true
        newBlip.layer.cornerRadius = newBlip.frame.size.width / 8
        newBlipPhoto.clipsToBounds = true
        newBlipPhoto.layer.cornerRadius = newBlipPhoto.frame.size.width / 8
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
