import UIKit
import Flutter

// ✅ Define plugin BEFORE AppDelegate
public class ProImageEditorPlugin: NSObject, FlutterPlugin {

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "pro_image_editor", binaryMessenger: registrar.messenger())
        let instance = ProImageEditorPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getSupportedEmojis":
            guard let arguments = call.arguments as? [String: Any],
                  let source = arguments["source"] as? [String] else {
                result(FlutterError(code: "INVALID_ARGUMENT", message: "Invalid arguments", details: nil))
                return
            }

            let supportedList = source.map { emoji in
                return isEmojiSupported(emoji: emoji)
            }
            result(supportedList)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func isEmojiSupported(emoji: String) -> Bool {
        let font = UIFont.systemFont(ofSize: 12)
        let attributes = [NSAttributedString.Key.font: font]
        let size = emoji.size(withAttributes: attributes)
        return size.width > 0 && size.height > 0
    }
}

// ✅ Now AppDelegate can safely reference ProImageEditorPlugin
@main
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // ⚠️ Also: window?.rootViewController may not be set yet at this point!
        // Better to register plugins without depending on the view controller.
        // Just register the plugin — Flutter handles the rest.

        // ✅ This line is now valid because ProImageEditorPlugin is defined above
        ProImageEditorPlugin.register(with: registrar(forPlugin: "ProImageEditorPlugin")!)

        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}