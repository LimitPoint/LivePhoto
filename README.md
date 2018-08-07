![LivePhotoIcon](https://support.apple.com/library/content/dam/edam/applecare/images/en_US/ios/iphoto/ios11-camera-live-photo-icon.png)
# LivePhoto.swift
## A single-file helper library to work with Apple Live Photos

A Live Photo is a paired camera photo ("key photo") and video recording ("paired video").
Learn more about Live Photos from our [in-depth blog post](https://www.limit-point.com/blog/2018/live-photos).

### Live Photo format
A Live Photo consists of two resources paired using an asset identifier (a UUID string):
1. JPEG image with special metadata for `kCGImagePropertyMakerAppleDictionary` with `[17 : assetIdentifier]`
2. Quicktime MOV with
     1. Quicktime metadata for `["com.apple.quicktime.content.identifier" : assetIdentifier]`
     2. Timed metadata track with `["com.apple.quicktime.still-image-time" : 0xFF]`.  This lets the system know where the still image sits in the movie timeline.

### LivePhoto.swift
The entire library is contained in the `LivePhoto.swift` file:

#### Extracting Resources from PHLivePhoto
```swift
LivePhoto.extractResources(from: livePhoto, completion: resources -> Void) {
  let pairedImageURL = resources.pairedImageURL
  let pairedVideoURL = resources.pairedVideoURL
}
```
#### Generating a Live Photo & Saving it to the Photo Library
```swift
LivePhoto.generate(from: photoURL, videoURL: videoURL, progress: { percent in }, completion: { livePhoto, resources in
  // Display the Live Photo in a PHLivePhotoView
  livePhotoView.livePhoto = livePhoto
  // Or save the resources to the Photo library
  LivePhoto.saveToLibrary(resources)
  })
```
