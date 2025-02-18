//
//  File.swift
//  KSPlayer
//
//  Created by kintan on 2022/1/29.
//
import AVFoundation
import SwiftUI

@available(iOS 15, tvOS 15, macOS 12, *)
public struct KSVideoPlayerView: View {
    @State private var currentTime = TimeInterval(0)
    @State private var totalTime = TimeInterval(1)
    @State private var isMaskShow: Bool = true
    private let url: URL
    public let options: KSOptions
    public init(url: URL, options: KSOptions) {
        self.url = url
        self.options = options
    }

    public var body: some View {
        let player = KSVideoPlayer()
        player.playerLayer.set(url: url, options: options)
        return ZStack {
            player.onPlay { current, total in
                currentTime = current
                totalTime = total
            }
            .onDisappear {
                player.playerLayer.pause()
            }
            VideoControllerView(config: VideoControllerView.Config(isPlay: options.isAutoPlay, playerLayer: player.playerLayer), currentTime: $currentTime, totalTime: $totalTime).opacity(isMaskShow ? 1 : 0)
        }
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        #if !os(tvOS)
        .onTapGesture {
            isMaskShow.toggle()
        }
        #endif
    }
}

@available(iOS 15, tvOS 15, macOS 12, *)
struct VideoControllerView: View {
    public struct Config {
        private let playerLayer: KSPlayerLayer
        init(isPlay: Bool, playerLayer: KSPlayerLayer) {
            self.isPlay = isPlay
            self.playerLayer = playerLayer
        }

        var isPlay: Bool {
            didSet {
                isPlay ? playerLayer.play() : playerLayer.pause()
            }
        }

        var isMuted: Bool = false {
            didSet {
                playerLayer.player?.isMuted = isMuted
            }
        }

        var isPipActive = false {
            didSet {
                if let pipController = playerLayer.player?.pipController, isPipActive != pipController.isPictureInPictureActive {
                    if pipController.isPictureInPictureActive {
                        pipController.stopPictureInPicture()
                    } else {
                        pipController.startPictureInPicture()
                    }
                }
            }
        }

        var isScaleAspectFill = false {
            didSet {
                playerLayer.player?.contentMode = isScaleAspectFill ? .scaleAspectFill : .scaleAspectFit
            }
        }
    }

    @State private var config: Config
    @Binding private var currentTime: TimeInterval
    @Binding private var totalTime: TimeInterval
    private let backgroundColor = Color(red: 0.145, green: 0.145, blue: 0.145).opacity(0.6)
    init(config: Config, currentTime: Binding<TimeInterval>, totalTime: Binding<TimeInterval>) {
        self.config = config
        _currentTime = currentTime
        _totalTime = totalTime
    }

    public var body: some View {
        VStack {
            HStack {
                HStack(spacing: 8) {
                    Button {} label: {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                    }
                    Toggle(isOn: $config.isPipActive) {
                        Image(systemName: config.isPipActive ? "pip.exit" : "pip.enter")
                    }.toggleStyle(.button)
                    Toggle(isOn: $config.isScaleAspectFill) {
                        Image(systemName: config.isScaleAspectFill ? "rectangle.arrowtriangle.2.inward" : "rectangle.arrowtriangle.2.outward")
                    }.toggleStyle(.button)
                }.padding(.horizontal)
                    .background(backgroundColor, ignoresSafeAreaEdges: []).cornerRadius(8)
                Spacer()
                Toggle(isOn: $config.isMuted) {
                    Image(systemName: config.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                }
                .toggleStyle(.button)
                .frame(width: 48)
                .background(backgroundColor, ignoresSafeAreaEdges: []).cornerRadius(8)
            }
            Spacer()
            HStack(spacing: 8) {
                Toggle(isOn: $config.isPlay) {
                    Image(systemName: config.isPlay ? "pause.fill" : "play.fill")
                }
                .toggleStyle(.button).frame(width: 32, height: 32)
                Text(currentTime.toString(for: .minOrHour)).font(Font.custom("SFProText-Regular", size: 11)).foregroundColor(.secondary.opacity(0.6))
                ProgressView(value: currentTime, total: totalTime).tint(.secondary.opacity(0.32))
                Text("-" + (totalTime - currentTime).toString(for: .minOrHour)).font(Font.custom("SFProText-Regular", size: 11)).foregroundColor(.secondary.opacity(0.6))
                Button {} label: {
                    Image(systemName: "ellipsis")
                }
            }
            .background(backgroundColor)
            .cornerRadius(8)
        }.padding(.horizontal).tint(.clear).foregroundColor(.primary)
    }
}

@available(iOS 13, tvOS 13, macOS 10.15, *)
public struct KSVideoPlayer {
    struct Handler {
        var onPlay: ((TimeInterval, TimeInterval) -> Void)?
        var onFinish: ((Error?) -> Void)?
        var onStateChanged: ((KSPlayerState) -> Void)?
        var onBufferChanged: ((Int, TimeInterval) -> Void)?
    }

