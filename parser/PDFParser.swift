//
//  PDFParser.swift
//  PDFParser
//
//  Copyright (c) 2020 Geri Borbás http://www.twitter.com/_eppz
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
//https://stackoverflow.com/questions/2475450/extracting-images-from-a-pdf

import Foundation
import PDFKit


class PDFParser
{


    /// Undocumented enumeration case stands for `Object` type (sourced from an expection thrown).
    static let CGPDFObjectTypeObject: CGPDFObjectType = CGPDFObjectType(rawValue: 77696)!

    /// Shorthand for type strings.
    static let namesForTypes: [CGPDFObjectType:String] =
    [
        .null : "Null",
        .boolean : "Boolean",
        .integer : "Integer",
        .real : "Real",
        .name : "Name",
        .string : "String",
        .array : "Array",
        .dictionary : "Dictionary",
        .stream : "Stream",
        CGPDFObjectTypeObject : "Object",
    ]

    struct Message
    {
        static let parentNotSerialized = "<PARENT_NOT_SERIALIZED>"
        static let couldNotParseValue = "<COULD_NOT_PARSE_VALUE>"
        static let couldNotGetStreamData = "<COULD_NOT_GET_STREAM_DATA>"
        static let unknownStreamDataFormat = "<UNKNOWN_STREAM_DATA_FORMAT>"
    }

    /// Parse a PDF file into a JSON file.
    static func parse(pdfUrl: URL, into jsonURL: URL)
    {
        do
        {
            let pdf = PDFParser.parse(pdfUrl: pdfUrl)
            let data = try JSONSerialization.data(withJSONObject: pdf, options: .prettyPrinted)
            try data.write(to: jsonURL, options: [])
        }
        catch
        { print(error) }
    }

    /// Parse a PDF file into a JSON file.
    static func parse(pdfUrl: URL) -> [String:Any?]
    {
        // Document.
        guard
            let document = CGPDFDocument(pdfUrl as CFURL),
            let catalog = document.catalog,
            let info = document.info,
            let page = document.page(at: 1)
        else
        {
            print("Cannot open PDF.")
            return [:]
        }
        
        // get media box
        print(page.getBoxRect(CGPDFBox.mediaBox) )
        
        // get dictionary
        guard let dictionary = page.dictionary else {
            print ("error getting dictionary")
            return[ "error": "error getting dictionary"]
        }
        var resourcesRef: CGPDFDictionaryRef?
        guard CGPDFDictionaryGetDictionary(dictionary, "Resources", &resourcesRef),
        let resources = resourcesRef else {
            print ("could not read resources")
            return ["error": "could not read resources"]
        }
        var xObj: CGPDFDictionaryRef?
        guard CGPDFDictionaryGetDictionary(resources, "XObject", &xObj), let xObject = xObj else {
            print("Couldn't load page XObject.")
            return ["error": "Couldn't load page XObject."]
        }
        /*var stream: CGPDFStreamRef?
        guard CGPDFDictionaryGetStream(xObject, "Im0", &stream), let imageStream = stream else {
            print("No image on PDF page.")
            return ["error": "No image on PDF page."]
        }
        var format: CGPDFDataFormat = .raw
        guard let data = CGPDFStreamCopyData(imageStream, &format) else {
            print("Couldn't convert image stream to data.")
            return ["error": "Couldn't convert image stream to data."]
        }
        let image = UIImage(data: data as Data)*/
        
        // GET VP array of dictionaries
        var vp: CGPDFArrayRef?
        guard CGPDFDictionaryGetArray(dictionary,"VP",&vp), let vpArray = vp else {
            return ["error":"No VP"]
        }
        var maxBBoxHt: Float = 0.0
        var bboxValues = ""
        for index in 0 ..< CGPDFArrayGetCount(vpArray)
        {
            var eachDictRef: CGPDFDictionaryRef? = nil
            if
                CGPDFArrayGetDictionary(vpArray, index, &eachDictRef),
                let eachDict = eachDictRef
            {
            
                var bboxArrayRef: CGPDFArrayRef? = nil
                guard CGPDFDictionaryGetArray(eachDict, "BBox", &bboxArrayRef), let bboxArr = bboxArrayRef else{
                    continue
                }
                
                // Get values from BBox Array x1 y1 x2 y2
                var bboxValue:[CGFloat] = []
                let sp:String = " "
                for i in 0 ..< CGPDFArrayGetCount(bboxArr)
                {
                    //var bboxReal: CGPDFReal
                    var bboxValueRef: CGPDFReal = 0.0
                    CGPDFArrayGetNumber(bboxArr, i, &bboxValueRef)
                    //let num: CGFloat = bboxValueRef
                    bboxValue.append(bboxValueRef)
                }
                var ht:Float
                if bboxValue[1] > bboxValue[3] { ht = Float (bboxValue[1] - bboxValue[3]) }
                else { ht = Float (bboxValue[3] - bboxValue[1]) }
                if (ht > maxBBoxHt) {
                    maxBBoxHt = ht
                    bboxValues.append(bboxValue[0].description)
                    bboxValues.append(" ")
                    bboxValues.append(bboxValue[1].description)
                    bboxValues.append(" ")
                    bboxValues.append(bboxValue[2].description)
                    bboxValues.append(" ")
                    bboxValues.append(bboxValue[3].description)
                }
                
            }
            else {
                print("error")
            }
            
        }
        
        
        // Get PDF version
        var major: Int32 = 0
        var minor: Int32 = 0
         document.getVersion(majorVersion: &major, minorVersion: &minor)
        print("Version: \(major).\(minor)")
        // Parse.
        return [
            "Catalog" : PDFParser.value(from: catalog),
            "Info" : PDFParser.value(from: info)
        ]
    }

