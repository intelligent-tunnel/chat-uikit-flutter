// ignore_for_file: unused_import

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:tencent_chat_i18n_tool/tencent_chat_i18n_tool.dart';
import 'package:tencent_cloud_chat_sdk/enum/message_elem_type.dart';
import 'package:tencent_cloud_chat_sdk/enum/message_status.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_message.dart'
    if (dart.library.html) 'package:tencent_cloud_chat_sdk/web/compatible_models/v2_tim_message.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_sound_elem.dart'
    if (dart.library.html) 'package:tencent_cloud_chat_sdk/web/compatible_models/v2_tim_sound_elem.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/separate_models/tui_chat_model_tools.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/common_utils.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/platform.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/screen_utils.dart';
import 'package:tencent_cloud_chat_uikit/ui/views/TIMUIKitChat/TIMUIKitTextField/special_text/DefaultSpecialTextSpanBuilder.dart';
import 'package:extended_text/extended_text.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_callback.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_base.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_state.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/separate_models/tui_chat_separate_view_model.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/view_models/tui_chat_global_model.dart';
import 'package:tencent_cloud_chat_uikit/data_services/services_locatar.dart';
import 'package:tencent_cloud_chat_uikit/data_services/message/message_services.dart';
import 'package:tencent_cloud_chat_uikit/theme/tui_theme.dart';
import 'package:tencent_cloud_chat_uikit/ui/views/TIMUIKitChat/TIMUIKitMessageItem/TIMUIKitMessageReaction/tim_uikit_message_reaction_show_panel.dart';
import 'package:tencent_cloud_chat_uikit/ui/views/TIMUIKitChat/TIMUIKitMessageItem/main.dart';
import 'package:tencent_cloud_chat_uikit/ui/views/TIMUIKitChat/TIMUIKitMessageItem/tim_uikit_chat_face_elem.dart';
import 'package:tencent_cloud_chat_uikit/ui/views/TIMUIKitChat/tim_uikit_chat_config.dart';
import 'package:tencent_cloud_chat_uikit/ui/views/TIMUIKitChat/tim_uikit_cloud_custom_data.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/chat_bubble_style.dart';
import 'package:tencent_cloud_chat_uikit/ui/widgets/link_preview/link_preview_entry.dart';
import 'package:tencent_cloud_chat_uikit/ui/widgets/link_preview/models/link_preview_content.dart';
import 'package:tencent_cloud_chat_uikit/ui/widgets/link_preview/widgets/link_preview.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/logger.dart';
import 'package:tim_ui_kit_sticker_plugin/utils/tim_custom_face_data.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/sound_record.dart';

const BorderRadius _kSelfBubbleRadius = BorderRadius.all(Radius.circular(12));
const BorderRadius _kOtherBubbleRadius = BorderRadius.all(Radius.circular(12));

const Color _kDefaultSelfBubbleColor = Color(0xFFFCF0CA);
const Color _kDefaultOtherBubbleColor = Color(0xFFF8F8F8);

class TIMUIKitReplyElem extends StatefulWidget {
  final V2TimMessage message;
  final Function scrollToIndex;
  final bool isShowJump;
  final VoidCallback clearJump;
  final TextStyle? fontStyle;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? textPadding;
  final TUIChatSeparateViewModel chatModel;
  final bool? isShowMessageReaction;
  final List<CustomEmojiFaceData> customEmojiStickerList;

