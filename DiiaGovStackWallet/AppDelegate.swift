import UIKit
import UserNotifications
import DiiaCommonServices
import WalletSplashScreen
import DiiaUIComponents

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    var window: UIWindow?
    private var router: AppRouter!
    private var stubImage: UIImageView!
    private let deeplinkManager = DeepLinkManager()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        ReachabilityHelper.shared.startNetworkReachabilityObserver()
        
        let window = UIWindow(frame: UIScreen.main.bounds)
        self.window = window
        
        router = AppRouter.instance
        router.configure(window: window)
        deeplinkManager.appRouter = router
        window.makeKeyAndVisible()
        
        // Configure app-wide services before presenting the first screen.
        AppConfigurator.configureApp()

        // Register synchronously during launch — BGTaskScheduler traps on late registration.
        DeferredIssuanceBackgroundRefresh.register()

        UIApplication.shared.registerForRemoteNotifications()
        // Receive local notifications (e.g. document-revocation banners) so they
        // can be presented while the app is in the foreground — the revocation
        // poller only runs while foregrounded, so without this the banner would
        // be silently suppressed by the system.
        UNUserNotificationCenter.current().delegate = self
        
        window.rootViewController = SplashScreenModule(
            backgroundImage: R.image.light_background.image,
            logosImage: R.image.logos.image,
            onFinish: { [weak self] in
                self?.router.start()
            }
        ).viewController()
        
        return true
    }
    
    // MARK: - DeepLinks
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        guard
            userActivity.activityType == NSUserActivityTypeBrowsingWeb,
            let url = userActivity.webpageURL
        else {
            return false
        }
        
        return deeplinkManager.parse(url: url)
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        
        return deeplinkManager.parse(url: url)
    }
    
    // MARK: - LifeCycle
    func applicationWillResignActive(_ application: UIApplication) {
        if let window = window, stubImage == nil {
            stubImage = UIImageView(frame: window.frame)
            stubImage.image = R.image.light_background.image
        }
        stubImage.alpha = 0
        self.window?.addSubview(stubImage)
        self.window?.endEditing(true)
        UIView.animate(withDuration: 0.2, animations: { self.stubImage.alpha = 1 })
        ScreenBrightnessHelper.shared.resetBrightness()
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        if stubImage != nil {
            stubImage.removeFromSuperview()
        }
        for window in application.windows {
            window.rootViewController?.beginAppearanceTransition(true, animated: false)
            window.rootViewController?.endAppearanceTransition()
        }
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        ServicesProvider.shared.authService.noteEnteredBackground()
        for window in application.windows {
            window.rootViewController?.beginAppearanceTransition(false, animated: false)
            window.rootViewController?.endAppearanceTransition()
        }
        DeferredIssuanceBackgroundRefresh.scheduleIfNeeded()
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        if ServicesProvider.shared.authService.doesNeedPincode() {
            router.showPincode()
        }
    }
    
    // MARK: - Local Notifications
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Suppress the foreground banner for deferred-issuance outcomes (already shown by the in-app alert); everything else (e.g. revocation banners) still shows.
        if notification.request.identifier.hasPrefix("deferred-issuance") {
            completionHandler([])
        } else {
            completionHandler([.banner, .list, .sound])
        }
    }

    // MARK: - Disable Third Party Keyboards
    func application(_ application: UIApplication, shouldAllowExtensionPointIdentifier extensionPointIdentifier: UIApplication.ExtensionPointIdentifier) -> Bool {
        if extensionPointIdentifier == UIApplication.ExtensionPointIdentifier.keyboard {
            return false
        }
        
        return true
    }
}
