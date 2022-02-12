//
//  Exif.swift
//  Blip dropper
//
//  Created by DANIEL PATRIARCA on 8/30/18.
//  Copyright © 2018 DANIEL PATRIARCA. All rights reserved.

import Foundation
import CoreLocation
import UIKit

//1
//self.exif.

public struct Exif{
    var assetCreateDate: Date?
    var assetLocation: CLLocation?
    let pixelHeight:Int
    let pixelWidth:Int
    let dpiHeight:Int
    let dpiWidth:Int
    
    //MARK:- Exif Data
    
    var apertureValue:Double?
    var brightnessValue:Double?
    
    var colorSpace:Int = 0
    var colorSpaceComponents:(red:Int ,green:Int,blue:Int,alpha:Int) = (0,0,0,0)
    
    var timeDigitized:String?
    var timeOrigional:String?
    
    var exifVersion = [Int]()
    var exposureBiasValue:Int?
    var exposureMode:Int?
    var exposureProgram:Int?
    var exposureTime:Double?
    var FNumber:Double?
    var flash:Int?
    var flashPixVersion = [Int]()
    var focalLengthIn35mmFilm:Int?
    var focalLength:Double?
    var isoSpeedRatings = [Int]()
    var lensMake:String?
    var lensModel:String?
    var lensSpecification = [Double]()
    var masteringMode:Int?
    var pixelXDimension:Int = 0
    var pixelYDimension:Int = 0
    var sceneType:Int = 0
    var sceneCaptureType:Int = 0
    var sensingMethod:Int?
    var shutterSpeedValue:String?
    var subjectArea = [Int]()
    var subsecTimeDigitized:Int?
    var subsecTimeOrigional:Int?
    var whiteBalance:Int?
    
    var tiff:Tiff? //self.exif.tiff.
    var gps:GPS? //self.exif.gps
    
    var depth:Int?
    var orientation:Int?
    var profileName:String?
    
