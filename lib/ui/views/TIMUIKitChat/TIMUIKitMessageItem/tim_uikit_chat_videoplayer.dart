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

class TIMUIKitVideoPlayer extends StatefulWidget {
  final V2TimMessage message;
  final bool controller;
  final bool isSending;

  const TIMUIKitVideoPlayer({
    super.key,
    required this.message,
    required this.controller,
    required this.isSending,
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
  final String _tag = "TencentCloudChatMessageVideoPlayer";

  /// 预留给关闭/下载按钮的底部空间，避免与视频控制条重叠。
  static const double _kControlBottomPadding = 60;

  /// 视频暂停/显示控制层时的全屏遮罩底色。
  ///
  /// - 用途：BetterPlayer 默认会用 `controlBarColor` 作为「中间点击区域」的全屏背景，
  ///   暂停时会出现一整块偏黑的半透明蒙版；这里将其改为透明以保持画面清爽。
  /// - 业务约束：仅影响 1v1 聊天的视频预览页（`VideoScreen`），不影响其它视频模块。
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
          controlsConfiguration: const BetterPlayerControlsConfiguration(
            controlBarColor: _kVideoControlsMaskColor,
            enableFullscreen: false,
            enablePlayPause: true,
            enableProgressBar: true,
            enableProgressText: true,
            showControlsOnInitialize: false,
            enableMute: false,
            enableOverflowMenu: false,
            enableSkips: false,
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

  Future<CurrentVideoInfo?> getMessageInfo() async {
    if (widget.message.elemType == MessageElemType.V2TIM_ELEM_TYPE_VIDEO) {
      double aspectRatio = (9 / 16);

      if (widget.isSending) {
        var lp = widget.message.videoElem!.videoPath ?? "";
        if (lp.isNotEmpty) {
          console("view sending message video path");
          if (File(lp).existsSync() && !kIsWeb) {
            return CurrentVideoInfo(
                path: lp,
                type: CurrentVideoType.local,
                aspectRatio: aspectRatio);
          }
        }
      }

      if (widget.message.videoElem!.snapshotWidth != null &&
          widget.message.videoElem!.snapshotHeight != null) {
        if (widget.message.videoElem!.snapshotHeight != 0) {
          aspectRatio = (widget.message.videoElem!.snapshotWidth!) /
              (widget.message.videoElem!.snapshotHeight!);
        }
      }

      if (TencentUtils.checkString(widget.message.videoElem!.videoPath) !=
          null) {
        // 先查本地发送的视频地址
        if (File(widget.message.videoElem!.videoPath!).existsSync()) {
          console("video: local video path exists");
          return CurrentVideoInfo(
              path: widget.message.videoElem!.videoPath!,
              type: CurrentVideoType.local,
              aspectRatio: aspectRatio);
        }
      } else if (TencentUtils.checkString(
              widget.message.videoElem!.localVideoUrl) !=
          null) {
        // 再查本地下载的视频地址
        if (File(widget.message.videoElem!.localVideoUrl!).existsSync()) {
          console("video: local url exists");
          return CurrentVideoInfo(
              path: widget.message.videoElem!.localVideoUrl!,
              type: CurrentVideoType.local,
              aspectRatio: aspectRatio);
        }
      } else {
        // 最后再查在线地址(todo 使用 getMessageOnlineUrl 查询)
        if (widget.message.videoElem != null) {
          if (widget.message.videoElem!.snapshotUrl != null) {
            console("video: online url ${widget.message.videoElem!.videoUrl}");
            return CurrentVideoInfo(
              path: widget.message.videoElem!.videoUrl!,
              type: CurrentVideoType.online,
              aspectRatio: aspectRatio,
            );
          }
        }
        if (!kIsWeb) {
          V2TimValueCallback<V2TimMessageOnlineUrl> urlres =
              await TencentImSDKPlugin.v2TIMManager
                  .getMessageManager()
                  .getMessageOnlineUrl(msgID: widget.message.msgID ?? "");
          if (urlres.data != null) {
            if (urlres.data?.videoElem != null) {
              if (TencentUtils.checkString(urlres.data?.videoElem?.videoUrl) !=
                  null) {
                console(
                    "view video online url ${urlres.data?.videoElem?.videoUrl}");
                return CurrentVideoInfo(
                    path: urlres.data!.videoElem!.videoUrl!,
                    type: CurrentVideoType.online,
                    aspectRatio: aspectRatio);
              }
            }
          }
        }
      }
    } else {
      console(
          "The component received a non-video message parameter. please check");
    }
    console("has no view video source. please check");
    return null;
  }

  console(String log) {
    print("$_tag, $log");
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
              9 / 16,
      child: Padding(
        padding: const EdgeInsets.only(bottom: _kControlBottomPadding),
        child: BetterPlayer(
          controller: _betterPlayerController!,
        ),
      ),
    );
  }
}