  const TIMUIKitReplyElem({
    Key? key,
    required this.message,
    required this.scrollToIndex,
    this.isShowJump = false,
    required this.clearJump,
    this.fontStyle,
    this.borderRadius,
    this.isShowMessageReaction,
    this.backgroundColor,
    this.textPadding,
    this.customEmojiStickerList = const [],
    required this.chatModel,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _TIMUIKitReplyElemState();
}

class _TIMUIKitReplyElemState extends TIMUIKitState<TIMUIKitReplyElem> {
  MessageRepliedData? repliedMessage;
  V2TimMessage? rawMessage;
  bool isShowJumpState = false;
  bool isShining = false;

  MessageRepliedData? _getRepliedMessage() {
    try {
      final CloudCustomData messageCloudCustomData = CloudCustomData.fromJson(
          json.decode(
              TencentUtils.checkString(widget.message.cloudCustomData) != null
                  ? widget.message.cloudCustomData!
                  : "{}"));
      if (messageCloudCustomData.messageReply != null) {
        final MessageRepliedData repliedMessage =
            MessageRepliedData.fromJson(messageCloudCustomData.messageReply!);
        return repliedMessage;
      }
      return null;
    } catch (error) {
      return null;
    }
  }

  _getMessageByMessageID() async {
    final MessageRepliedData? cloudCustomData = _getRepliedMessage();
    if (cloudCustomData != null) {
      if (mounted) {
        setState(() {
          repliedMessage = cloudCustomData;
        });
      }

      final messageID = cloudCustomData.messageID;
      if (PlatformUtils().isWeb) {
        return;
      }
      V2TimMessage? message = await widget.chatModel.findMessage(messageID);
      if (message == null) {
        try {
          final RepliedMessageAbstract repliedMessageAbstract =
              RepliedMessageAbstract.fromJson(
                  jsonDecode(cloudCustomData.messageAbstract));
          if (repliedMessageAbstract.isNotEmpty) {
            message = V2TimMessage(
                elemType: 0,
                seq: repliedMessageAbstract.seq,
                timestamp: repliedMessageAbstract.timestamp,
                msgID: repliedMessageAbstract.msgID);
          }
        } catch (e) {
          // ignore: avoid_print
          outputLogger.i(e.toString());
        }
      }
      if (message != null) {
        if (mounted) {
          setState(() {
            rawMessage = message;
          });
        }
      }
    }
  }

  DefaultSpecialTextSpanBuilder _buildSpanBuilder() {
    final StickerPanelConfig? stickerConfig =
        widget.chatModel.chatConfig.stickerPanelConfig;
    return DefaultSpecialTextSpanBuilder(
      isUseQQPackage: stickerConfig?.useQQStickerPackage ?? true,
      isUseTencentCloudChatPackage:
          stickerConfig?.useTencentCloudChatStickerPackage ?? true,
      isUseTencentCloudChatPackageOldKeys:
          stickerConfig?.useTencentCloudChatStickerPackageOldKeys ?? false,
      customEmojiStickerList: widget.customEmojiStickerList,
      showAtBackground: true,
      checkHttpLink: true,
    );
  }

  TextStyle _defaultSummaryStyle(TUITheme? theme) {
    return TextStyle(
      fontSize: 12,
      color: theme?.weakTextColor,
      fontWeight: FontWeight.w400,
      height: 1.3,
    );
  }

  Widget _defaultRawMessageText(String text, TUITheme? theme) {
    final style = _defaultSummaryStyle(theme);
    return ExtendedText(
      text,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      softWrap: true,
      style: style,
      specialTextSpanBuilder: _buildSpanBuilder(),
    );
  }

  _renderMessageSummary(TUITheme? theme) {
    try {
      final RepliedMessageAbstract repliedMessageAbstract =
          RepliedMessageAbstract.fromJson(
              jsonDecode(repliedMessage?.messageAbstract ?? ""));
      if (TencentUtils.checkString(repliedMessageAbstract.summary) != null) {
        return _defaultRawMessageText(repliedMessageAbstract.summary!, theme);
      }
      return _defaultRawMessageText(
          repliedMessage?.messageAbstract ?? TIM_t("[未知消息]"), theme);
    } catch (e) {
      return _defaultRawMessageText(
          repliedMessage?.messageAbstract ?? TIM_t("[未知消息]"), theme);
    }
  }

  (bool isRevoke, bool isRevokeByAdmin) isRevokeMessage(V2TimMessage message) {
    if (message.status == 6) {
      return (true, false);
    } else {
      try {
        final customData = jsonDecode(message.cloudCustomData ?? "{}");
        final isRevoke = customData["isRevoke"] ?? false;
        final revokeByAdmin = customData["revokeByAdmin"] ?? false;
        return (isRevoke, revokeByAdmin);
      } catch (e) {
        return (false, false);
      }
    }
  }

  _rawMessageBuilder(V2TimMessage? message, TUITheme? theme) {
    if (repliedMessage == null) {
      return const SizedBox(width: 0, height: 12);
    }
    if (message == null) {
      if (repliedMessage?.messageAbstract != null) {
        return _renderMessageSummary(theme);
      }
      return const SizedBox(width: 0, height: 12);
    }

    final revokeStatus = isRevokeMessage(message);
    final isRevokedMsg = revokeStatus.$1;
    final isAdminRevoke = revokeStatus.$2;

    if (isRevokedMsg) {
      return _defaultRawMessageText(
          isAdminRevoke ? TIM_t("[消息被管理员撤回]") : TIM_t("[消息被撤回]"), theme);
    }

    final messageType = message.elemType;
    final isSelf = message.isSelf ?? true;
    final customAbstractMessage =
        widget.chatModel.abstractMessageBuilder != null
            ? widget.chatModel.abstractMessageBuilder!(message)
            : null;
    if (customAbstractMessage != null) {
      return _defaultRawMessageText(customAbstractMessage, theme);
    }
    switch (messageType) {
      case MessageElemType.V2TIM_ELEM_TYPE_CUSTOM:
        return _defaultRawMessageText(TIM_t("[自定义]"), theme);
      case MessageElemType.V2TIM_ELEM_TYPE_SOUND:
        if (message.soundElem == null) {
          return _defaultRawMessageText(TIM_t("[语音消息]"), theme);
        }
        return _ReplyVoicePreview(
          message: message,
          chatModel: widget.chatModel,
        );
      case MessageElemType.V2TIM_ELEM_TYPE_TEXT:
        return ExtendedText(
          message.textElem?.text ?? "",
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          softWrap: true,
          style: _defaultSummaryStyle(theme),
          specialTextSpanBuilder: _buildSpanBuilder(),
        );
      case MessageElemType.V2TIM_ELEM_TYPE_FACE:
        return TIMUIKitFaceElem(
          model: widget.chatModel,
          isShowJump: false,
          isShowMessageReaction: false,
          path: message.faceElem!.data ?? "",
          message: message,
        );
      case MessageElemType.V2TIM_ELEM_TYPE_FILE:
        return TIMUIKitFileElem(
            chatModel: widget.chatModel,
            isShowMessageReaction: false,
            message: message,
            messageID: message.msgID,
            fileElem: message.fileElem,
            isSelf: isSelf,
            isShowJump: false);
      case MessageElemType.V2TIM_ELEM_TYPE_IMAGE:
        return TIMUIKitImageElem(
            chatModel: widget.chatModel,
            message: message,
            isFrom: "reply",
            isShowMessageReaction: false);
      case MessageElemType.V2TIM_ELEM_TYPE_VIDEO:
        return TIMUIKitVideoElem(message,
            chatModel: widget.chatModel,
            isFrom: "reply",
            isShowMessageReaction: false);
      case MessageElemType.V2TIM_ELEM_TYPE_LOCATION:
        return _defaultRawMessageText(TIM_t("[位置]"), theme);
      case MessageElemType.V2TIM_ELEM_TYPE_MERGER:
        return TIMUIKitMergerElem(
            model: widget.chatModel,
            isShowJump: false,
            isShowMessageReaction: false,
            message: message,
            mergerElem: message.mergerElem!,
            messageID: message.msgID ?? "",
            isSelf: isSelf);
      default:
        return _renderMessageSummary(theme);
    }
  }

  @override
  void initState() {
    _getMessageByMessageID();
    super.initState();
  }

  @override
  void didUpdateWidget(covariant TIMUIKitReplyElem oldWidget) {
    WidgetsBinding.instance.addPostFrameCallback((mag) {
      super.didUpdateWidget(oldWidget);
      _getMessageByMessageID();
    });
  }

  _showJumpColor() {
    if ((widget.chatModel.jumpMsgID != widget.message.msgID) &&
        (widget.message.msgID?.isNotEmpty ?? true)) {
      return;
    }
    isShining = true;
    int shineAmount = 6;
    setState(() {
      isShowJumpState = true;
    });
    Timer.periodic(const Duration(milliseconds: 300), (timer) {
      if (mounted) {
        setState(() {
          isShowJumpState = shineAmount.isOdd ? true : false;
        });
      }
      if (shineAmount == 0 || !mounted) {
        isShining = false;
        timer.cancel();
      }
      shineAmount--;
    });
    widget.clearJump();
  }

  void _jumpToRawMsg() {
    if (rawMessage?.status != MessageStatus.V2TIM_MSG_STATUS_LOCAL_REVOKED &&
        rawMessage?.timestamp != null) {
      widget.scrollToIndex(rawMessage);
    } else {
      onTIMCallback(TIMCallback(
          type: TIMCallbackType.INFO, infoRecommendText: TIM_t("无法定位到原消息")));
    }
  }

  Future<bool> _handleReplyTap(BuildContext context) async {
    final callback = widget.chatModel.chatConfig.onTapReplyMessage;
    final MessageRepliedData? replied = repliedMessage ?? _getRepliedMessage();
    if (callback == null || replied == null) {
      return false;
    }
    try {
      final result =
          await callback(context, rawMessage, replied, widget.message);
      return result == true;
    } catch (e, stack) {
      outputLogger.i("onTapReplyMessage failed: $e");
      outputLogger.i(stack.toString());
      return false;
    }
  }

  Widget? _renderPreviewWidget() {
    // If the link preview info from [localCustomData] is available, use it to render the preview card.
    // Otherwise, it will returns null.
    if (widget.message.localCustomData != null &&
        widget.message.localCustomData!.isNotEmpty) {
      try {
        final String localJSON = widget.message.localCustomData!;
        final LocalCustomDataModel? localPreviewInfo =
            LocalCustomDataModel.fromMap(json.decode(localJSON));
        if (localPreviewInfo != null &&
            !localPreviewInfo.isLinkPreviewEmpty()) {
          return Container(
            margin: const EdgeInsets.only(top: 8),
            child:
                // You can use this default widget [LinkPreviewWidget] to render preview card, or you can use custom widget.
                LinkPreviewWidget(linkPreview: localPreviewInfo),
          );
        } else {
          return null;
        }
      } catch (e) {
        return null;
      }
    } else {
      return null;
    }
  }

  @override
  Widget tuiBuild(BuildContext context, TUIKitBuildValue value) {
    final theme = value.theme;
    final isDesktopScreen =
        TUIKitScreenUtils.getFormFactor(context) == DeviceType.Desktop;
    if (widget.isShowJump) {
      if (!isShining) {
        Future.delayed(Duration.zero, () {
          _showJumpColor();
        });
      } else {
        if ((widget.chatModel.jumpMsgID == widget.message.msgID) &&
            (widget.message.msgID?.isNotEmpty ?? false)) {
          widget.clearJump();
        }
      }
    }

    final isFromSelf = widget.message.isSelf ?? true;

    final Color? themeBackground = isFromSelf
        ? (theme.chatMessageItemFromSelfBgColor ??
            theme.lightPrimaryMaterialColor.shade50)
        : theme.chatMessageItemFromOthersBgColor;

    // 兜底会话类型，优先使用控制器类型，空值时按消息体推断。
    final ConvType conversationType = ChatBubbleStyle.resolveConversationType(
        conversationType: widget.chatModel.conversationType,
        message: widget.message);

    // 单聊统一灰底，主题或默认色为其他场景兜底。
    final Color resolvedBubbleColor = ChatBubbleStyle.resolveBubbleColor(
        conversationType: conversationType,
        backgroundColor: widget.backgroundColor,
        themeBackground: themeBackground,
        isFromSelf: isFromSelf,
        selfFallbackColor: _kDefaultSelfBubbleColor,
        otherFallbackColor: _kDefaultOtherBubbleColor);

    final backgroundColor = isShowJumpState
        ? const Color.fromRGBO(245, 166, 35, 1)
        : resolvedBubbleColor;

    final BorderRadius resolvedBorderRadius = widget.borderRadius ??
        (isFromSelf ? _kSelfBubbleRadius : _kOtherBubbleRadius);
    final textWithLink = LinkPreviewEntry.getHyperlinksText(
        widget.message.textElem?.text ?? "",
        widget.chatModel.chatConfig.isSupportMarkdownForTextMessage,
        onLinkTap: widget.chatModel.chatConfig.onTapLink,
        isUseQQPackage: widget
                .chatModel.chatConfig.stickerPanelConfig?.useQQStickerPackage ??
            true,
        isUseTencentCloudChatPackage: widget.chatModel.chatConfig
                .stickerPanelConfig?.useTencentCloudChatStickerPackage ??
            true,
        isUseTencentCloudChatPackageOldKeys: widget.chatModel.chatConfig
                .stickerPanelConfig?.useTencentCloudChatStickerPackageOldKeys ??
            false,
        customEmojiStickerList: widget.customEmojiStickerList,
        isEnableTextSelection:
            widget.chatModel.chatConfig.isEnableTextSelection ?? false);
    return Container(
      padding: widget.textPadding ?? EdgeInsets.all(isDesktopScreen ? 12 : 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: resolvedBorderRadius,
      ),
      constraints:
          BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.6),
      child: GestureDetector(
        onTap: () async {
          final handled = await _handleReplyTap(context);
          if (!handled) {
            _jumpToRawMsg();
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              // 这里是引用的部分
              padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 6),
              constraints: const BoxConstraints(minWidth: 120),
              decoration: const BoxDecoration(
                  color: Color.fromRGBO(68, 68, 68, 0.05),
                  border: Border(
                      left: BorderSide(
                          color: Color.fromRGBO(68, 68, 68, 0.1), width: 2))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    repliedMessage != null
                        ? "${repliedMessage!.messageSender}:"
                        : "",
                    style: TextStyle(
                        fontSize: 12,
                        color: theme.weakTextColor,
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(
                    height: 4,
                  ),
                  _rawMessageBuilder(rawMessage, theme)
                ],
              ),
            ),
            const SizedBox(
              height: 12,
            ),
            // If the [elemType] is text message, it will not be null here.
            // You can render the widget from extension directly, with a [TextStyle] optionally.
            widget.chatModel.chatConfig.urlPreviewType != UrlPreviewType.none
                ? textWithLink!(
                    style: widget.fontStyle ??
                        TextStyle(
                            fontSize: isDesktopScreen ? 14 : 16,
                            textBaseline: TextBaseline.ideographic,
                            height: widget.chatModel.chatConfig.textHeight))
                : ExtendedText(widget.message.textElem?.text ?? "",
                    softWrap: true,
                    style: widget.fontStyle ??
                        TextStyle(
                            fontSize: isDesktopScreen ? 14 : 16,
                            height: widget.chatModel.chatConfig.textHeight),
                    specialTextSpanBuilder: DefaultSpecialTextSpanBuilder(
                      isUseQQPackage: widget.chatModel.chatConfig
                              .stickerPanelConfig?.useQQStickerPackage ??
                          true,
                      isUseTencentCloudChatPackage: widget
                              .chatModel
                              .chatConfig
                              .stickerPanelConfig
                              ?.useTencentCloudChatStickerPackage ??
                          true,
                      isUseTencentCloudChatPackageOldKeys: widget
                              .chatModel
                              .chatConfig
                              .stickerPanelConfig
                              ?.useTencentCloudChatStickerPackageOldKeys ??
                          false,
                      customEmojiStickerList: widget.customEmojiStickerList,
                      showAtBackground: true,
                    )),
            // If the link preview info is available, render the preview card.
            if (_renderPreviewWidget() != null &&
                widget.chatModel.chatConfig.urlPreviewType ==
                    UrlPreviewType.previewCardAndHyperlink)
              _renderPreviewWidget()!,
            if (widget.isShowMessageReaction ?? true)
              TIMUIKitMessageReactionShowPanel(message: widget.message)
          ],
        ),
      ),
    );
  }
}

