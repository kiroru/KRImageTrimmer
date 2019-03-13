//
//  UIImagePickerController+Permission.swift
//  KRImageTrimmer
//
//  Created by ktakeguchi on 2019/02/12.
//  Copyright © 2019 Kiroru Inc. All rights reserved.
//

import Foundation
import AVFoundation
import Photos

extension UIImagePickerController {
    typealias CompletionHandler = (Accessibility) -> Void

    enum Accessibility {
        // The specified source can not be used
        case notAvailable
        // The first authorization request was issued
        case requested(_ granted: Bool)
        // Access denied
        case denied
        // Access is permitted
        case granted
    }

    /// Request access to the specified source type
    static func requestAccess(_ sourceType: UIImagePickerController.SourceType, completionHandler: @escaping CompletionHandler) {
        switch sourceType {
        case .camera:
            requestCameraAccess(completionHandler)
        case .photoLibrary:
            requestPhotoLibraryAccess(completionHandler)
        default:
            // Do not implement
            break
        }
    }

    /// Request access to the camera
    private static func requestCameraAccess(_ completionHandler: @escaping CompletionHandler) {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            completionHandler(.notAvailable)
            return
        }

        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                completionHandler(.requested(granted))
            }
        case .authorized:
            completionHandler(.granted)
        default:
            completionHandler(.denied)
        }
    }

    /// Request access to the photo library
    private static func requestPhotoLibraryAccess(_ completionHandler: @escaping CompletionHandler) {
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else {
            completionHandler(.notAvailable)
            return
        }

        let status = PHPhotoLibrary.authorizationStatus()
        switch status {
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { status in
                let granted = status == .authorized
                completionHandler(.requested(granted))
            }
        case .authorized:
            completionHandler(.granted)
        default:
            completionHandler(.denied)
        }
    }
}
