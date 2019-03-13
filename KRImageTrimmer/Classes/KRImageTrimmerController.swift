//
//  KRImageTrimmerViewController.swift
//  KRImageTrimmer
//
//  Created by ktakeguchi on 2019/02/07.
//  Copyright © 2019 Kiroru Inc. All rights reserved.
//

import UIKit
import CoreGraphics

public protocol KRImageTrimmerControllerDelegate: class {
    /// Specify the image to trim
    /// - Returns: Image to trim
    func imageForTrimming() -> UIImage

    /// Notify that trimming has been canceled
    /// Since this view is not closed arbitrarily, please close the screen according to how to call
    /// - Parameter imageTrimmer: ViewController
    func imageTrimmerControllerDidCancel(_ imageTrimmer: KRImageTrimmerController)

    /// Notify that trimming is completed
    /// Since this view is not closed arbitrarily, please close the screen according to how to call
    /// - Parameters:
    ///   - imageTrimmer: ViewController
    ///   - image: Trimmed image (If it fails, nil will return)
    func imageTrimmerController(_ imageTrimmer: KRImageTrimmerController, didFinishTrimmingImage image: UIImage?)
}

public class KRImageTrimmerController: UIViewController {

    public class Options {
        /// Maximum zoom magnification
        public var zoomingMultiplier: CGFloat = 2.0

        /// Title of the cancel button
        public var cancelButtonTitle: String = "Cancel"

        /// Title color of the cancel button
        public var cancelButtonTitleColor: UIColor = UIColor.white

        /// Title of the confirm button
        public var confirmButtonTitle: String = "OK"

        /// Title color of the confirm button
        public var confirmButtonTitleColor: UIColor = UIColor.white

        /// Width of dashed line indicating trimming area
        public var frameWidth: CGFloat = 1.0

        /// Color of dashed line
        public var frameColor: UIColor = UIColor.white

        /// Pattern of dashed line
        /// [Line length, Blank length]
        /// If an empty array is specified, it is drawn as a straight line
        public var frameDashPattern: [CGFloat] = [4.0, 4.0]

        public init() {}
    }

    // MARK: - Public Properties

    /// Configurable options
    private var options: Options = Options()

    /// Delegate
    public weak var delegate: KRImageTrimmerControllerDelegate?

    // MARK: - View Properties

    @IBOutlet private var scrollView: UIScrollView!
    @IBOutlet private var trimFrameView: KRTrimFrameView!
    @IBOutlet private var trimImageView: UIImageView!
    @IBOutlet private var cancelButton: UIButton!
    @IBOutlet private var confirmButton: UIButton!

    // MARK: - Initializer

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    public convenience init(options: Options) {
        let name = String(describing: type(of: self))
        let pod = Bundle(for: KRImageTrimmerController.classForCoder())
        let path = pod.path(forResource: "KRImageTrimmer", ofType: "bundle")

        let bundle: Bundle?
        if let path = path {
            bundle = Bundle(path: path)
        } else {
            bundle = pod
        }

        self.init(nibName: name, bundle: bundle)
        self.options = options
    }

    // MARK: - Lifecycle

    override public func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        loadTrimImage()
    }

    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        adjustScrollPosition()
    }

    override public func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        // Hide resizing while rotating
        scrollView.isHidden = true

        coordinator.animate(alongsideTransition: nil) { [weak self] context in
            // Sizing after rotation
            self?.adjustScrollPosition()
            self?.scrollView.isHidden = false
        }
    }

    // MARK: - Actions

    @IBAction private func cancelAction() {
        delegate?.imageTrimmerControllerDidCancel(self)
    }

    @IBAction private func confirmAction() {
        delegate?.imageTrimmerController(self, didFinishTrimmingImage: trim())
    }

    // MARK: - Private methods

    /// Perform view setup
    private func setupViews() {
        cancelButton.setTitleColor(options.cancelButtonTitleColor, for: .normal)
        cancelButton.setTitle(options.cancelButtonTitle, for: .normal)
        confirmButton.setTitleColor(options.confirmButtonTitleColor, for: .normal)
        confirmButton.setTitle(options.confirmButtonTitle, for: .normal)
        trimFrameView.frameWidth = options.frameWidth
        trimFrameView.frameColor = options.frameColor
        trimFrameView.frameDashPattern = options.frameDashPattern
    }

    /// Load an image
    private func loadTrimImage() {
        guard let image = delegate?.imageForTrimming() else { return }

        trimImageView.image = image
        trimImageView.sizeToFit()
    }

    /// Adjust scroll display position
    private func adjustScrollPosition() {
        guard let image = trimImageView.image else { return }

        scrollView.contentSize = trimImageView.bounds.size
        scrollView.contentInset = scrollView.frame.insets(to: trimFrameView.trimAreaFrame)

        let minimumZoomScale = calcMinimumZoomScale(for: image, biggerThan: trimFrameView.trimAreaBounds.size)
        let maximumZoomScale = minimumZoomScale * options.zoomingMultiplier

        scrollView.minimumZoomScale = minimumZoomScale
        scrollView.maximumZoomScale = maximumZoomScale
        scrollView.zoomScale = minimumZoomScale

        scrollView.scrollToCenter()
    }

    /// Calculate the minimum zoom magnification
    /// - Parameters:
    ///   - image: Target image
    ///   - frameSize: Minimum size
    /// - Returns: Minimum zoom scale
    private func calcMinimumZoomScale(for image: UIImage, biggerThan frameSize: CGSize) -> CGFloat {
        let imageSize = image.size
        let xRatio = frameSize.width / imageSize.width
        let yRatio = frameSize.height / imageSize.height
        return max(xRatio, yRatio)
    }

    /// Acquire the image of the trimming result
    /// - Returns: Trimmed image
    private func trim() -> UIImage? {
        let rect = trimFrameView.convert(trimFrameView.trimAreaBounds, to: trimImageView)
        return trimImageView.image?.cropping(to: rect)
    }
}

