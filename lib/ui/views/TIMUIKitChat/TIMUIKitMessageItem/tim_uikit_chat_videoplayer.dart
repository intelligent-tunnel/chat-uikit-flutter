import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:better_player_plus/better_player_plus.dart';
import 'package:tencent_cloud_chat_sdk/enum/message_elem_type.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_message.dart'
    if (dart.library.html) 'package:tencent_cloud_chat_sdk/web/compatible_models/v2_tim_message.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_message_online_url.dart'
    if (dart.library.html) 'package:tencent_cloud_chat_sdk/web/compatible_models/v2_tim_message_online_url.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_value_callback.dart'
    if (dart.library.html) 'package:tencent_cloud_chat_sdk/web/compatible_models/v2_tim_value_callback.dart';
import 'package:tencent_cloud_chat_sdk/tencent_im_sdk_plugin.dart';
import 'package:tencent_cloud_chat_uikit/tencent_cloud_chat_uikit.dart';

import 'tim_uikit_chat_video_controls.dart';

class TIMUIKitVideoPlayer extends StatefulWidget {
  final V2TimMessage message;
  final bool controller;
  final bool isSending;

  /// 聊天视频预览页控制条样式（用于自定义进度条与交互体验）。
  final TIMUIKitChatVideoControlsStyle controlsStyle;

  const TIMUIKitVideoPlayer({
    super.key,
    required this.message,
    required this.controller,
    required this.isSending,
    this.controlsStyle = const TIMUIKitChatVideoControlsStyle(),
  });

  @override
  State<StatefulWidget> createState() => TIMUIKitVideoPlayerState();
}

enum CurrentVideoType {
  online,
  local,
}

class CurrentVideoInfo {
  final String path;
  final CurrentVideoType type;
  final double aspectRatio;

  CurrentVideoInfo({
    required this.path,
    required this.type,
    required this.aspectRatio,
  });
}

class TIMUIKitVideoPlayerState extends State<TIMUIKitVideoPlayer> {
  /// 日志 tag（用于快速定位聊天视频播放页相关日志）。
  final String _tag = "TencentCloudChatMessageVideoPlayer";

  /// 预留给关闭/下载按钮的底部空间，避免与视频控制条重叠。
  static const double _kControlBottomPadding = 60;

  /// 默认视频展示宽高比（用于兜底）。
  ///
  /// - 用途：当视频封面宽高为空/异常时，避免 AspectRatio 计算失败导致布局跳动。
  /// - 返回：默认宽高比（9:16）。
  /// - 约束：仅用于 UI 展示兜底，不代表真实视频比例。
  static const double _kDefaultAspectRatio = 9 / 16;

  /// 视频控制层的遮罩背景色。
  ///
  /// - 用途：Android(Material) 默认会使用 `controlBarColor` 作为「点击区域」的全屏背景，
  ///   若为黑色会导致显示控制条时整屏发黑。
  /// - 约束：这里设置为透明，由自定义控制条自行绘制需要的局部背景（如圆角容器底）。
  static const Color _kVideoControlsMaskColor = Colors.transparent;

  BetterPlayerController? _betterPlayerController;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  /// 初始化视频播放器控制器。
  ///
  /// - 用途：根据消息来源（本地/网络）构建 `BetterPlayerController` 并自动播放。
  /// - 返回：Future<void>，初始化完成后会触发 `setState` 刷新界面。
  /// - 业务约束：仅在 `mounted == true` 时更新状态，避免页面销毁后回调导致异常。
  Future<void> _initializePlayer() async {
    try {
      final info = await getMessageInfo();
      if (info != null && mounted) {
        BetterPlayerDataSource dataSource;
        if (info.type == CurrentVideoType.online) {
          dataSource = BetterPlayerDataSource(
            BetterPlayerDataSourceType.network,
            info.path,
          );
        } else {
          dataSource = BetterPlayerDataSource(
            BetterPlayerDataSourceType.file,
            info.path,
          );
        }

        final betterPlayerConfiguration = BetterPlayerConfiguration(
          aspectRatio: info.aspectRatio,
          fit: BoxFit.contain,
          autoPlay: true,
          allowedScreenSleep: false,
          fullScreenByDefault: false,
          controlsConfiguration: BetterPlayerControlsConfiguration(
            controlBarColor: _kVideoControlsMaskColor,
            playerTheme: BetterPlayerTheme.custom,
            enableFullscreen: false,
            enablePlayPause: true,
            enableProgressBar: true,
            enableProgressText: true,
            showControlsOnInitialize: false,
            enableMute: false,
            enableOverflowMenu: false,
            enableSkips: false,
            customControlsBuilder: (
              BetterPlayerController controller,
              Function(bool) onPlayerVisibilityChanged,
            ) {
              return TIMUIKitChatVideoControls(
                betterPlayerController: controller,
                onPlayerVisibilityChanged: onPlayerVisibilityChanged,
                style: widget.controlsStyle,
              );
            },
          ),
        );

        _betterPlayerController = BetterPlayerController(
          betterPlayerConfiguration,
          betterPlayerDataSource: dataSource,
        );
        _attachPositionListener();

        if (mounted) {
          setState(() {});
        }
      }
    } catch (e) {
      debugPrint("Video initialization error: $e");
    }
  }

