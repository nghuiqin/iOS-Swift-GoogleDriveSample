//
//  ViewController.swift
//  GoogleDriveSample
//
//  Created by Ng Hui Qin on 4/9/15.
//  Copyright (c) 2015 huiqin.testing. All rights reserved.
//

import UIKit
import MobileCoreServices

class ViewController: UIViewController , UINavigationControllerDelegate ,UIImagePickerControllerDelegate {
  var window: UIWindow?
  let driveService : GTLServiceDrive =  GTLServiceDrive()
  
  let scopes = "https://www.googleapis.com/auth/drive.file"
  let kKeychainItemName : NSString = "Google Drive Quickstart"
  let kClientID = "Your Client ID"
  let kClientSecret = "Your Client Secret"
  
  func showWaitIndicator(title:String) -> UIAlertView {
    var progressAlert = UIAlertView()
    progressAlert.title = title
    progressAlert.message = "Please Wait...."
    progressAlert.show()
    
    let activityView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.White)
    activityView.center = CGPointMake(progressAlert.bounds.size.width / 2, progressAlert.bounds.size.height - 45)
    progressAlert.addSubview(activityView)
    activityView.hidesWhenStopped = true
    activityView.startAnimating()
    return progressAlert
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.driveService.authorizer  = GTMOAuth2ViewControllerTouch.authForGoogleFromKeychainForName(kKeychainItemName,
      clientID: kClientID,
      clientSecret: kClientSecret)
  }
  
  override func viewDidAppear(animated: Bool) {
    self.showCamera()
  }
  
  
  func showCamera() {
    var cameraUI = UIImagePickerController()
    if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera) {
      cameraUI.sourceType = UIImagePickerControllerSourceType.Camera
    } else {
      cameraUI.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
      if UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Pad {
        self.showAlert("Error", message: "Ipad Simulator not supported")
        return
      }
    }
    
    cameraUI.mediaTypes = [kUTTypeImage as String]
    cameraUI.allowsEditing = true
    cameraUI.delegate = self
    self.presentViewController(cameraUI, animated: true, completion: nil)
    println("Show Camera \(self.isAuthorized())")
    if (!self.isAuthorized())
    {
      // Not yet authorized, request authorization and push the login UI onto the navigation stack.
      cameraUI.pushViewController(self.createAuthController(), animated:true);
    }
  }
  // Handle selection of an image
  func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info:NSDictionary) {
    println("imagePickerController didFinishPickingMediaWithInfo")
    let image = info.valueForKey(UIImagePickerControllerOriginalImage) as UIImage
    self.dismissViewControllerAnimated(true, completion: nil)
    self.uploadPhoto(image)
    
  }
  
  // Handle cancel from image picker/camera.
  
  func imagePickerControllerDidCancel(picker: UIImagePickerController){
    self.dismissViewControllerAnimated(true, completion: nil)
  }
  
  // Helper to check if user is authorized
  func isAuthorized() -> Bool {
    return (self.driveService.authorizer as GTMOAuth2Authentication).canAuthorize
  }
  
  // Creates the auth controller for authorizing access to Google Drive.
  func createAuthController() -> GTMOAuth2ViewControllerTouch {
    return GTMOAuth2ViewControllerTouch(scope: kGTLAuthScopeDriveFile,
      clientID: kClientID,
      clientSecret: kClientSecret,
      keychainItemName: kKeychainItemName,
      delegate: self,
      finishedSelector: Selector("viewController:finishedWithAuth:error:"))
    
  }
  //     “func join(string s1: String, toString s2: String, withJoiner joiner: String)”
  
  // Handle completion of the authorization process, and updates the Drive service
  // with the new credentials.
  func viewController(viewController: GTMOAuth2ViewControllerTouch , finishedWithAuth authResult: GTMOAuth2Authentication , error:NSError? ) {
    if let error = error
    {
      self.showAlert("Authentication Error", message:error.localizedDescription)
      self.driveService.authorizer = nil
    } else {
      println("Authentication success")
      self.driveService.authorizer = authResult
    }
    
  }
  
  
  // Uploads a photo to Google Drive
  func uploadPhoto(image: UIImage) {
    println("uploading Photo")
    let dateFormat  = NSDateFormatter()
    dateFormat.dateFormat = "'Quickstart Uploaded File ('EEEE MMMM d, YYYY h:mm a, zzz')"
    
    let file = GTLDriveFile.object() as GTLDriveFile
    file.title = dateFormat.stringFromDate(NSDate())
    file.descriptionProperty = "Uploaded from Google Drive IOS"
    file.mimeType = "image/png"
    
    let data = UIImagePNGRepresentation(image)
    let uploadParameters = GTLUploadParameters(data: data, MIMEType: file.mimeType)
    let query = GTLQueryDrive.queryForFilesInsertWithObject(file, uploadParameters: uploadParameters) as GTLQueryDrive
    let waitIndicator = self.showWaitIndicator("Uploading To Google Drive")
    
    self.driveService.executeQuery(query, completionHandler:  { (ticket, insertedFile , error) -> Void in
      let myFile = insertedFile as? GTLDriveFile
      
      waitIndicator.dismissWithClickedButtonIndex(0, animated: true)
      if error == nil {
        println("File ID \(myFile?.identifier)")
        self.showAlert("Google Drive", message: "File Saved")
      } else {
        println("An Error Occurred! \(error)")
        self.showAlert("Google Drive", message: "Sorry, an error occurred!")
      }
      
    })
  }
  
  func showAlert(title: String, message: String ) {
    let cancel = "OK"
    println("show Alert")
    let alert = UIAlertView()
    alert.title = title
    alert.message = message
    alert.addButtonWithTitle(cancel)
    alert.show()
  }
  
}


