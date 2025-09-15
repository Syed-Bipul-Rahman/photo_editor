import Flutter
import UIKit

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
        // Check if the emoji can be rendered on iOS
        let font = UIFont.systemFont(ofSize: 12)
        let attributes = [NSAttributedString.Key.font: font]
        let size = emoji.size(withAttributes: attributes)
        return size.width > 0 && size.height > 0
    }
}