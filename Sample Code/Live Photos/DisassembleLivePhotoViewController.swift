//
//  DisassembleLivePhotoViewController.swift
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

var livePhotoResourcesFolderName = "Live-Photo-Resources"

class DisassembleLivePhotoViewController: BaseLivePhotoViewController {
    
    var photoURL: URL?
    var videoURL: URL?
    var audioPlayer: AVAudioPlayer?
    
    @IBOutlet var pickLivePhotoButton: UIButton!
    @IBOutlet var saveKeyPhotoButton: UIButton!
    @IBOutlet var savePairedVideoButton: UIButton!

    @IBAction func pickLivePhoto(_ sender: AnyObject) {
        let picker = UIImagePickerController()
        picker.sourceType = UIImagePickerControllerSourceType.photoLibrary
        picker.allowsEditing = false
        picker.delegate = self
        
        picker.mediaTypes = [kUTTypeLivePhoto, kUTTypeImage] as [String]
        
        present(picker, animated: true, completion: nil)
    }
    
    func playAudioURL(_ url:URL) {
        
        do {
            
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            guard let player = audioPlayer else { return }
            
            player.prepareToPlay()
            player.play()
            
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    func playLoadSound(_ itemTitle: String) {

        var url = Bundle.main.url(forResource: itemTitle, withExtension: "wav")
        
        if url != nil {
            self.playAudioURL(url!)
        }
        else {
            url = Bundle.main.url(forResource: itemTitle, withExtension: "m4a")
            if url != nil {
                self.playAudioURL(url!)
            }
        }
    }
    
    func updateStatus(_ string: String?, showActivity: Bool) {
        DispatchQueue.main.async {
            if showActivity {
                self.activityView.startAnimating()
            } else {
                self.activityView.stopAnimating()
            }
            self.statusLabel.text = string
        }
    }
    
    @IBAction func saveVideo() {
        if let pairedVideoPath = videoURL?.path  {
            if FileManager.default.fileExists(atPath: pairedVideoPath) {
                updateStatus("Saving Video...", showActivity: true)
                PHPhotoLibrary.shared().performChanges({
                    let videoURL = URL(fileURLWithPath: pairedVideoPath)
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoURL)
                }) { (success, error) -> Void in
                    self.updateStatus(nil, showActivity: false)
                    if success == false {
                        if let errorString = error?.localizedDescription  {
                            self.postAlert("Video Not Saved", message:errorString)
                        }
                    }
                    else {
                        self.postAlert("Video Saved", message:"The video was successfully saved to Photos.")
                    }
                }
            }
            else {
                self.playLoadSound("Basso")
            }
        }
        else {
            self.playLoadSound("Basso")
        }
    }
    
    @IBAction func savePhoto() {
        if let keyPhotoPath = photoURL?.path  {
            if FileManager.default.fileExists(atPath: keyPhotoPath) {
                updateStatus("Saving photo...", showActivity: true)
                PHPhotoLibrary.shared().performChanges({
                    let imageURL = URL(fileURLWithPath: keyPhotoPath)
                    PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: imageURL)
                }) { (success, error) -> Void in
                    self.updateStatus(nil, showActivity: false)
                    if success == false {
                        if let errorString = error?.localizedDescription  {
                            self.postAlert("Photo Not Saved", message:errorString)
                        }
                    }
                    else {
                        self.postAlert("Photo Saved", message:"The photo was successfully saved to Photos.")
                    }
                }
            }
            else {
                self.playLoadSound("Basso")
            }
        }
        else {
            self.playLoadSound("Basso")
        }
        
    }
    
    private func disassembleLivePhoto() {
        guard let livePhoto = self.livePhotoView.livePhoto else {
            self.postAlert("Live Photo Missing.", message:"Pick a live photo and try again.")
            return
        }
        
        updateStatus("Extracting resources...", showActivity: true)
        
        LivePhoto.extractResources(from: livePhoto, completion: { resources in
            self.photoURL = resources?.pairedImage
            self.videoURL = resources?.pairedVideo
            if let keyPhotoPath = self.photoURL {
                if FileManager.default.fileExists(atPath: keyPhotoPath.path) {
                    guard let keyPhotoImage = UIImage(contentsOfFile: keyPhotoPath.path) else {
                        return
                    }
                    self.keyPhotoView.image = keyPhotoImage
                }
            }
            if let pairedVideoPath = self.videoURL?.path  {
                if FileManager.default.fileExists(atPath: pairedVideoPath) {
                    let fileURL = URL(fileURLWithPath: pairedVideoPath)
                    self.playVideo(fileURL)
                }
            }
            self.updateStatus(nil, showActivity: false)
        })
    }
    
    // MARK: UIImagePickerControllerDelegate
    override func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let mediaType = info[UIImagePickerControllerMediaType] as! NSString
        if mediaType == kUTTypeLivePhoto {
            guard let livePhoto = info[UIImagePickerControllerLivePhoto] as? PHLivePhoto else {
                self.postAlert("Photo Picker", message: "Could not retrieve the picked photo.")
                return;
            }
            self.livePhotoView.livePhoto = livePhoto
            disassembleLivePhoto()
        } else {
            self.postAlert("It seems a live photo was not selected.", message:"Try again.")
        }
        dismiss(animated: true)
    }
    
}

