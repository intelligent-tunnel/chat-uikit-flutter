import 'dart:io';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:open_file/open_file.dart';
import 'package:tencent_chat_i18n_tool/tencent_chat_i18n_tool.dart';
import 'package:tencent_cloud_chat_sdk/enum/message_status.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_message.dart'
    if (dart.library.html) 'package:tencent_cloud_chat_sdk/web/compatible_models/v2_tim_message.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_video_elem.dart'
    if (dart.library.html) 'package:tencent_cloud_chat_sdk/web/compatible_models/v2_tim_video_elem.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_base.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_state.dart';
import 'package:tencent_cloud_chat_uikit/tencent_cloud_chat_uikit.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_callback.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/separate_models/tui_chat_separate_view_model.dart';
import 'package:tencent_cloud_chat_uikit/data_services/message/message_services.dart';
import 'package:tencent_cloud_chat_uikit/data_services/services_locatar.dart';
import 'package:tencent_cloud_chat_uikit/theme/tui_theme.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/message.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/platform.dart';
import 'package:tencent_cloud_chat_uikit/ui/views/TIMUIKitChat/TIMUIKitMessageItem/'
    'TIMUIKitMessageReaction/tim_uikit_message_reaction_wrapper.dart';
import 'package:tencent_cloud_chat_uikit/ui/widgets/video_screen.dart';
import 'package:tencent_cloud_chat_uikit/ui/widgets/wide_popup.dart';
import 'package:url_launcher/url_launcher.dart';

class TIMUIKitVideoElem extends StatefulWidget {
  final V2TimMessage message;
  final bool isShowJump;
  final VoidCallback? clearJump;
  final String? isFrom;
  final TUIChatSeparateViewModel chatModel;
  final bool? isShowMessageReaction;

  const TIMUIKitVideoElem(this.message,
      {Key? key,
      this.isShowJump = false,
      this.clearJump,
      this.isFrom,
      this.isShowMessageReaction,
      required this.chatModel})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _TIMUIKitVideoElemState();
}

class _TIMUIKitVideoElemState extends TIMUIKitState<TIMUIKitVideoElem> {
  final MessageService _messageService = serviceLocator<MessageService>();
  /// 视频消息封面统一圆角半径，保持与图片气泡的视觉一致性。
  static const double _kMediaBubbleRadius = 12;
  late V2TimVideoElem stateElement = widget.message.videoElem!;