    var colorModel:String?
    
    
    init(_ object:[String:Any]) {
        
        self.pixelWidth = object["PixelHeight"] as? Int ?? 0
        self.pixelHeight = object["PixelHeight"] as? Int ?? 0
        self.dpiWidth = object["DPIWidth"] as? Int ?? 0
        self.dpiHeight = object["DPIHeight"] as? Int ?? 0
        
        
        if let object  = object["{Exif}"] as? [String:Any]{
            if let value = object["ApertureValue"] as? Double{
                
                self.apertureValue = value
            }
            
            if let value = object["BrightnessValue"] as? Double{
                
                self.brightnessValue = value
            }
            
            self.colorSpace = object["ColorSpace"] as? Int ?? 0
            
            if let value = object["ComponentsConfiguration"] as? [Int]{
                
                self.colorSpaceComponents = (value[0],value[1],value[2],value[3])
            }
            
            if let value = object["DateTimeDigitized"] as? String{
                
                self.timeDigitized = value
            }
            
            if let value = object["DateTimeOriginal"] as? String{
                
                self.timeOrigional = value
            }
            
            if let value = object["ExifVersion"] as? [Int]{
                
                self.exifVersion =  value
            }
            
            if let value = object["ExposureBiasValue"] as? Int{
                
                self.exposureBiasValue =  value
            }
            
            if let value = object["ExposureMode"] as? Int{
                
                self.exposureMode =  value
            }
            
            if let value = object["ExposureProgram"] as? Int{
                
                self.exposureProgram =  value
            }
            
            if let value = object["ExposureTime"] as? Double{
                
                self.exposureTime =  value
            }
            
            if let value = object["FNumber"] as? Double{
                
                self.FNumber =  value
            }
            
            if let value = object["Flash"] as? Int{
                
                self.flash =  value
            }
            
            if let value = object["FlashPixVersion"] as? [Int]{
                
                self.flashPixVersion =  value
            }
            
            if let value = object["FocalLenIn35mmFilm"] as? Int{
                
                self.focalLengthIn35mmFilm =  value
            }
            
            if let value = object["FocalLength"] as? Double{
                
                self.focalLength =  value
            }
            
            if let value = object["ISOSpeedRatings"] as? [Int]{
                
                self.isoSpeedRatings =  value
            }
            
            if let value = object["LensMake"] as? String{
                
                self.lensMake =  value
            }
            
            if let value = object["LensModel"] as? String{
                
                self.lensModel =  value
            }
            
            if let value = object["LensSpecification"] as? [Double]{
                
                self.lensSpecification =  value
            }
            
            if let value = object["MeteringMode"] as? Int{
                
                self.masteringMode =  value
            }
            
            if let value = object["PixelXDimension"] as? Int{
                
                self.pixelXDimension =  value
            }
            
            if let value = object["PixelYDimension"] as? Int{
                
                self.pixelYDimension =  value
            }
            
            if let value = object["SceneType"] as? Int{
                
                self.sceneType =  value
            }
            
            if let value = object["SceneCaptureType"] as? Int{
                
                self.sceneCaptureType =  value
            }
            
            if let value = object["SensingMethod"] as? Int{
                
                self.sensingMethod =  value
            }
            
            if let value = object["ShutterSpeedValue"] as? String{
                
                self.shutterSpeedValue =  value
            }
            
            if let value = object["SubjectArea"] as? [Int]{
                
                self.subjectArea =  value
            }
            
            if let value = object["SubsecTimeDigitized"] as? Int{
                
                self.subsecTimeDigitized =  value
            }
            
            if let value = object["SubsecTimeOriginal"] as? Int{
                
                self.subsecTimeOrigional =  value
            }
            
            if let value = object["WhiteBalance"] as? Int{
                
                self.whiteBalance =  value
            }
        }
        
        if let value = object["Orientation"] as? Int{
            
            self.orientation =  value
        }
        
        if let value = object["ProfileName"] as? String{
            
            self.profileName =  value
        }
        
        if let tiff = object["{TIFF}"] as? [String:Any]{
            
            self.tiff = Tiff(tiff)
        }
        
        if let tiff = object["{GPS}"] as? [String:Any]{
            
            self.gps = GPS(tiff,time:self.timeOrigional ?? "")
        }
        
        
    }
    
    
    
}

public struct Tiff{
    
    var dateandTime:String? //self.exif.tiff.
    var make:String?
    var model:String?
    var orientation:Int?
    var software:String?
    
    var resolutionUnit:Int = 0
    var xResoultion:Int = 0
    var yResoultion:Int = 0
    
    var object  = [String:Any]()
    init(_ object:[String:Any]) {
        
        self.object = object
        
        if let value = object["DateTime"] as? String{
            
            self.dateandTime = value
        }
        
        if let value = object["Make"] as? String{
            
            self.make = value
        }
        
        if let value = object["Model"] as? String{
            
            self.model = value
        }
        
        if let value = object["Orientation"] as? Int{
            
            self.orientation = value
        }
        
        if let value = object["ResolutionUnit"] as? Int{
            
            self.resolutionUnit = value
        }
        
        if let value = object["Software"] as? String{
            
            self.software = value
        }
        
        if let value = object["XResolution"] as? Int{
            
            self.xResoultion = value
        }
        
        if let value = object["YResolution"] as? Int{
            
            self.yResoultion = value
        }
    }
    
    public func getFormattedString(valueSeperator:String,lineSeperator:String)->String{
        
        return self.object.getFormattedString(valueSeperator:valueSeperator,lineSeperator:lineSeperator)
    }
}

public struct GPS{
    
    var time:String? //self.exif.gps.time
    var altitude:Double?
    var altitudeRef:Int?
    var dateStamp:String?
    var destBearing:Double?
    var destBearingRef:String?
    var hPositionError:Int?
    var imageDirection:Double?
    var imageDirectionRef:String?
    var latitude:Double?
    var latitudeRef:String?
    var longitude:Double?
    var longitudeRef:String?
    var speed:String?
    var speedRef:String?
    var timeStamp:String?
    
    var timeZoneLocation:String?
    var timeZoneAbbreviation:String?
    
