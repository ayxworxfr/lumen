import Flutter
import ImageIO
import UIKit
import UniformTypeIdentifiers

/// AVIF 编码插件
///
/// 通过 MethodChannel "lumen/avif" 接收来自 Dart 侧的编码请求。
/// iOS 16+ ImageIO 原生支持 AVIF 输出（UTI: org.aomediacodec.avif-image）。
/// 编码在后台队列执行，避免阻塞主线程。
@available(iOS 16.0, *)
final class AvifEncoderPlugin: NSObject, FlutterPlugin {

    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "lumen/avif",
            binaryMessenger: registrar.messenger()
        )
        let instance = AvifEncoderPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard call.method == "encode" else {
            result(FlutterMethodNotImplemented)
            return
        }

        guard let args = call.arguments as? [String: Any],
              let sourcePath = args["sourcePath"] as? String,
              let outputPath = args["outputPath"] as? String,
              let quality = args["quality"] as? Int,
              let isLossless = args["lossless"] as? Bool
        else {
            result(FlutterError(
                code: "INVALID_ARGS",
                message: "Missing required arguments",
                details: nil
            ))
            return
        }

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let outputBytes = try self.encodeToAvif(
                    sourcePath: sourcePath,
                    outputPath: outputPath,
                    quality: quality,
                    isLossless: isLossless
                )
                DispatchQueue.main.async {
                    result(["outputPath": outputPath, "outputBytes": outputBytes])
                }
            } catch {
                DispatchQueue.main.async {
                    result(FlutterError(
                        code: "ENCODE_FAILED",
                        message: error.localizedDescription,
                        details: nil
                    ))
                }
            }
        }
    }

    /// 将源图片编码为 AVIF 并写到 outputPath，返回输出字节数
    private func encodeToAvif(
        sourcePath: String,
        outputPath: String,
        quality: Int,
        isLossless: Bool
    ) throws -> Int {
        let sourceURL = URL(fileURLWithPath: sourcePath)
        let outputURL = URL(fileURLWithPath: outputPath)

        // 解码源图片（支持 JPEG / PNG / HEIC / WebP 等系统 codec 支持的格式）
        guard let source = CGImageSourceCreateWithURL(sourceURL as CFURL, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil)
        else {
            throw EncoderError.sourceReadFailed
        }

        // 读取 EXIF 元数据（用于透传到 AVIF）
        let sourceMetadata = CGImageSourceCopyPropertiesAtIndex(source, 0, nil)

        // 创建 AVIF 输出目标
        guard let destination = CGImageDestinationCreateWithURL(
            outputURL as CFURL,
            UTType.avif.identifier as CFString,
            1,
            nil
        ) else {
            throw EncoderError.destinationCreateFailed
        }

        // 压缩选项
        var options: [CFString: Any] = [:]
        if isLossless {
            // ImageIO 的 kCGImageDestinationLossyCompressionQuality = 1.0 近似 lossless
            options[kCGImageDestinationLossyCompressionQuality] = 1.0
        } else {
            // quality 0-100 → 0.0-1.0
            options[kCGImageDestinationLossyCompressionQuality] = Double(quality) / 100.0
        }

        // 附带原始 EXIF（含 GPS、方向等）
        if let metadata = sourceMetadata {
            CGImageDestinationAddImageAndMetadata(
                destination,
                cgImage,
                CGImageMetadataCreateMutableCopy(
                    CGImageSourceCopyMetadataAtIndex(source, 0, nil)!
                ),
                options as CFDictionary
            )
        } else {
            CGImageDestinationAddImage(destination, cgImage, options as CFDictionary)
        }

        guard CGImageDestinationFinalize(destination) else {
            throw EncoderError.finalizeFailed
        }

        let attr = try FileManager.default.attributesOfItem(atPath: outputPath)
        return (attr[.size] as? Int) ?? 0
    }

    private enum EncoderError: LocalizedError {
        case sourceReadFailed
        case destinationCreateFailed
        case finalizeFailed

        var errorDescription: String? {
            switch self {
            case .sourceReadFailed: return "Failed to read source image"
            case .destinationCreateFailed: return "Failed to create AVIF destination"
            case .finalizeFailed: return "Failed to finalize AVIF encoding"
            }
        }
    }
}
