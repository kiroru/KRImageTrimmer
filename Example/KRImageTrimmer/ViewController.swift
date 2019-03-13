//
//  ViewController.swift
//  KRImageTrimmer
//
//  Created by ktakeguchi on 2019/02/07.
//  Copyright © 2019 Kiroru Inc. All rights reserved.
//

import UIKit
import KRImageTrimmer

class ViewController: UIViewController {
    @IBOutlet private var imageView: UIImageView!
    private var pickedImage: UIImage?

    @IBAction private func imagePickAction() {
        showSourceSelectionSheet()
    }

    /// Select source of image
    private func showSourceSelectionSheet() {
        let vc = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        vc.addAction(UIAlertAction(title: "Camera", style: .default, handler: { [unowned self] _ in
            self.requestAccess(sourceType: .camera)
        }))
        vc.addAction(UIAlertAction(title: "Photo library", style: .default, handler: { [unowned self] _ in
            self.requestAccess(sourceType: .photoLibrary)
        }))
        vc.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(vc, animated: true, completion: nil)
    }

    /// Request permission to use UIImagePickerController
    /// (This is an implementation of the sample, it is not an essential process to use KRImageTrimmerController)
    private func requestAccess(sourceType: UIImagePickerController.SourceType) {
        let message: String
        switch sourceType {
        case .camera:
            message = "Access to the camera is denied. Please change the setting."
        case .photoLibrary:
            message = "Access to the photo library is denied. Please change the setting."
        default:
            // I do not think this time
            message = ""
        }

        UIImagePickerController.requestAccess(sourceType) { accessibility in
            DispatchQueue.main.async { [unowned self] in
                switch accessibility {
                case .granted:
                    self.showImagePicker(sourceType)
                case .requested(granted: true):
                    self.showImagePicker(sourceType)
                case .denied:
                    self.showSettingAlert(message)
                case .notAvailable:
                    self.showAlert("It is not available on this device.")
                default:
                    break
                }
            }
        }
    }

    /// Open UIImagePickerController and get the image to edit
    private func showImagePicker(_ sourceType: UIImagePickerController.SourceType) {
        let vc = UIImagePickerController()
        vc.sourceType = sourceType
        vc.delegate = self
        present(vc, animated: true, completion: nil)
    }

    /// Display KRImageTrimmerController
    private func showImageTrimmer() {
        // Customize settings
        // If not specified, the default value is applied
        let options = KRImageTrimmerController.Options()
        options.zoomingMultiplier = 2.0
        options.cancelButtonTitle = "Cancel"
        options.cancelButtonTitleColor = UIColor.red
        options.confirmButtonTitle = "OK"
        options.confirmButtonTitleColor = UIColor.blue
        options.frameWidth = 4.0
        options.frameColor = UIColor.white
        options.frameDashPattern = [8.0, 4.0, 4.0, 4.0]

        let vc = KRImageTrimmerController(options: options)
        vc.delegate = self
        navigationController?.pushViewController(vc, animated: true)
    }

    private func showAlert(_ message: String) {
        let vc = UIAlertController(title: "", message: message, preferredStyle: .alert)
        vc.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(vc, animated: true, completion: nil)
    }

    private func showSettingAlert(_ message: String) {
        let vc = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        vc.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        vc.addAction(UIAlertAction(title: "Setting", style: .default, handler: { _ in
            guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                UIApplication.shared.openURL(url)
            }
        }))
        present(vc, animated: true, completion: nil)
    }
}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    /// Receive selected image from UIImagePickerController
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else { return }
        pickedImage = image
        picker.dismiss(animated: true) { [unowned self] in
            self.showImageTrimmer()
        }
    }
}

extension ViewController: KRImageTrimmerControllerDelegate {
    /// Pass the image to be edited
    func imageForTrimming() -> UIImage {
        return pickedImage!
    }

    /// Called when image editing is canceled
    func imageTrimmerControllerDidCancel(_ imageTrimmer: KRImageTrimmerController) {
        navigationController?.popViewController(animated: true)
        showAlert("Trimming canceled")
    }

    /// When image editing is completed, the image after editing will be returned
    func imageTrimmerController(_ imageTrimmer: KRImageTrimmerController, didFinishTrimmingImage image: UIImage?) {
        navigationController?.popViewController(animated: true)
        guard let image = image else {
            showAlert("Trimming failed")
            return
        }
        imageView.image = image
    }
}