  @override
  void dispose() {
    _detachPositionListener();
    _betterPlayerController?.dispose();
    super.dispose();
  }

  /// 从消息中解析可播放的视频资源信息。
  ///
  /// - 用途：为 `BetterPlayerController` 提供正确的数据源（本地文件 / 在线 URL）。
  /// - 返回：可播放时返回 `CurrentVideoInfo`，否则返回 null。
  /// - 业务约束：iOS 历史自发视频可能携带无效 `videoPath`，文件不存在时需回退到在线地址。
  Future<CurrentVideoInfo?> getMessageInfo() async {
    if (widget.message.elemType != MessageElemType.V2TIM_ELEM_TYPE_VIDEO) {
      console(
          "The component received a non-video message parameter. please check");
      return null;
    }

    final double aspectRatio = _calculateVideoAspectRatio();

    final String? localPath = _resolvePlayableLocalVideoPath(
      isSending: widget.isSending,
    );
    if (localPath != null) {
      return CurrentVideoInfo(
        path: localPath,
        type: CurrentVideoType.local,
        aspectRatio: aspectRatio,
      );
    }

    final String? messageOnlineUrl = _resolveMessageOnlineVideoUrl();
    if (messageOnlineUrl != null) {
      return CurrentVideoInfo(
        path: messageOnlineUrl,
        type: CurrentVideoType.online,
        aspectRatio: aspectRatio,
      );
    }

    final String? fetchedOnlineUrl = await _fetchOnlineVideoUrlByMsgId(
      widget.message.msgID,
    );
    if (fetchedOnlineUrl != null) {
      return CurrentVideoInfo(
        path: fetchedOnlineUrl,
        type: CurrentVideoType.online,
        aspectRatio: aspectRatio,
      );
    }

    final elem = widget.message.videoElem;
    console(
      "has no view video source. msgID=${widget.message.msgID}, "
      "videoPath=${elem?.videoPath}, localVideoUrl=${elem?.localVideoUrl}, "
      "videoUrl=${elem?.videoUrl}",
    );
    return null;
  }

  /// 控制台日志输出（仅用于调试）。
  ///
  /// - 用途：统一输出带 tag 的日志，便于定位视频播放页相关问题。
  /// - 入参：[log] 需要输出的日志内容。
  /// - 返回：无。
  /// - 约束：使用 `debugPrint`，避免生产环境触发 `avoid_print`。
  void console(String log) {
    debugPrint("$_tag, $log");
  }

  /// 计算当前视频展示宽高比，优先使用封面宽高，避免播放页布局跳动。
  double _calculateVideoAspectRatio() {
    final elem = widget.message.videoElem;
    final int? snapshotWidth = elem?.snapshotWidth;
    final int? snapshotHeight = elem?.snapshotHeight;
    if (snapshotWidth == null || snapshotHeight == null) {
      return _kDefaultAspectRatio;
    }
    if (snapshotHeight == 0) {
      return _kDefaultAspectRatio;
    }
    return snapshotWidth / snapshotHeight;
  }

