//
//  BaseLivePhotoViewController.swift
//  Live Photos
//
//  Read discussion at:
//  http://www.limit-point.com/blog/2018/live-photos/
//
//  Created by Joe Pagliaro on 3/21/18.
//  Copyright © 2018 Limit Point LLC. All rights reserved.
//

import UIKit

import Photos
import PhotosUI
import MobileCoreServices
import AVFoundation
import AVKit

class BaseLivePhotoViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, PHLivePhotoViewDelegate {

    var playerController: AVPlayerViewController?
    var player: AVPlayer?
    var livePhotoBadgeLayer = CALayer()
    
    @IBOutlet var livePhotoView: PHLivePhotoView!
    @IBOutlet var activityView: UIActivityIndicatorView!
    @IBOutlet var statusLabel: UILabel!
    @IBOutlet var progressView: UIProgressView!
    @IBOutlet var keyPhotoView: UIImageView!
    @IBOutlet var pairedVideoView: UIImageView!
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.playerController?.view.frame = self.view.convert(self.pairedVideoView.frame, from: self.pairedVideoView.superview)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        statusLabel.text = nil
        livePhotoView.contentMode = .scaleAspectFit
        livePhotoView.delegate = self
        
        let livePhotoBadge = PHLivePhotoView.livePhotoBadgeImage(options: .overContent)
        
        guard let livePhotoBadgeImage = livePhotoBadge.cgImage else {
            return
        }
        
        self.livePhotoBadgeLayer.frame = livePhotoView.bounds
        self.livePhotoBadgeLayer.contentsGravity = kCAGravityTopLeft
        self.livePhotoBadgeLayer.isGeometryFlipped = true
        self.livePhotoBadgeLayer.contentsScale = UIScreen.main.scale
        
        self.livePhotoBadgeLayer.contents = livePhotoBadgeImage
        livePhotoView.layer.addSublayer(self.livePhotoBadgeLayer)
        
        playerController = AVPlayerViewController()
        if let playerView = playerController?.view {
            self.view.addSubview(playerView)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if self.livePhotoView.livePhoto != nil {
            self.livePhotoView.startPlayback(with: .hint)
            
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) { () -> Void in
                self.livePhotoView.stopPlayback()
            }
        }
        
        // Get the current authorization state.
        let status = PHPhotoLibrary.authorizationStatus()
        
        if (status == PHAuthorizationStatus.authorized) {
            // Access has been granted.
        }
            
        else if (status == PHAuthorizationStatus.denied) {
            // Access has been denied.
        }
            
        else if (status == PHAuthorizationStatus.notDetermined) {
            
            // Access has not been determined.
            PHPhotoLibrary.requestAuthorization({ (newStatus) in
                
                if (newStatus == PHAuthorizationStatus.authorized) {
                    
                }
                    
                else {
                    
                }
            })
        }
            
        else if (status == PHAuthorizationStatus.restricted) {
            // Restricted access - normally won't happen.
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
    
    func playVideo(_ url:URL) {
        let asset = AVAsset(url:url)
        if asset.isPlayable {
            DispatchQueue.main.async {
                let playerItem = AVPlayerItem(url: url)
                self.player = AVPlayer(playerItem: playerItem)
                self.playerController?.player = self.player
                self.player?.play()
            }
        }
    }
    
    // MARK: UIImagePickerControllerDelegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: PHLivePhotoViewDelegate
    
    func livePhotoView(_ livePhotoView: PHLivePhotoView, willBeginPlaybackWith playbackStyle: PHLivePhotoViewPlaybackStyle) {
        self.livePhotoBadgeLayer.opacity = 0.0
    }
    
    func livePhotoView(_ livePhotoView: PHLivePhotoView, didEndPlaybackWith playbackStyle: PHLivePhotoViewPlaybackStyle) {
        self.livePhotoBadgeLayer.opacity = 1.0
    }
}
