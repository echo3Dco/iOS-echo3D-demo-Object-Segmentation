//
//  APIRequest.swift
//  Object-Segmentation
//
//  Created by EchoAR on 7/7/20.
//  Copyright © 2020 EchoAR. All rights reserved.
//

import Foundation
import UIKit

// Custom Type of Parameters for httpBody
typealias Parameters = [String: String]


/*
   ApiError enum of type Error:
        - responseProblem: Issues with the API Response
        - decodingProblem: Used when error occurs while decoding the response
        - encodingProbelem: Used when error occurs while encoding httpBody
 */
enum APIError:Error {
    case responseProblem
    case incorrectKeyProblem
    case encodingProblem
}


/*
 Extension to the Data method to append encoded string to httpBody
 */
extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}


/**
    API Request Struct to Create an API Request and Upload Image to the echoAR console.
    - Usage:
        - Creating API Request:
            `let postRequest = APIRequest()`
 
        - Sending API Request:
             postRequest.send(imageToSend, nameOfImage, EchoARAPIKey, completion: {
                 result in switch result {
                 case .failure(let error):
                     print("Error Occurred \(error)")
                 case .success(_):
                     print("Success Uploading")
                 }
             })
            
 */

struct APIRequest {
    
    /*
        - resourceUrl: URL For the POST Request ("https://console.echoAR.xyz/upload")
    */
    let resourceUrl: URL
    
    /*
       - Constructor for creating API Request
     */
    init() {
        guard let resourceURL = URL(string: "https://console.echoAR.xyz/upload") else {fatalError()}
        self.resourceUrl = resourceURL
    }
    
    /*
        Use this method to create and send HTTP-POST request to the EchoAR Console.
        Image data is first converted to an Media Object and then it is added to httpBody data.
        
        - Parameters:
            - image: The UIImage you need to upload to the console
            - imageName: The name of the image
            - echoARApiKey: Your API key
            - completion: Escaping Closure which is passed as an arguement to the function but is called after function returns. It return Result type that has two cases: success and failure, where the success case will return a string and the failure case will be some sort of API Error.
        
        - Return: Invokes completion Handler passed as an arguement.
    */
    func send(_ image: UIImage, _ imageName: String, _ echoARApiKey: String, completion: @escaping(Result<String, APIError>) -> Void) {
        
        do {
            
            // Created an Media Object using ImageName and image
            guard let mediaImage = Media(withImage: image, forKey: "file_image_hologram", withName: imageName) else { return }
            
            // Ford Data parameters
            let formFields = ["key": echoARApiKey, "target_type": "2", "hologram_type": "1"]
            
            // request object for URL Request
            var request = URLRequest(url: self.resourceUrl)
            
            // Set request httpMethod to "POST"
            request.httpMethod = "POST"
            
            // Generate Boundary String for HTTP-Body
            let boundary = generateBoundary()
            
            // Set the "Content-Type" httpHeaderField to "multipart/form-data"
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            
            // Creating data-body for the HTTP - Request.
            let dataBody = createDataBody(withParameters: formFields, media: [mediaImage], boundary: boundary)
            
            request.httpBody = dataBody
            
            // Create shared URL Session for the POST Request with `request` object
            let session = URLSession.shared
            session.dataTask(with: request) { (data, response, error) in
                
                // Checks if the response is valid HTTPURLResponse and if status code is 200.
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else{
                    
                    // If invalid httpResponse, return "responseProblem APIError"
                    completion(.failure(.responseProblem))
                    return
                }
                
                // Extract data from the response
                if let data = data {
                    do {
                        // Converts JSON data object and return ".success" Result
                        let json = try JSONSerialization.jsonObject(with: data, options: [])
                        print(json)
                        completion(.success("Succesfully Saved"))
                        
                    } catch {
                        
                        // If not able to decode return ".decoding failure"
                        completion(.failure(.incorrectKeyProblem))
                    }
                }
            }.resume()
            
        } catch {
            // Otherwise encoding failute
            completion(.failure(.encodingProblem))
        }
        
    }
    
    
    /**
     Configures the httpBody for `multipart/form-data`.
     
        - Parameter parameters: Parameters for the httpRequest:
                - API Key
                - Target Type
                - Hologram Type
     
        - `Media`: Image which needs to be uploaded
        
        - `Boundary`: Randomnly generated boundary string for the data
     */
    func createDataBody(withParameters params: Parameters?, media: [Media]?, boundary: String) -> Data {
        
        let lineBreak = "\r\n"
        var body = Data()
        
        if let parameters = params {
            for (key, value) in parameters {
                body.append("--\(boundary + lineBreak)")
                body.append("Content-Disposition: form-data; name=\"\(key)\"\(lineBreak + lineBreak)")
                body.append("\(value + lineBreak)")
            }
        }
        
        if let media = media {
            for photo in media {
                body.append("--\(boundary + lineBreak)")
                body.append("Content-Disposition: form-data; name=\"\(photo.key)\"; filename=\"\(photo.filename)\"\(lineBreak)")
                body.append("Content-Type: \(photo.mimeType + lineBreak + lineBreak)")
                body.append(photo.data)
                body.append(lineBreak)
            }
        }
        
        body.append("--\(boundary)--\(lineBreak)")
        
        return body
    }
    
    /**
     Function randomnly generates boundary string which is used to separate different field name and value. The boundary string has to be specified in the HTTP header content-type field
     */
    func generateBoundary() -> String {
        return "Boundary-\(NSUUID().uuidString)"
    }
    
}