  /// 解析并返回「当前确实存在」的本地视频文件路径。
  /// 优先级：发送中本地路径 > videoPath（SDK/发送遗留）> localVideoUrl（下载缓存）。
  /// [isSending] 表示是否处于发送中状态，发送中优先用原始视频路径播放。
  String? _resolvePlayableLocalVideoPath({required bool isSending}) {
    if (kIsWeb) {
      return null;
    }

    final elem = widget.message.videoElem;
    if (elem == null) {
      return null;
    }

    if (isSending) {
      final String? sendingPath = TencentUtils.checkString(elem.videoPath);
      if (sendingPath != null && File(sendingPath).existsSync()) {
        console("view sending message video path");
        return sendingPath;
      }
    }

    final String? videoPath = TencentUtils.checkString(elem.videoPath);
    if (videoPath != null && File(videoPath).existsSync()) {
      console("video: local video path exists");
      return videoPath;
    }

    final String? localVideoUrl = TencentUtils.checkString(elem.localVideoUrl);
    if (localVideoUrl != null && File(localVideoUrl).existsSync()) {
      console("video: local url exists");
      return localVideoUrl;
    }

    return null;
  }

  /// 从消息体中直接解析在线播放地址（无需额外请求）。
  /// 注意：仅当 videoUrl 非空时返回；否则交给在线拉取兜底处理。
  String? _resolveMessageOnlineVideoUrl() {
    final elem = widget.message.videoElem;
    final String? videoUrl = TencentUtils.checkString(elem?.videoUrl);
    if (videoUrl == null) {
      return null;
    }
    console("video: online url $videoUrl");
    return videoUrl;
  }

  /// 通过 SDK 根据 [msgID] 拉取视频在线地址，适配历史消息未携带 videoUrl 的情况。
  /// 返回可用的在线 URL；若 msgID 为空/拉取失败则返回 null。
  Future<String?> _fetchOnlineVideoUrlByMsgId(String? msgID) async {
    final String? safeMsgID = TencentUtils.checkString(msgID);
    if (kIsWeb || safeMsgID == null) {
      return null;
    }

    try {
      final V2TimValueCallback<V2TimMessageOnlineUrl> urlRes =
          await TencentImSDKPlugin.v2TIMManager
              .getMessageManager()
              .getMessageOnlineUrl(msgID: safeMsgID);
      final String? onlineUrl =
          TencentUtils.checkString(urlRes.data?.videoElem?.videoUrl);
      if (onlineUrl == null) {
        return null;
      }
      console("view video online url $onlineUrl");
      return onlineUrl;
    } catch (e) {
      console("getMessageOnlineUrl error: $e");
      return null;
    }
  }

  /// 为底层 video 控制器添加监听，保障进度不会溢出。
  void _attachPositionListener() {
    final controller = _betterPlayerController?.videoPlayerController;
    controller?.addListener(_clampPositionToDuration);
  }

  /// 移除进度监听，避免组件销毁后仍触发回调。
  void _detachPositionListener() {
    final controller = _betterPlayerController?.videoPlayerController;
    controller?.removeListener(_clampPositionToDuration);
  }

  /// 防止播放位置超过时长导致控制条剩余时间倒数为负值。
  void _clampPositionToDuration() {
    final controller = _betterPlayerController?.videoPlayerController;
    final Duration? duration = controller?.value.duration;
    final Duration? position = controller?.value.position;
    if (duration == null || duration.inMilliseconds <= 0) {
      return;
    }
    if (position != null && position > duration) {
      _betterPlayerController?.pause();
      _betterPlayerController?.seekTo(duration);
    }
  }

  /// 构建视频播放区域，额外腾出底部内边距让进度条远离自定义操作按钮。
  @override
  Widget build(BuildContext context) {
    if (widget.message.hasRiskContent == true) {
      return const Center(
        child: Text(
          "Risk Video",
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    if (_betterPlayerController == null) {
      return Container();
    }

    return AspectRatio(
      aspectRatio:
          _betterPlayerController!.videoPlayerController?.value.aspectRatio ??
              _kDefaultAspectRatio,
      child: Padding(
        padding: const EdgeInsets.only(bottom: _kControlBottomPadding),
        child: BetterPlayer(
          controller: _betterPlayerController!,
        ),
      ),
    );
  }
}
