# iOS-echo3D-demo-Object-Segmentation
Foreground extraction iOS application. The app let's the user to select an image, extract foreground and upload the image object to the echo3D console.

## Register
If you don't have an echo3D API key yet, make sure to register for FREE at [echo3D](https://console.echo3D.co/#/auth/register).

## Installation
- Clone the project from the github repository.
- Open up Xcode and select 'open an existing project'.
- Connect an IOS Device and build the project.

## Usage
- Open the application and you will see the home screen.
  <br> <br> <img src="./Screenshots/homeScreen.PNG" width=300 height = 500>
- There are two options at the top-right corner of the navigation bar.
  - Photogallery: If you want to choose image from photo-gallery.
  - Camera: If you choose to take an new image.

- After choosing an image either from camera or photogallery, click "Begin Button" to start foreground extraction
    <br> <br> <img src="./Screenshots/OriginalImage.PNG" width=300 height = 500> 

- Original Image will be processed to extract the foreground.
    <br> <br> <img src="./Screenshots/maskedImage.PNG" width=300 height = 500> 

- If you wish to upload image to the echo3D console, click on the upload button at the top left corner.
  - There will be a prompt to enter API key.
  <br><br> <img src="./Screenshots/apiKeyPromp.PNG" width=300 height = 500> 
  - After entering API-Key, enter the name of the image and click on Upload.
     <br><br> <img src="./Screenshots/uploadKeyPromp.PNG" width=300 height = 500> 
  - Image will be available at the console and can be used for different projects.
     <br><br> <img src="./Screenshots/console.png" width=300 height = 500>  

## Creating APIRequest
If you want to add image upload functionality to your custom application, add `APIRequest.swift` and `Media.swift` to your project folder.

- To make an http-post request create an `APIRequest` object: 
    <br>
    ```
    let postRequest = APIRequest()
    ```
    
- To send the post request use `send()` instance method of `APIRequest`, which accepts these parameters:
   - `image` (type: UIimage): The UIImage you need to upload to the console
   - `imageName` (type: String): The name of the image
   - `echoARApiKey` (type: String) : Your API key
   - `completion` (type: closure): Escaping Closure which is passed as an arguement to the function but is called after function returns. It return Result type that has two cases: success and failure, where the success case will return a string and the failure case will be some sort of API Error.
```
let postRequest = APIRequest()
postRequest.send(imageToPost: UIimage,fileName: String, APIKey: String, completion: {
    result in switch result {
    case .success(_):
        print("Success Uploading")
    case .failure(.incorrectKeyProblem):
        self.createErrorAlert("Incorrect Key", "Please Check key and Try again")
        print("Incorrect Key")
    case .failure(let error):
        print("Error Occurred \(error)")
    
    }
})
```

- Post Request performs `multipart/form-data` httpRequest, where key-value pair are seperated with the randomnly generated boundary string. 
- Post Request only works for `target_type = 2`, `hologram_type = 1`  and image is sent as `file_image_hologram`. 

### APIErrors:
- Closure which is passed as an `send(_)` request return `.success` or `.failure`, where `.failure` is type of `APIError`:
    - responseProblem: Problem with the API Response
    - decodingProblem: Error decoding API Response data
    - incorrectKeyProblem: Incorrect API Key
    
   
## Learn more
Refer to our [documentation](https://docs.echo3D.co/unity/) to learn more about how to use Unity, AR Foundation, and echo3D.

## Support
Feel free to reach out at [support@echo3D.co](mailto:support@echo3D.co) or join our [support channel on Slack](https://go.echo3D.co/join). 

## Screenshots
![screenshot5](/Screenshots/clockOriginalImage.png)
![screenshot6](/Screenshots/clockMaskImage.PNG)