class _ReplyVoicePreview extends StatefulWidget {
  final V2TimMessage message;
  final TUIChatSeparateViewModel chatModel;

  const _ReplyVoicePreview({required this.message, required this.chatModel});

  @override
  State<_ReplyVoicePreview> createState() => _ReplyVoicePreviewState();
}

class _ReplyVoicePreviewState extends State<_ReplyVoicePreview>
    with SingleTickerProviderStateMixin {
  final MessageService _messageService = serviceLocator<MessageService>();
  late final AnimationController _waveController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );
  late final Animation<double> _waveAnimation =
      Tween<double>(begin: 0, end: 2 * math.pi).animate(_waveController);
  V2TimSoundElem? _soundElem;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _soundElem = widget.message.soundElem;
    _prepareSoundElem();
  }

  @override
  void didUpdateWidget(covariant _ReplyVoicePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message.msgID != widget.message.msgID) {
      _soundElem = widget.message.soundElem;
      _prepareSoundElem();
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  Future<V2TimSoundElem?> _prepareSoundElem() async {
    final String? msgID = widget.message.msgID;
    if (_soundElem != null &&
        _soundElem!.url != null &&
        _soundElem!.url!.isNotEmpty) {
      return _soundElem;
    }
    if (msgID == null || msgID.isEmpty) {
      return _soundElem;
    }
    try {
      final response = await _messageService.getMessageOnlineUrl(msgID: msgID);
      final V2TimSoundElem? updated = response.data?.soundElem;
      if (updated != null) {
        _soundElem = updated;
        widget.message.soundElem = _soundElem;
        if (mounted) {
          setState(() {});
        }
      }
    } catch (_) {}
    return _soundElem;
  }

  void _setPlaying(bool playing) {
    if (_isPlaying == playing) {
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _isPlaying = playing;
      if (_isPlaying) {
        if (!_waveController.isAnimating) {
          _waveController.repeat();
        }
      } else {
        _waveController.stop();
      }
    });
  }

  Future<void> _togglePlay() async {
    final String? msgID = widget.message.msgID;
    if (msgID == null || msgID.isEmpty) {
      return;
    }
    if (!SoundPlayer.isInit) {
      SoundPlayer.initSoundPlayer();
    }
    if (widget.chatModel.currentPlayedMsgId == msgID && _isPlaying) {
      SoundPlayer.stop();
      widget.chatModel.currentPlayedMsgId = "";
      _setPlaying(false);
      return;
    }
    final V2TimSoundElem? soundElem = await _prepareSoundElem();
    final String? url = soundElem?.url;
    if (url == null || url.isEmpty) {
      return;
    }
    try {
      widget.chatModel.currentPlayedMsgId = msgID;
      SoundPlayer.play(url: url);
      _setPlaying(true);
    } catch (_) {
      widget.chatModel.currentPlayedMsgId = "";
      _setPlaying(false);
    }
  }

  String _formatDuration(int? seconds) {
    final int safeSeconds = (seconds ?? 0).clamp(0, 3599);
    final int minutes = safeSeconds ~/ 60;
    final int remain = safeSeconds % 60;
    return "${minutes.toString()}:${remain.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final bool shouldPlaying =
        widget.chatModel.currentPlayedMsgId == widget.message.msgID;
    if (shouldPlaying != _isPlaying) {
      _setPlaying(shouldPlaying);
    }
    final String durationLabel = _formatDuration(
        _soundElem?.duration ?? widget.message.soundElem?.duration);
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        _togglePlay();
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 120,
            height: 20,
            child: _ReplyVoiceWaveform(
              animation: _waveAnimation,
              active: _isPlaying,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            durationLabel,
            style: const TextStyle(
              color: Color(0xFF101010),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReplyVoiceWaveform extends StatelessWidget {
  const _ReplyVoiceWaveform({required this.animation, required this.active});

  final Animation<double> animation;
  final bool active;

  static const List<double> _barHeights = <double>[
    4,
    6,
    10,
    16,
    22,
    18,
    12,
    8,
    6,
    4
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final double progress = animation.value;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(_barHeights.length, (index) {
            return _ReplyWaveBar(
              height: _computeHeight(_barHeights[index], progress, index),
              opacity: _computeOpacity(progress, index),
              active: active,
            );
          }),
        );
      },
    );
  }

  double _computeHeight(double base, double progress, int index) {
    if (!active) {
      return base;
    }
    final double phase = progress + index * 0.35;
    final double wave = (math.sin(phase) + 1) / 2;
    return base + wave * 12;
  }

  double _computeOpacity(double progress, int index) {
    if (!active) {
      return 0.4;
    }
    final double phase = progress + index * 0.4;
    final double wave = (math.sin(phase) + 1) / 2;
    return 0.5 + wave * 0.5;
  }
}

class _ReplyWaveBar extends StatelessWidget {
  const _ReplyWaveBar(
      {required this.height, required this.opacity, required this.active});

  final double height;
  final double opacity;
  final bool active;

  @override
  Widget build(BuildContext context) {
    const Color baseColor = Color(0xFFFBD455);
    final Color barColor = active
        ? baseColor.withValues(alpha: opacity.clamp(0.5, 1.0))
        : baseColor.withValues(alpha: 0.4);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 6,
      height: height.clamp(4, 32),
      decoration: BoxDecoration(
        color: barColor,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}