extension KRImageTrimmerController: UIScrollViewDelegate {
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return trimImageView
    }
}

fileprivate extension CGRect {
    /// Get inset with target rect
    /// - Parameter targetRect: Target rect
    /// - Returns: Inset with target rect
    func insets(to targetRect: CGRect) -> UIEdgeInsets {
        return UIEdgeInsets(
            top: targetRect.minY - minY,
            left: targetRect.minX - minX,
            bottom: maxY - targetRect.maxY,
            right: maxX - targetRect.maxX
        )
    }
}

fileprivate extension UIScrollView {
    /// Scroll the content to the center
    func scrollToCenter() {
        let xScrollable = contentSize.width + contentInset.left + contentInset.right
        let yScrollable = contentSize.height + contentInset.top + contentInset.bottom

        let xHidden = xScrollable - bounds.size.width
        let yHidden = yScrollable - bounds.size.height

        let xOffset = contentInset.left - xHidden * 0.5
        let yOffset = contentInset.top - yHidden * 0.5

        contentOffset = CGPoint(x: -xOffset, y: -yOffset)
    }
}

fileprivate extension UIImage {
    /// Cut out the specified range
    /// Use this because CGImage#cropping(to:) does not consider Orientation
    func cropping(to: CGRect) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(to.size, false, scale)
        draw(at: CGPoint(x: -to.origin.x, y: -to.origin.y))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}

@IBDesignable class KRTrimFrameView: UIView {

    /// Margin provided outside the trimming area
    @IBInspectable var margin: CGFloat = 2.0

    /// Width of dashed line indicating trimming area
    @IBInspectable var frameWidth: CGFloat = 1.0

    /// Color of dashed line
    @IBInspectable var frameColor: UIColor = UIColor.red

    /// Pattern of dashed line
    var frameDashPattern: [CGFloat] = [5.0, 5.0]

    /// Local range of the trimming area
    var trimAreaBounds: CGRect {
        let ignoreWidth = margin + frameWidth
        return CGRect(
            x: ignoreWidth,
            y: ignoreWidth,
            width: bounds.width - ignoreWidth * 2.0,
            height: bounds.height - ignoreWidth * 2.0)
    }

    /// Range of trimming area from parent view
    var trimAreaFrame: CGRect {
        let ignoreWidth = margin + frameWidth
        return CGRect(
            x: frame.minX + ignoreWidth,
            y: frame.minY + ignoreWidth,
            width: bounds.width - ignoreWidth * 2.0,
            height: bounds.height - ignoreWidth * 2.0)
    }

    override func draw(_ rect: CGRect) {
        let widthToCenterOfLine = margin + frameWidth / 2.0
        let frameRect = CGRect(
            x: widthToCenterOfLine,
            y: widthToCenterOfLine,
            width: rect.width - widthToCenterOfLine * 2.0,
            height: rect.height - widthToCenterOfLine * 2.0)

        let rectPath = UIBezierPath(rect: frameRect)
        rectPath.lineWidth = frameWidth
        rectPath.setLineDash(frameDashPattern, count: frameDashPattern.count, phase: 0)
        frameColor.setStroke()
        rectPath.stroke()
    }
}