    static func value(from object: CGPDFObjectRef) -> Any?
    {
        switch (CGPDFObjectGetType(object))
        {
            case .null:

                return nil

            case .boolean:

                var valueRef: CGPDFBoolean = 0
                if CGPDFObjectGetValue(object, .boolean, &valueRef)
                { return Bool(valueRef == 0x01) }

            case .integer:

                var valueRef: CGPDFInteger = 0
                if CGPDFObjectGetValue(object, .integer, &valueRef)
                { return valueRef as Int }

            case .real:

                var valueRef: CGPDFReal = 0.0
                if CGPDFObjectGetValue(object, .real, &valueRef)
                { return Double(valueRef) }

            case .name:

                var objectRefOrNil: UnsafePointer<Int8>? = nil
                if
                    CGPDFObjectGetValue(object, .name, &objectRefOrNil),
                    let objectRef = objectRefOrNil,
                    let string = String(cString: objectRef, encoding: String.Encoding.isoLatin1)
                { return string }

            case .string:

                var objectRefOrNil: UnsafePointer<Int8>? = nil
                if
                    CGPDFObjectGetValue(object, .string, &objectRefOrNil),
                    let objectRef = objectRefOrNil,
                    let stringRef = CGPDFStringCopyTextString(OpaquePointer(objectRef))
                { return stringRef as String }

            case .array:

                var arrayRefOrNil: CGPDFArrayRef? = nil
                if
                    CGPDFObjectGetValue(object, .array, &arrayRefOrNil),
                    let arrayRef = arrayRefOrNil
                {
                    var array: [Any] = []
                    for index in 0 ..< CGPDFArrayGetCount(arrayRef)
                    {
                        var eachObjectRef: CGPDFObjectRef? = nil
                        if
                            CGPDFArrayGetObject(arrayRef, index, &eachObjectRef),
                            let eachObject = eachObjectRef,
                            let eachValue = PDFParser.value(from: eachObject)
                        { array.append(eachValue) }
                    }
                    return array
                }

            case .stream:

                var streamRefOrNil: CGPDFStreamRef? = nil
                if
                    CGPDFObjectGetValue(object, .stream, &streamRefOrNil),
                    let streamRef = streamRefOrNil,
                    let streamDictionaryRef = CGPDFStreamGetDictionary(streamRef)
                {
                    // Get stream dictionary.
                    var streamNSMutableDictionary = NSMutableDictionary()
                    Self.collectObjects(from: streamDictionaryRef, into: &streamNSMutableDictionary)
                    var streamDictionary = streamNSMutableDictionary as! [String: Any?]

                    // Get data.
                    var dataString: String? = Message.couldNotGetStreamData
                    var streamDataFormat: CGPDFDataFormat = .raw
                    if let streamData: CFData = CGPDFStreamCopyData(streamRef, &streamDataFormat)
                    {
                        switch streamDataFormat
                        {
                            case .raw: dataString = String(data: NSData(data: streamData as Data) as Data, encoding: String.Encoding.utf8)
                            case .jpegEncoded, .JPEG2000: dataString = NSData(data: streamData as Data).base64EncodedString()
                        @unknown default: dataString = Message.unknownStreamDataFormat
                        }
                    }

                    // Add to dictionary.
                    streamDictionary["Data"] = dataString

                    return streamDictionary
                }

            case .dictionary:

                var dictionaryRefOrNil: CGPDFDictionaryRef? = nil
                if
                    CGPDFObjectGetValue(object, .dictionary, &dictionaryRefOrNil),
                    let dictionaryRef = dictionaryRefOrNil
                {
                    var dictionary = NSMutableDictionary()
                    Self.collectObjects(from: dictionaryRef, into: &dictionary)
                    return dictionary as! [String: Any?]
                }

            case CGPDFObjectTypeObject:

                var dictionary = NSMutableDictionary()
                Self.collectObjects(from: object, into: &dictionary)
                return dictionary as! [String: Any?]

            @unknown default:

                return nil
        }

        // No known case.
        return nil
    }

    static func collectObjects(from dictionaryRef: CGPDFDictionaryRef, into dictionaryPointer: UnsafeMutableRawPointer?)
    {

        CGPDFDictionaryApplyFunction(
            dictionaryRef,
            {
                (eachKeyPointer, eachObject, eachContextOrNil: UnsafeMutableRawPointer?) -> Void in

                // Unwrap dictionary.
                guard let dictionary = eachContextOrNil?.assumingMemoryBound(to: NSMutableDictionary.self).pointee
                else { return print("Could not unwrap dictionary.") }

                // Unwrap key.
                guard let eachKey = String(cString: UnsafePointer<CChar>(eachKeyPointer), encoding: .isoLatin1)
                else { return print("Could not unwrap key.") }

                // Type.
                guard let eachTypeName = PDFParser.namesForTypes[CGPDFObjectGetType(eachObject)]
                else { return print("Could not unwrap type.") }

                // Assemble.
                let eachDictionaryKey = "\(eachKey)<\(eachTypeName)>" as NSString

                // Skip parent.
                guard eachKey != "Parent"
                else
                {
                    dictionary.setObject(Message.parentNotSerialized, forKey: eachDictionaryKey)
                    return
                }

                // Parse value.
                guard let eachValue = PDFParser.value(from: eachObject)
                else
                {
                    dictionary.setObject(Message.couldNotParseValue, forKey: eachDictionaryKey)
                    fatalError("😭")
                    // return
                }

                // Set.
                dictionary.setObject(eachValue, forKey: eachDictionaryKey)
            },
            dictionaryPointer
        )
    }
}