  Widget errorDisplay(TUITheme? theme) {
    return Container(
      decoration: BoxDecoration(
          border: Border.all(
        width: 1,
        color: Colors.black12,
      )),
      height: 100,
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.warning_amber_outlined,
              color: theme?.cautionColor,
              size: 16,
            ),
            Text(
              TIM_t("视频加载失败"),
              style: TextStyle(color: theme?.cautionColor),
            ),
          ],
        ),
      ),
    );
  }

  /// 根据视频元素选择合适的封面资源，并应用统一圆角。
  /// [theme] 用于提供加载占位的颜色配置；[height] 为原始封面高度，便于占位。
  Widget generateSnapshot(TUITheme theme, int height) {
    if (!PlatformUtils().isWeb) {
      final current = (DateTime.now().millisecondsSinceEpoch / 1000).ceil();
      final timeStamp = widget.message.timestamp ?? current;
      if (current - timeStamp < 300) {
        if (stateElement.snapshotPath != null && stateElement.snapshotPath != '') {
          File imgF = File(stateElement.snapshotPath!);
          bool isExist = imgF.existsSync();
          if (isExist) {
            return Image.file(File(stateElement.snapshotPath!), fit: BoxFit.fitWidth);
          }
        }
      }
    }

    if ((stateElement.snapshotUrl == null || stateElement.snapshotUrl == '') &&
        (stateElement.snapshotPath == null || stateElement.snapshotPath == '')) {
      return Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_kMediaBubbleRadius),
            border: Border.all(
              width: 1,
              color: Colors.black12,
            )),
        height: double.parse(height.toString()),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              LoadingAnimationWidget.staggeredDotsWave(
                color: theme.weakTextColor ?? Colors.grey,
                size: 28,
              )
            ],
          ),
        ),
      );
    }
    // 发送中或失败场景下优先用本地封面，避免触发无效下载。
    final bool shouldUseLocalSnapshot =
        (!PlatformUtils().isWeb && stateElement.snapshotUrl == null) ||
            widget.message.status == MessageStatus.V2TIM_MSG_STATUS_SENDING;
    // 发送时生成的本地封面。
    final bool hasPrimarySnapshot = (stateElement.snapshotPath ?? '').isNotEmpty;
    // SDK 缓存的封面文件。
    final bool hasCachedSnapshot = (stateElement.localSnapshotUrl ?? '').isNotEmpty;
    if (shouldUseLocalSnapshot) {
      if (hasPrimarySnapshot) {
        return Image.file(
          File(stateElement.snapshotPath!),
          fit: BoxFit.fitWidth,
        );
      }
      if (hasCachedSnapshot) {
        return Image.file(
          File(stateElement.localSnapshotUrl!),
          fit: BoxFit.fitWidth,
        );
      }
    }

    final bool shouldLoadNetwork = PlatformUtils().isWeb ||
        stateElement.localSnapshotUrl == null ||
        stateElement.localSnapshotUrl!.isEmpty;
    if (shouldLoadNetwork) {
      return Image.network(
        stateElement.snapshotUrl ?? '',
        fit: BoxFit.fitWidth,
      );
    }
    return Image.file(
      File(stateElement.localSnapshotUrl!),
      fit: BoxFit.fitWidth,
    );
  }

  /// 拉取视频的云端地址并尝试缓存本地，发送中/发送失败的消息跳过以避免 6017 报错。
  /// 仅当 msgID 存在时才发起下载请求，确保 SDK 参数完整。
  downloadMessageDetailAndSave() async {
    final int? status = widget.message.status;
    if (status == MessageStatus.V2TIM_MSG_STATUS_SENDING ||
        status == MessageStatus.V2TIM_MSG_STATUS_SEND_FAIL) {
      return;
    }
    // 视频元素理论上不为空，此处加保护避免异常崩溃。
    final V2TimVideoElem? videoElem = widget.message.videoElem;
    if (videoElem == null) {
      return;
    }
    if (TencentUtils.checkString(widget.message.msgID) != null) {
      if (TencentUtils.checkString(videoElem.videoUrl) == null) {
        final response = await _messageService.getMessageOnlineUrl(msgID: widget.message.msgID!);
        if (response.data != null) {
          widget.message.videoElem = response.data!.videoElem;
          Future.delayed(const Duration(microseconds: 10), () {
            setState(() => stateElement = response.data!.videoElem!);
          });
        }
      }
      if (!PlatformUtils().isWeb) {
        if (TencentUtils.checkString(videoElem.localVideoUrl) == null ||
            !File(videoElem.localVideoUrl!).existsSync()) {
          _messageService.downloadMessage(
            msgID: widget.message.msgID!,
            messageType: 5,
            imageType: 0,
            isSnapshot: false,
          );
        }
        if (TencentUtils.checkString(videoElem.localSnapshotUrl) == null ||
            !File(videoElem.localSnapshotUrl!).existsSync()) {
          _messageService.downloadMessage(
            msgID: widget.message.msgID!,
            messageType: 5,
            imageType: 0,
            isSnapshot: true,
          );
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    downloadMessageDetailAndSave();
  }

  void launchDesktopFile(String path) {
    if (PlatformUtils().isWindows) {
      OpenFile.open(path);
    } else {
      launchUrl(Uri.file(path));
    }
  }

  /// 构建视频播放页面路由，iOS 使用 CupertinoPageRoute 以开启系统侧滑返回，其他端保持透明层效果。
  /// [heroTag] 当前视频 Hero 标识；[element] 对应的视频元素；返回值为可直接 push 的路由。
  Route<dynamic> _buildVideoRoute(String heroTag, V2TimVideoElem element) {
    // 预先构建视频播放页，避免路由分支内重复创建。
    final videoScreen = VideoScreen(
      message: widget.message,
      heroTag: heroTag,
      videoElement: element,
    );
    if (PlatformUtils().isIOS) {
      return CupertinoPageRoute(
        builder: (_) => videoScreen,
        fullscreenDialog: false,
      );
    }
    return PageRouteBuilder(
      opaque: false,
      pageBuilder: (_, __, ___) => videoScreen,
    );
  }

  /// 构建视频消息气泡，负责封面展示、点击跳转和统一圆角裁剪。
  /// [value] 包含主题等上下文信息。
  @override
  Widget tuiBuild(BuildContext context, TUIKitBuildValue value) {
    final theme = value.theme;
    // 生成播放页动画的标识，优先使用消息 ID，其次使用时间戳兜底。
    final String heroBase = widget.message.msgID ??
        widget.message.id ??
        widget.message.timestamp?.toString() ??
        DateTime.now().millisecondsSinceEpoch.toString();
    final heroTag = "$heroBase${widget.isFrom}";
    // 是否已存在封面资源，用于控制播放按钮展示。
    final bool hasVideoSnapshot =
        (stateElement.snapshotUrl ?? '').isNotEmpty || (stateElement.snapshotPath ?? '').isNotEmpty;
    // 是否已存在视频文件或在线地址。
    final bool hasVideoSource =
        (stateElement.videoPath ?? '').isNotEmpty || (stateElement.videoUrl ?? '').isNotEmpty;

    return GestureDetector(
      onTap: () {
        if (PlatformUtils().isWeb) {
          final url = widget.message.videoElem?.videoUrl ?? widget.message.videoElem?.videoPath ?? "";
          TUIKitWidePopup.showMedia(
              context: context,
              mediaURL: url,
              onClickOrigin: () => launchUrl(
                    Uri.parse(url),
                    mode: LaunchMode.externalApplication,
                  ));
          return;
        }
        if (PlatformUtils().isDesktop) {
          final videoElem = widget.message.videoElem;
          if (videoElem != null) {
            final localVideoUrl = TencentUtils.checkString(videoElem.localVideoUrl);
            final videoPath = TencentUtils.checkString(videoElem.videoPath);
            final videoUrl = videoElem.videoUrl;
            if (localVideoUrl != null) {
              launchDesktopFile(localVideoUrl);
              // todo
              // TUIKitWidePopup.showMedia(
              //     context: context,
              //     mediaPath: localVideoUrl,
              //     onClickOrigin: () => launchDesktopFile(localVideoUrl));
            } else if (videoPath != null && File(videoPath).existsSync()) {
              launchDesktopFile(videoPath);
              // todo
              // TUIKitWidePopup.showMedia(
              //     context: context,
              //     mediaPath: videoPath,
              //     onClickOrigin: () => launchDesktopFile(videoPath));
            } else if (TencentUtils.isTextNotEmpty(videoUrl)) {
              onTIMCallback(
                TIMCallback(
                  infoCode: 6660414,
                  infoRecommendText: TIM_t("正在下载中"),
                  type: TIMCallbackType.INFO,
                ),
              );
            }
          }
        } else {
          Navigator.of(context).push(_buildVideoRoute(heroTag, stateElement));
        }
      },
      child: Hero(
          tag: heroTag,
          child: TIMUIKitMessageReactionWrapper(
              chatModel: widget.chatModel,
              message: widget.message,
              isShowJump: widget.isShowJump,
              isShowMessageReaction: widget.isShowMessageReaction ?? true,
              clearJump: widget.clearJump,
              isFromSelf: widget.message.isSelf ?? true,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(_kMediaBubbleRadius),
                child: LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
                  double? positionRadio;
                  if ((stateElement.snapshotWidth) != null &&
                      stateElement.snapshotHeight != null &&
                      stateElement.snapshotWidth != 0 &&
                      stateElement.snapshotHeight != 0) {
                    positionRadio = (stateElement.snapshotWidth! / stateElement.snapshotHeight!);
                  }
                  return ConstrainedBox(
                      constraints: BoxConstraints(
                          maxWidth: PlatformUtils().isWeb ? 300 : constraints.maxWidth * 0.5,
                          maxHeight: min(constraints.maxHeight * 0.8, 300),
                          minHeight: 20,
                          minWidth: 20),
                      child: Stack(
                        children: <Widget>[
                          if (positionRadio != null &&
                              (stateElement.snapshotUrl != null || stateElement.snapshotUrl != null))
                            AspectRatio(
                              aspectRatio: positionRadio,
                              child: Container(
                                decoration: const BoxDecoration(color: Colors.transparent),
                              ),
                            ),
                          Row(
                            children: [
                              Expanded(
                                child: generateSnapshot(
                                  theme,
                                  stateElement.snapshotHeight ?? 100,
                                ),
                              ),
                            ],
                          ),
                          if (widget.message.status != MessageStatus.V2TIM_MSG_STATUS_SENDING &&
                              hasVideoSnapshot &&
                              hasVideoSource)
                            Positioned.fill(
                              child: Center(
                                child: Image.asset(
                                  'images/play.png',
                                  package: 'tencent_cloud_chat_uikit',
                                  height: 64,
                                ),
                              ),
                            ),
                          if ((widget.message.videoElem?.duration ?? 0) > 0)
                            Positioned(
                              right: 10,
                              bottom: 10,
                              child: Text(
                                MessageUtils.formatVideoTime(widget.message.videoElem!.duration!).toString(),
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ),
                        ],
                      ));
                }),
              ))),
    );
  }
}
