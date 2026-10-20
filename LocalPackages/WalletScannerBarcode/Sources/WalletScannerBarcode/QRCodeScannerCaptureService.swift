import UIKit
import AVFoundation
import WalletDomainModels

protocol QRCodeScannerCaptureServiceProtocol: AnyObject {
    var onCodeDetected: ((String) -> Void)? { get set }
    var onFailure: (() -> Void)? { get set }

    func attach(to previewView: QRCodeScannerPreviewView)
    func start()
    func stop()
}

final class QRCodeScannerCaptureService: NSObject, QRCodeScannerCaptureServiceProtocol {
    var onCodeDetected: ((String) -> Void)?
    var onFailure: (() -> Void)?

    private let captureSession = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "QRCodeScannerCaptureService.session")
    private let metadataQueue = DispatchQueue(label: "QRCodeScannerCaptureService.metadata")
    private var isConfigured = false

    func attach(to previewView: QRCodeScannerPreviewView) {
        // `videoPreviewLayer` is the view's backing layer, so it must be touched on the main thread.
        // Only the heavy session configuration in `start()` / `stop()` runs on `sessionQueue`.
        previewView.videoPreviewLayer.session = captureSession
    }

    func start() {
        sessionQueue.async { [weak self] in
            guard let self else { return }

            self.configureSessionIfNeeded()
            guard self.isConfigured, !self.captureSession.isRunning else { return }
            self.captureSession.startRunning()
        }
    }

    func stop() {
        sessionQueue.async { [weak self] in
            guard let self, self.captureSession.isRunning else { return }
            self.captureSession.stopRunning()
        }
    }

    private func configureSessionIfNeeded() {
        guard !isConfigured else { return }

        guard let device = AVCaptureDevice.default(for: .video) else {
            notifyFailure()
            return
        }

        guard let input = try? AVCaptureDeviceInput(device: device) else {
            notifyFailure()
            return
        }
        guard captureSession.canAddInput(input) else {
            notifyFailure()
            return
        }

        let metadataOutput = AVCaptureMetadataOutput()
        guard captureSession.canAddOutput(metadataOutput) else {
            notifyFailure()
            return
        }

        captureSession.addInput(input)
        captureSession.addOutput(metadataOutput)
        metadataOutput.setMetadataObjectsDelegate(self, queue: metadataQueue)
        metadataOutput.metadataObjectTypes = [.qr]
        isConfigured = true
    }

    private func notifyFailure() {
        DispatchQueue.main.async { [weak self] in
            self?.onFailure?()
        }
    }
}

extension QRCodeScannerCaptureService: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        guard let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              metadataObject.type == .qr,
              let code = metadataObject.stringValue
        else { return }

        DispatchQueue.main.async { [weak self] in
            self?.onCodeDetected?(code)
        }
    }
}