    public let playerLayer: KSPlayerLayer = .init()
    fileprivate var handler: Handler = .init()
    public init() {}
}

@available(iOS 13, tvOS 13, macOS 10.15, *)
extension KSVideoPlayer {
    func onBufferChanged(_ handler: @escaping (Int, TimeInterval) -> Void) -> Self {
        var view = self
        view.handler.onBufferChanged = handler
        return view
    }

    /// Playing to the end.
    func onFinish(_ handler: @escaping (Error?) -> Void) -> Self {
        var view = self
        view.handler.onFinish = handler
        return view
    }

    func onPlay(_ handler: @escaping (TimeInterval, TimeInterval) -> Void) -> Self {
        var view = self
        view.handler.onPlay = handler
        return view
    }

    /// Playback status changes, such as from play to pause.
    func onStateChanged(_ handler: @escaping (KSPlayerState) -> Void) -> Self {
        var view = self
        view.handler.onStateChanged = handler
        return view
    }
}

#if !canImport(UIKit)
@available(macOS 10.15, *)
typealias UIViewRepresentable = NSViewRepresentable
#endif
@available(iOS 13, tvOS 13, macOS 10.15, *)
extension KSVideoPlayer: UIViewRepresentable {
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    #if canImport(UIKit)
    public typealias UIViewType = KSPlayerLayer
    public func makeUIView(context: Context) -> UIViewType {
        makeView(context: context)
    }

    public func updateUIView(_ uiView: UIViewType, context: Context) {
        updateView(uiView, context: context)
    }

    #else
    public typealias NSViewType = KSPlayerLayer
    public func makeNSView(context: Context) -> NSViewType {
        makeView(context: context)
    }

    public func updateNSView(_ uiView: NSViewType, context: Context) {
        updateView(uiView, context: context)
    }
    #endif
    private func makeView(context: Context) -> KSPlayerLayer {
        playerLayer.delegate = context.coordinator
        return playerLayer
    }

    private func updateView(_: KSPlayerLayer, context _: Context) {}

    public final class Coordinator: KSPlayerLayerDelegate {
        private let videoPlayer: KSVideoPlayer

        init(_ videoPlayer: KSVideoPlayer) {
            self.videoPlayer = videoPlayer
        }

        public func player(layer _: KSPlayerLayer, state: KSPlayerState) {
            videoPlayer.handler.onStateChanged?(state)
        }

        public func player(layer _: KSPlayerLayer, currentTime: TimeInterval, totalTime: TimeInterval) {
            videoPlayer.handler.onPlay?(currentTime, totalTime)
        }

        public func player(layer _: KSPlayerLayer, finish error: Error?) {
            videoPlayer.handler.onFinish?(error)
        }

        public func player(layer _: KSPlayerLayer, bufferedCount: Int, consumeTime: TimeInterval) {
            videoPlayer.handler.onBufferChanged?(bufferedCount, consumeTime)
        }
    }
}
