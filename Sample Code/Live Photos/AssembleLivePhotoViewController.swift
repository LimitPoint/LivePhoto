//
//  AssembleLivePhotoViewController.swift
//  Live Photos
//
//  Read discussion at:
//  http://www.limit-point.com/blog/2018/live-photos/
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
    
    private let pickedVideoName = "pickedExportedVideo.mov"
    
    @IBOutlet var pickKeyPhotoButton: UIButton!
    @IBOutlet var pickPairedVideoButton: UIButton!
    @IBOutlet var assembleLivePhotoButton: UIButton!
    
    var pickedPhoto: UIImage?
    var pickedVideoURL: URL?
    
    @IBAction func pickPhoto(_ sender: AnyObject) {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.selectionLimit = 1
        config.filter = .any(of: [.livePhotos, .images]) // Allows selecting Live Photos and Images
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true, completion: nil)
    }
    
    @IBAction func pickVideo(_ sender: AnyObject) {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.selectionLimit = 1
        config.filter = .videos // Allows selecting only videos
        
        let picker = PHPickerViewController(configuration: config)
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

    // MARK: PHPickerViewControllerDelegate
    func retrieveVideoByPHAsset(_ phAsset: PHAsset) {
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        
        let imageManager = PHImageManager.default()
        
        imageManager.requestAVAsset(forVideo: phAsset, options: options) { avAsset, _, _ in
            if let urlAsset = avAsset as? AVURLAsset {
                let _ = urlAsset.exportToDocuments(filename: self.pickedVideoName) { outputURL in
                    DispatchQueue.main.async {
                        self.didPickVideo(outputURL)
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.postAlert("Video Picker", message: "Could not retrieve the video.")
                }
            }
        }
    }
    
        // MARK: - Handle Picked Video
    func didPickVideo(_ videoURL: URL) {
        self.pickedVideoURL = videoURL
        self.playVideo(videoURL)
    }
    
    override func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        guard let itemProvider = results.first?.itemProvider else { return }
        
        if itemProvider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
                // Attempt to retrieve the video via PHAsset first
            if let assetIdentifier = results.first?.assetIdentifier {
                let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [assetIdentifier], options: nil)
                if let phAsset = fetchResult.firstObject {
                    retrieveVideoByPHAsset(phAsset)
                    return
                }
            }
            
                // If PHAsset retrieval fails, attempt reference URL method
            itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { url, error in
                guard let url = url, error == nil else {
                    DispatchQueue.main.async {
                        self.postAlert("Video Picker", message: "Could not retrieve the picked video.")
                    }
                    return
                }
                
                DispatchQueue.main.async {
                    self.didPickVideo(url)
                }
            }
        } else if itemProvider.canLoadObject(ofClass: UIImage.self) {
            itemProvider.loadObject(ofClass: UIImage.self) { image, error in
                guard let image = image as? UIImage, error == nil else {
                    DispatchQueue.main.async {
                        self.postAlert("Photo Picker", message: "Could not retrieve the picked photo.")
                    }
                    return
                }
                
                DispatchQueue.main.async {
                    self.pickedPhoto = image
                    self.keyPhotoView.image = image
                }
            }
        }
    }
}

