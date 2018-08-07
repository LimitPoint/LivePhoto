//
//  AssembleLivePhotoViewController.swift
//  Live Photos
//
//  Created by Joe Pagliaro on 3/2/18.
//  Copyright © 2018 Limit Point LLC. All rights reserved.
//

import UIKit

import Photos
import PhotosUI
import MobileCoreServices
import AVFoundation
import AVKit

class AssembleLivePhotoViewController: BaseLivePhotoViewController{
    
    private let pickedVideoName = "pickedExportedVideo.mov" // for exporting AVURLAsset to Documents
    
    @IBOutlet var pickKeyPhotoButton: UIButton!
    @IBOutlet var pickPairedVideoButton: UIButton!
    @IBOutlet var assembleLivePhotoButton: UIButton!
    
    var pickedPhoto: UIImage?
    var pickedVideoURL: URL?

    @IBAction func pickPhoto(_ sender: AnyObject) {
        let picker = UIImagePickerController()
        picker.sourceType = UIImagePickerControllerSourceType.photoLibrary
        picker.allowsEditing = false
        picker.delegate = self
        picker.mediaTypes = [kUTTypeLivePhoto as String, kUTTypeImage as String]
        present(picker, animated: true, completion: nil)
    }
    
    @IBAction func pickVideo(_ sender: AnyObject) {
        let picker = UIImagePickerController()
        picker.sourceType = UIImagePickerControllerSourceType.savedPhotosAlbum
        picker.videoQuality = .typeHigh
        picker.mediaTypes = [kUTTypeMovie as String, kUTTypeVideo as String, kUTTypeQuickTimeMovie as String]
        picker.allowsEditing = false
        picker.delegate = self
        present(picker, animated: true, completion: nil)
    }
    
    @IBAction func assembleLivePhoto(_ sender: AnyObject) {
        guard let sourceVideoPath = self.pickedVideoURL else {
            self.postAlert("It seems a video was not selected.", message:"Try again.")
            return
        }
        var photoURL: URL?
        if let sourceKeyPhoto = self.pickedPhoto {
            guard let data = UIImageJPEGRepresentation(sourceKeyPhoto, 1.0) else { return }
            photoURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("photo.jpg")
            if let photoURL = photoURL {
                try? data.write(to: photoURL)
            }
        }
        LivePhoto.generate(from: photoURL, videoURL: sourceVideoPath, progress: { (percent) in
            DispatchQueue.main.async {
                self.progressView.progress = Float(percent)
            }
        }) { (livePhoto, resources) in
            self.livePhotoView.livePhoto = livePhoto
            if let resources = resources {
                LivePhoto.saveToLibrary(resources, completion: { (success) in
                    if success {
                        self.postAlert("Live Photo Saved", message:"The live photo was successfully saved to Photos.")
                    }
                    else {
                        self.postAlert("Live Photo Not Saved", message:"The live photo was not saved to Photos.")
                    }
                })
            }
        }
    }

    // MARK: UIImagePickerControllerDelegate
    
    func didPickVideo(_ videoURL:URL) -> Void {
        self.pickedVideoURL = videoURL
        self.playVideo(videoURL)
    }
    
    func retrieveVideoByPHAsset(_ info: [String : Any]) -> Bool {
        
        var byPHAsset = false
        
        if #available(iOS 11.0, *) {
            
            let something = info[UIImagePickerControllerPHAsset]
            
            if let phasset = something as? PHAsset  {
                
                let options = PHVideoRequestOptions()
                
                options.isNetworkAccessAllowed = true
                options.deliveryMode = .highQualityFormat
                
                let imageManager = PHImageManager.default()
                
                byPHAsset = true
                
                imageManager.requestAVAsset(forVideo: phasset, options: options, resultHandler: { (avAsset, avAudioMix, info) in
                    if let urlAsset = avAsset as? AVURLAsset {
                        let _ = urlAsset.self.exportToDocuments(filename: self.pickedVideoName, completion: { (outputURL) in
                            
                            self.didPickVideo(outputURL)
                        })
                    }
                })
            }
        }
        
        return byPHAsset
    }
    
    func retrieveVideoByReferenceURL(_ info: [String : Any]) -> Bool {
        
        var byReferenceURL = false
        
        if let videoURL = info[UIImagePickerControllerReferenceURL] as? URL  {
            
            let asset = AVURLAsset(url:videoURL)
            
            byReferenceURL = asset.self.exportToDocuments(filename: self.pickedVideoName, completion: { (outputURL) in
                
                self.didPickVideo(outputURL)
            })
        }
        
        return byReferenceURL
    }
    
    override func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        let mediaType = info[UIImagePickerControllerMediaType] as! NSString
        
        dismiss(animated: true) {
            
            if mediaType == kUTTypeMovie || mediaType == kUTTypeVideo || mediaType == kUTTypeQuickTimeMovie {
                
                if self.retrieveVideoByPHAsset(info) == false {
                    
                    if self.retrieveVideoByReferenceURL(info) == false {
                        
                        if  let videoURL = info[UIImagePickerControllerMediaURL] as? URL  {
                            
                            self.didPickVideo(videoURL)
                        }
                    }
                }

            }
            else if mediaType == kUTTypeImage || mediaType == kUTTypeLivePhoto {
                
                guard let image = (info[UIImagePickerControllerOriginalImage] as? UIImage) else {
                    self.postAlert("Photo Picker", message: "Could not retrieve the picked photo.")
                    return
                }
                
                self.pickedPhoto = image
                
                DispatchQueue.main.async {
                    self.keyPhotoView.image = image
                }
            }
        }
    }
}

