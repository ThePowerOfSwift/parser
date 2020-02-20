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

class ViewController: UIViewController {

    let pdfView = PDFView()//
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        if let pdfFileURL = Bundle.main.url(forResource: "Wellington",withExtension: "pdf"){
            print ("pdf file =  \(pdfFileURL)")
            // OPEN PDF
            
            pdfView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(pdfView)
            pdfView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
            pdfView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
            pdfView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
            pdfView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
            if let document = PDFDocument(url: pdfFileURL){
                pdfView.document = document
            
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
                let doubleScreenTap = UITapGestureRecognizer(target: view, action: #selector(zoomIn(_:)))
                doubleScreenTap.numberOfTapsRequired = 2
                doubleScreenTap.numberOfTouchesRequired = 1
                view.addGestureRecognizer(doubleScreenTap)
                
                // scrolling direction
                //pdfView.displayDirection = .vertical
                //pdfView.displayDirection = .horizontal
                
            }
            
            //let jsonFileURL = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("output.json")
            //PDFParser.parse(pdfUrl: pdfFileURL, into: jsonFileURL)
            // Parse PDF into Dictionary.
            let pdf: [String:Any?] = PDFParser.parse(pdfUrl: pdfFileURL)
            print (pdf)
        }
        else {
            print ("error file not found")
            return
        }
    }
    
    @IBAction func zoomIn(_ gestureRecognizer: UITapGestureRecognizer)
        // double tap zoom in
    {
        print("double tap")
         if gestureRecognizer.state == .ended
         {
            
              if let currentPage = pdfView.currentPage
              {
                   let point = gestureRecognizer.location(in: pdfView)
                   let destination = PDFDestination(page: currentPage, at: point)
                   destination.zoom = (pdfView.scaleFactor * 1.5)
                   pdfView.go(to: destination)
            }
        }
    }


}

