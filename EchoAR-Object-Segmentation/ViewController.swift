//
//  ViewController.swift
//  Object-Segmentation
//
//  Created by EchoAR on 6/22/20.
//  Copyright © 2020 EchoAR. All rights reserved.
//

import UIKit
import Vision

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    
    /*
     Image Vie for the Application
     */
    let imageView: UIImageView = {
        let img = UIImageView()
        img.image = UIImage(systemName: "hare.fill")
        img.contentMode = .scaleToFill
        img.translatesAutoresizingMaskIntoConstraints = false
        img.tintColor = .black
        return img
    }()
    
   
    // Button for start image segmentation and masking.
    let startSegmentationButton : UIButton = {
        let btn = UIButton(type: .system)
        btn.addTarget(self, action: #selector(handleStartSegmentationButton), for: .touchUpInside)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.backgroundColor = .gray
        btn.layer.cornerRadius = 5
        btn.tintColor = .white
        btn.layer.masksToBounds  = true
        btn.setTitle("Begin", for: .normal)
        btn.isHidden = true
        return btn
    }()
    
    
    
    //var imageSegmentationModel = DeepLabV3()
    
    // Image Segmentation model
    var imageSegmentationModel = U2NetUpdate()
    
    // Mask of the original image
    var maskImage: UIImage?
    
    // masked Image output
    var segmentedImage: UIImage?
    
    // original image
    var originalImage: UIImage?
    
    // request of type VNCoreMLRequest for performing Core-ML Vision Request
    var request :  VNCoreMLRequest?
    
    // URL Of the original image
    var imageURL : URL?
    
    // EchoAR API key
    var echoARAPIKey: String?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        // Do any additional setup after loading the view.
        view.backgroundColor = .white
        
        // Add cameraButton, photogallerybutton and Image Upload button on the navigationBar Controller
        let cameraBarButton = UIBarButtonItem(image: UIImage(systemName: "camera.circle.fill"),style: .done, target: self, action: #selector(handleCameraButtonTapped))
        
        let photoGalleryButton = UIBarButtonItem(image: UIImage(systemName: "photo.on.rectangle"), style: .done, target: self, action: #selector(handlePhotoGalleryTapped))
        
        let cloudUploadButton = UIBarButtonItem(image: UIImage(systemName: "square.and.arrow.up.fill"), style: .done, target: self, action: #selector(handleImageUpload))
        self.navigationItem.rightBarButtonItems = [cameraBarButton,photoGalleryButton]
        self.navigationItem.leftBarButtonItems = [cloudUploadButton]
        self.title = "Image Segmentation"
        setupViews()
        layoutViews()
        setUpModel()
    }
    
    // Set up all the views.
    func setupViews() {
        view.addSubview(imageView)
        view.addSubview(startSegmentationButton)
    }
    
    // Layout constraints to the views.
    func layoutViews() {
        
        imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: 400).isActive = true
        imageView.widthAnchor.constraint(equalToConstant: 400).isActive = true
        
        startSegmentationButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 250).isActive = true
        startSegmentationButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40).isActive = true
        startSegmentationButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40).isActive = true
        startSegmentationButton.heightAnchor.constraint(equalToConstant: 60).isActive = true
        
    }
    
    // Apply mask to the original image and return UIImage.
    func maskOriginalImage() -> UIImage? {
        if(self.maskImage != nil && self.originalImage != nil){
            let maskReference = self.maskImage?.cgImage!
            let maskedReference = self.originalImage?.cgImage!.masking(maskReference!)
            self.maskImage = nil
            return UIImage(cgImage: maskedReference!)
        }
        return nil
    }
    
    // Set up the VNCoreMLModel for performing vision request, and add completion handler.
    func setUpModel() {
        if let visionModel = try? VNCoreMLModel(for: imageSegmentationModel.model) {
            request = VNCoreMLRequest(model: visionModel, completionHandler: visionRequestDidComplete)
            
            request?.imageCropAndScaleOption = .scaleFill
            
        } else {
            fatalError()
        }
        
    }
    
    // Image picker controller to pick the image.
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let image = info[.originalImage] as? UIImage{
            print("picked")
            
            // assigns image to imageView
            self.imageView.image = image
            
            // make startSegmentationButton visible
            self.startSegmentationButton.isHidden = false
            
            // fix the orientation of the original image.
            self.originalImage = image.fixOrientation()
            dismiss(animated: true, completion: nil)
            
        }
    }
    
    
    // function to perform VNCoremML Request
    func predict(customRequest: VNCoreMLRequest?, customImage: UIImage?) {
        DispatchQueue.global(qos: .userInitiated).async {
            guard let request = customRequest else { fatalError() }
            let handler = VNImageRequestHandler(cgImage: (customImage?.cgImage)!, options: [:])
            do {
                print("Request Made")
                try handler.perform([request])
            }catch {
                print(error)
            }
        }
    }
    
    // function to receive segmented output from Core-ML model and perform post-processing.
    func visionRequestDidComplete(request: VNRequest, error: Error?) {
        DispatchQueue.main.async {
            
            /*
             Checks if the output is of type PixelBuffer or MultiArray:
                - U2-Net return CVPixelBuffer
                - Deep-Lab returns MLMultiArray
            */
            if let observations = request.results as? [VNPixelBufferObservation],
               let segmentationmap = observations.first?.pixelBuffer {
                self.maskImage = segmentationmap.createImage()
            }else if let observations = request.results as? [VNCoreMLFeatureValueObservation],
                     let segmentationmap = observations.first?.featureValue.multiArrayValue {
                self.maskImage = segmentationmap.image(min: 0, max: 255)
            }
            
            // Resize maskImage to the size of original image.
            if(self.maskImage != nil){
                self.maskImage = self.maskImage?.resizeImage(for: self.originalImage!.size)
            }
            
            // Apply mask to the original image
            if var image:UIImage = self.maskOriginalImage(){
                print("Success")
                image = image.createImageFromContext()!
                self.imageView.image = image
                self.originalImage = nil
                self.segmentedImage = image
                self.startSegmentationButton.setTitle("Done", for: .normal)
            }else {
                print("failure")
                self.imageView.image = self.originalImage
                self.startSegmentationButton.setTitle("Failed Try Again", for: .normal)
            }
        }
    }
    
    
    func showImagePickerController(sourceType: UIImagePickerController.SourceType) {
        if(UIImagePickerController.isSourceTypeAvailable(sourceType)){
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = sourceType
            self.present(imagePicker, animated: true, completion: nil)
        }
        self.startSegmentationButton.isHidden = true
        self.startSegmentationButton.setTitle("Begin", for: .normal)
    }
    
    
    
    
    // MARK: - Handlers
    
    @objc func handlePhotoGalleryTapped() {
        showImagePickerController(sourceType: .photoLibrary)
    }
    @objc func handleCameraButtonTapped() {
        print("Camera Button Tapped")
        showImagePickerController(sourceType: .camera)
    }
    
    // handler activated when startSegmentationButton is pressed
    @objc func handleStartSegmentationButton() {
        self.startSegmentationButton.setTitle("In Progress...", for: .normal)
        guard (self.originalImage != nil) else { return }
        self.predict(customRequest: self.request, customImage: self.originalImage)
        
    }
    
    // Alert for the user to enter API-Key
    @objc func apiKeyAlert(){
        let alertController = UIAlertController(title: "Hi", message: "Please Enter Your EchoAR API Key", preferredStyle: .alert)
        
        alertController.addTextField{textfield in textfield.placeholder = "Enter API Key"}
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alertController] (action) -> Void in
            guard let text = alertController?.textFields?.first?.text else {
                return
            }
            self.echoARAPIKey = text
        }))

        self.present(alertController, animated: true)
        
    }
    
    @objc func createErrorAlert(_ title: String, _ message: String){
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alertController, animated: true)
    }
    
    // Handler for handling ImageUpload
    @objc func handleImageUpload(){
        
        // Checks if APIKey is Present, if not creates a prompt for user to enter API-Key
        if(self.echoARAPIKey == nil){
            self.apiKeyAlert()
            return
        }
        let alertController = UIAlertController(title: "Hello", message: "You want to upload image to console", preferredStyle: .alert)
        
        if (self.segmentedImage != nil) {
            
            // Textfield to enter image name
            alertController.addTextField{textfield in textfield.placeholder = "Enter Name of Image (without image format extension)"}
            alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            alertController.addAction(UIAlertAction(title: "Update API Key", style: .default, handler: {
                _ in
                self.apiKeyAlert()
            }))
            alertController.addAction(UIAlertAction(title: "Upload", style: .default, handler: {_ in
                
                guard let text = alertController.textFields?.first?.text else {
                    print("No Text Available")
                    return
                }
                
                // Creates an API Request object and sends the POST request.
                
                print("API Request Created")
                let postRequest = APIRequest()
                postRequest.send(self.segmentedImage!,text, self.echoARAPIKey!, completion: {
                    result in switch result {
                    case .success(_):
                        print("Success Uploading")
                    case .failure(.incorrectKeyProblem):
                        self.createErrorAlert("Incorrect Key", "Please Check key and Try again")
                        print("Incorrect Key")
                    case .failure(let error):
                        print("Error Occurred \(error)")
                        self.createErrorAlert("Failed to Upload Image to Console", "Please try Again")
                    
                    }
                })
                
            }))
        }else {
            alertController.message = "Please Mask the Image First to Extract Object."
            alertController.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
        }
        self.present(alertController, animated: true)
    }
}