    var object = [String:Any]()
    init(_ object:[String:Any],time:String) {
        
        self.object = object
        
        if let value = object["Altitude"] as? Double{
            
            self.altitude = value
        }
        
        if let value = object["AltitudeRef"] as? Int{
            
            self.altitudeRef = value
        }
        
        if let value = object["DateStamp"] as? String{
            
            self.dateStamp = value
        }
        
        if let value = object["DestBearing"] as? Double{
            
            self.destBearing = value
        }
        
        if let value = object["DestBearingRef"] as? String{
            
            self.destBearingRef = value
        }
        
        if let value = object["HPositioningError"] as? Int{
            
            self.hPositionError = value
        }
        
        if let value = object["ImgDirection"] as? Double{
            
            self.imageDirection = value
        }
        
        if let value = object["ImgDirectionRef"] as? String{
            
            self.imageDirectionRef = value
        }
        
        
        if let value = object["LatitudeRef"] as? String{
            
            self.latitudeRef = value.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        }
        
        if let value = object["Latitude"] as? Double{
            
            
            self.latitude = value
        }
        
        
        if let value = object["LongitudeRef"] as? String{
            
            self.longitudeRef = value.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        }
        
        
        if let value = object["Longitude"] as? Double{
            
            self.longitude = value
        }
        
        
        switch (self.latitudeRef ?? "S",self.longitudeRef ?? "S") {
        case ("N","W"):
            self.longitude = -(self.longitude ?? 0)
        case ("S","W"):
            self.longitude = -(self.longitude ?? 0)
            self.latitude = -(self.latitude ?? 0)
        case ("S","E"):
            self.latitude = -(self.latitude ?? 0)
        default:
            break
        }
        
        
        if let value = object["Speed"] as? String{
            
            self.speed = value
        }
        
        if let value = object["SpeedRef"] as? String{
            
            self.speedRef = value
        }
        
        if let value = object["TimeStamp"] as? String{
            
            self.timeStamp = value
        }
        
        print(time) //2017:06:24 11:36:22 //YYYY:MM:DD hh:mm:ss
        
        if let date = self.stringToDate(time, format: "YYYY:MM:DD hh:mm:ss"){
            self.time = self.datetoString(date, format: "hh:mm:ss")
        }
        let location = CLLocationCoordinate2D(latitude: self.latitude ?? 0, longitude: self.longitude ?? 0)
        if let timeZone = TimezoneMapper.latLngToTimezone(location){
            self.timeZoneLocation = timeZone.description
            self.timeZoneAbbreviation = timeZone.abbreviation()
        }
        
        //MARK:- Just references!
        self.object.updateValue(self.latitude ?? 0, forKey: "Latitude")
        self.object.updateValue(self.longitude ?? 0, forKey: "Longitude")
        self.object.updateValue(self.timeZoneLocation ?? "", forKey: "Location")
        self.object.updateValue(self.timeZoneAbbreviation ?? "", forKey: "Time Zone")
        self.object.updateValue(self.time ?? "", forKey: "Time")
    }
    
    public func stringToDate(_ timeString:String,format:String)->Date?{
        
        let formatter  = DateFormatter()
        formatter.dateFormat = format
        
        return formatter.date(from: timeString)
    }
    
    public func datetoString(_ date:Date, format:String)->String?{
        
        let formatter  = DateFormatter()
        formatter.dateFormat = format
        
        return formatter.string(from: date)
    }
    
    
    public func getFormattedString(valueSeperator:String,lineSeperator:String)->String{
        
        return self.object.getFormattedString(valueSeperator:valueSeperator,lineSeperator:lineSeperator)
    }
}

extension Dictionary where Key == String,Value == Any{
    
    public func getFormattedString(valueSeperator:String,lineSeperator:String)->String{
        
        return self.description.replacingOccurrences(of: ": ", with: valueSeperator).trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ",", with: "\n\(lineSeperator)").replacingOccurrences(of: "[", with: "").replacingOccurrences(of: "]", with: "").replacingOccurrences(of: "\"", with: "")
    }
}


