//
//  ViewController.swift
//  parser
//
//  Created by Brittney Bearly on 2/13/20.
//  Copyright © 2020 Tammy Bearly. All rights reserved.
//


// check out code at https://medium.com/@artempoluektov/ios-pdfkit-ink-annotations-tutorial-4ba19b474dce
// anotation, thumbnail

import UIKit
import PDFKit
import CoreLocation // current location

var pdfView = PDFView()


class ViewController: UIViewController {
    var locationManager = CLLocationManager()
    
    //let pdfView = PDFView()//
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let pdfView = PDFView(frame: self.view.bounds)
        //let pdfView = PDFView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height))
        
        // Do any additional setup after loading the view.
        if let pdfFileURL = Bundle.main.url(forResource: "Wellington",withExtension: "pdf"){
            print ("pdf file =  \(pdfFileURL)")
            // OPEN PDF
            
            // Must set this to false!
            pdfView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(pdfView)
            pdfView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
            pdfView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
            pdfView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
            pdfView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
            
            if let document = PDFDocument(url: pdfFileURL){
                pdfView.autoresizesSubviews = true
                pdfView.autoresizingMask = [.flexibleWidth, .flexibleHeight, .flexibleTopMargin, .flexibleLeftMargin]
                //pdfView.displayDirection = .vertical

                pdfView.autoScales = true
                pdfView.displayMode = .singlePageContinuous
                //pdfView.displaysPageBreaks = true
                pdfView.document = document

                // how far can we zoom in?
                pdfView.maxScaleFactor = 4.0
                pdfView.minScaleFactor = pdfView.scaleFactor //pdfView.scaleFactorForSizeToFit
                pdfView.scaleFactor = pdfView.scaleFactorForSizeToFit
                
                // show only one page of document. true is causing many errors?????
                //pdfView.usePageViewController(true)
                
                //pdfView.autoScales = true // true is giving error one error
                //pdfView.minScaleFactor = pdfView.scaleFactorForSizeToFit //pdfView.scaleFactor
                //pdfView.zoomIn(15.0)
                //pdfView.maxScaleFactor = 10
                //pdfView.scaleFactor = 1
                print ("min \(pdfView.minScaleFactor)  max \(pdfView.maxScaleFactor)  scaleFactor \(pdfView.scaleFactor)")
                
                
                
                // try to zoom in
               /* if let page = document.page(at: 0) {
                    pdfView.scaleFactor = pdfView.scaleFactorForSizeToFit * 2
                    pdfView.go(to: CGRect(x: 0, y: 0, width: 1000, height: 1000), on: page)
                }*/
                
                // Set up double tab zoom in --- Does NOTHING!!!!!
                let doubleScreenTap = UITapGestureRecognizer(target: pdfView, action: #selector(zoomIn(_:)))
                doubleScreenTap.numberOfTapsRequired = 2
                doubleScreenTap.numberOfTouchesRequired = 1
                pdfView.addGestureRecognizer(doubleScreenTap)
               
                // scrolling direction
                //pdfView.displayDirection = .vertical
                //pdfView.displayDirection = .horizontal
                
            
                // Add annotation
                let image = UIImage(named: "ic_red_pin-web.png")
                let imageAnnotation = PushPin(image, bounds: CGRect(x: 200, y: 200, width: 200, height: 200), properties: nil)
                let page = document.page(at: 1)
                page?.addAnnotation(imageAnnotation)
            
            
            }
            
            //let jsonFileURL = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("output.json")
            //PDFParser.parse(pdfUrl: pdfFileURL, into: jsonFileURL)
            // Parse PDF into Dictionary.
            let pdf: [String:Any?] = PDFParser.parse(pdfUrl: pdfFileURL)
            print (pdf)
            print ("-- RETURNED VALUES --")
            let bounds = pdf["bounds"]!!
            print ("lat/long bounds: \(bounds)")
            let viewport = pdf["viewport"]!!
            print ("viewport margins: \(viewport)")
            let mediabox = pdf["mediabox"]!!
            print ("mediabox page size: \(mediabox)")
        
        
        }
        else {
            print ("error file not found")
            return
        }
        
        //locationManager.delegate=self
        locationManager.desiredAccuracy=kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        displayLocation();
    }
    
    
    func displayLocation(){
        var currentLoc: CLLocation!
        if(CLLocationManager.authorizationStatus() == .authorizedWhenInUse ||
        CLLocationManager.authorizationStatus() == .authorizedAlways) {
           currentLoc = locationManager.location
           print("Current location: \(currentLoc.coordinate.latitude), \(currentLoc.coordinate.longitude)")
        }
    }
    
    // On rotation make map fit, was zooming on landscape NOT WORKING??? Does nothing???
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        pdfView.frame = view.frame
        pdfView.autoScales = true
        if UIDevice.current.orientation.isLandscape {
            print("landscape")
        }
        else {
            print("portrait")
        }
    }
    
    // double tap zoom in NOT WORKING NEVER CALLED!!!!!!
    @IBAction func zoomIn(_ gestureRecognizer: UITapGestureRecognizer)
    {
        print("double tap zoom in")
        if gestureRecognizer.state == .ended
        {
            print("double tap state end")
            if let currentPage = pdfView.currentPage
            {
                let point = gestureRecognizer.location(in: pdfView)
                let destination = PDFDestination(page: currentPage, at: point)
                destination.zoom = (pdfView.scaleFactor * 1.5)
                pdfView.go(to: destination)
                print("scaleFactor: \(pdfView.scaleFactor)")
            }
        }
    }
}

var counter:Int = 0
// trying to hide menu that pops up on double click once in while. "Look Up Share... Copy Select Send To..."
extension PDFView {
    override public func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        print("\(counter) try to turn off PDF menu")
        counter += 1
        return false
    }
}
