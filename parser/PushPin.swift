//
//  PushPin.swift
//  parser
//
//  Created by Brittney Bearly on 3/2/20.
//  Copyright © 2020 Tammy Bearly. All rights reserved.
// from example https://pspdfkit.com/blog/2019/image-annotation-via-pdfkit/

import UIKit
import PDFKit

class PushPin: PDFAnnotation {
    var image: UIImage?
    
    convenience init(_ image: UIImage?, bounds: CGRect, properties: [AnyHashable : Any]?) {
        // pass an image and bounding rectangle
        self.init(bounds: bounds, forType: PDFAnnotationSubtype.stamp, withProperties: properties)
        self.image = image
    }
    
    override func draw(with box: PDFDisplayBox, in context: CGContext){
        // Draw original content under the new content.
        super.draw(with: box, in: context)
        
        // Drawing the image within the annotation's bounds.
        guard let cgImage = image?.cgImage else { return }
        context.draw(cgImage, in: bounds)
    }
}
