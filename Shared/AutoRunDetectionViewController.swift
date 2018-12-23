//
//  AutoRunDetectionViewController.swift
//  MediaProcessor
//
//  Created by Benoit Pereira da silva on 22/12/2018.
//  Copyright © 2018 Pereira da Silva. All rights reserved.
//

import Foundation
import CoreMedia
import CoreVideo


class AutoRunDetectionViewController: XViewController, PrintDelegate {

    var detector:ShotsDetector?

    func printIfVerbose(_ message: Any){
        print(message)
    }
    func printAlways(_ message: Any){
        print(message)
    }


    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        /// Auto run
        let token:String = ""
        let prettyEncode:Bool = true
        let threshold:Int = 40
        // URL(string: "https://download.blender.org/peach/bigbuckbunny_movies/BigBuckBunny_320x180.mp4")!
        let movieURL:URL = URL(string:"https://download.blender.org/peach/bigbuckbunny_movies/big_buck_bunny_1080p_h264.mov")!
        let starts:Double = 60
        let endsTime:CMTime? = 120.toCMTime()
        let startTime:CMTime = starts.toCMTime()
        VideoMetadataExtractor.extractMetadataFromMovieAtURL(movieURL, success: { (origin, fps,  duration,width,height,url) in
            self.printIfVerbose("Processing video: \(url) ")
            self.printIfVerbose("Fps: \(fps)")
            self.printIfVerbose("Size: \(Int(width))/\(Int(height))")
            self.printIfVerbose("Duration: \(duration.stringMMSS)")

            if let origin:Double = origin{
                self.printIfVerbose("Origin: \(origin.toCMTime().timeCodeRepresentation(fps, showImageNumber: true))")
            }else{
                self.printIfVerbose("Origin: \(0.toCMTime().timeCodeRepresentation(fps, showImageNumber: true))")
            }

            do{

                let videoSource: VideoSource = VideoSource( url: url,
                                                            token: token,
                                                            fps: fps,
                                                            width: Double(width),
                                                            height: Double(height),
                                                            duration: duration,
                                                            origin: origin ?? 0,
                                                            originTimeCode: (origin ?? 0).stringMMSS)

                self.detector = try ShotsDetector.init( source: videoSource,
                                                        startTime: startTime,
                                                        endTime: endsTime ?? duration.toCMTime())
                self.detector?.printDelegate = self


                self.detector?.start()

                if threshold > 0 && threshold <= 255{
                    self.detector?.differenceThreshold = threshold
                }else{
                    self.printIfVerbose("Ignoring threshold option \(threshold), its value should be > 0 and <= 255")
                }


                NotificationCenter.default.addObserver(forName: NSNotification.Name.ShotsDetection.didFinish, object:nil, queue:nil, using: { (notification) in
                    if let result: ShotsDetectionResult = self.detector?.result{
                        doCatchLog({
                            let data:Data
                            if prettyEncode{
                                data = try JSON.prettyEncoder.encode(result)
                            }else{
                                data = try JSON.encoder.encode(result)
                            }
                            if let utf8String:String = String(data: data, encoding: .utf8 ){
                                self.printIfVerbose(utf8String)
                            }
                        })
                    }
                    self.printIfVerbose("This the END")
                })

            }catch{
                self.printIfVerbose("\(error)")
            }

            }, failure: { (message, url) in
            self.printIfVerbose("\(message) \(url)")
        })
    }



}
