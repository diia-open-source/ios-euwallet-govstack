
import UIKit

public final class LoadingView: BaseCodeView {
    
    // MARK: - Static
    public static weak var globalLoadingView: LoadingView?
    
    public static func showGlobal(in view: UIView) {
        if globalLoadingView != nil {
            hideGlobal()
        }
        globalLoadingView = show(in: view)
        
        UIAccessibility.post(notification: .layoutChanged, argument: globalLoadingView)
    }
    
    public static func hideGlobal() {
        globalLoadingView?.hide()
        globalLoadingView = nil
    }
    
    @discardableResult
    public static func show(in view: UIView) -> LoadingView {
        let loadingView = LoadingView()
        
        loadingView.isAccessibilityElement = true
        loadingView.accessibilityTraits = .staticText
        loadingView.accessibilityViewIsModal = true
        loadingView.accessibilityLabel = R.Strings.general_accessibility_loading_hint.localized()
        
        view.isUserInteractionEnabled = false
        loadingView.visualEffectView.alpha = 0
        view.addSubview(loadingView)
        loadingView.fillSuperview()
        
        loadingView.loadingContainerView.startAnimation()
        UIView.animate(withDuration: Constants.showingAnimationDuration,
                       animations: {
            loadingView.visualEffectView.alpha = 1
        })
        
        return loadingView
    }
    
    // MARK: - Private
    private lazy var visualEffectView: UIView = {
        let visualEffectView = UIView()
        visualEffectView.backgroundColor = Constants.backgroundColor
        return visualEffectView
    }()
    
    private lazy var loadingContainerView: LoadingContainerView = {
        let loadingView = LoadingContainerView()
        loadingView.configure(size: Constants.loadingViewSize, loadingImage: R.image.loading.image)
        return loadingView
    }()
    
    public override func setupSubviews() {
        addSubview(visualEffectView)
        visualEffectView.fillSuperview()
        
        addSubview(loadingContainerView)
        loadingContainerView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        loadingContainerView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
    }
    
    public func hide() {
        superview?.isAccessibilityElement = false
        superview?.accessibilityViewIsModal = false
        
        superview?.isUserInteractionEnabled = true
        layer.removeAllAnimations()
        UIView.animate(withDuration: Constants.hidingAnimationDuration,
                       animations: {
            self.visualEffectView.alpha = 0
        }, completion: { [weak self] _ in
            self?.loadingContainerView.stopAnimation()
            self?.removeFromSuperview()
        })
    }
}

private extension LoadingView {
    enum Constants {
        static let backgroundColor = UIColor.black.withAlphaComponent(0.6)
        static let loadingViewSize = CGSize(width: 24, height: 24)
        static let hidingAnimationDuration: TimeInterval = 0.3
        static let showingAnimationDuration: TimeInterval = 0.1
    }
}
