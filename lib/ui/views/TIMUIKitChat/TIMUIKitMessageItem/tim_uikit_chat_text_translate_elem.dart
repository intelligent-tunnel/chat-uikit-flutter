import 'dart:async';
import 'dart:convert';

import 'package:tencent_chat_i18n_tool/tencent_chat_i18n_tool.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_message.dart'
    if (dart.library.html) 'package:tencent_cloud_chat_sdk/web/compatible_models/v2_tim_message.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/screen_utils.dart';
import 'package:extended_text/extended_text.dart';
import 'package:flutter/material.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_base.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_state.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/separate_models/tui_chat_separate_view_model.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/view_models/tui_chat_global_model.dart';
import 'package:tencent_cloud_chat_uikit/tencent_cloud_chat_uikit.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/chat_bubble_style.dart';
import 'package:tencent_cloud_chat_uikit/ui/views/TIMUIKitChat/TIMUIKitTextField/special_text/DefaultSpecialTextSpanBuilder.dart';
import 'package:tencent_cloud_chat_uikit/ui/widgets/link_preview/link_preview_entry.dart';

const BorderRadius _kSelfBubbleRadius = BorderRadius.all(Radius.circular(12));
const BorderRadius _kOtherBubbleRadius = BorderRadius.all(Radius.circular(12));

// 统一翻译/转写文本背景为 0xFFF8F8F8（无论是自己还是对方）
const Color _kDefaultSelfBubbleColor = Color(0xFFF8F8F8);
const Color _kDefaultOtherBubbleColor = Color(0xFFF8F8F8);

class TIMUIKitTextTranslationElem extends StatefulWidget {
  final V2TimMessage message;
  final bool isFromSelf;
  final bool isShowJump;
  final VoidCallback clearJump;
  final TextStyle? fontStyle;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? textPadding;
  final TUIChatSeparateViewModel chatModel;
  final bool? isShowMessageReaction;
  final List<CustomEmojiFaceData> customEmojiStickerList;

  const TIMUIKitTextTranslationElem(
      {Key? key,
      required this.message,
      required this.isFromSelf,
      required this.isShowJump,
      required this.clearJump,
      this.fontStyle,
      this.borderRadius,
      this.isShowMessageReaction,
      this.backgroundColor,
      this.textPadding,
      required this.chatModel,
      this.customEmojiStickerList = const []})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _TIMUIKitTextTranslationElemState();
}

class _TIMUIKitTextTranslationElemState
    extends TIMUIKitState<TIMUIKitTextTranslationElem> {
  bool isShowJumpState = false;
  bool isShining = false;

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
    Future.delayed(const Duration(milliseconds: 100), () {
      widget.clearJump();
    });
  }

  @override
  Widget tuiBuild(BuildContext context, TUIKitBuildValue value) {
    final theme = value.theme;
    final isDesktopScreen =
        TUIKitScreenUtils.getFormFactor(context) == DeviceType.Desktop;
    final BorderRadius resolvedBorderRadius = widget.borderRadius ??
        (widget.isFromSelf ? _kSelfBubbleRadius : _kOtherBubbleRadius);
    if ((widget.chatModel.jumpMsgID == widget.message.msgID)) {}
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

    // 兜底会话类型，优先取控制器设置，缺省按消息判定单聊/群聊。
    final ConvType conversationType = ChatBubbleStyle.resolveConversationType(
        conversationType: widget.chatModel.conversationType,
        message: widget.message);

    // 单聊保持灰色背景，其余继续使用翻译消息默认灰。
    final Color resolvedBubbleColor = ChatBubbleStyle.resolveBubbleColor(
        conversationType: conversationType,
        backgroundColor: widget.backgroundColor,
        themeBackground: null,
        isFromSelf: widget.isFromSelf,
        selfFallbackColor: _kDefaultSelfBubbleColor,
        otherFallbackColor: _kDefaultOtherBubbleColor);

    // 单聊自己翻译气泡文字统一白色，其他场景沿用默认颜色。
    final Color? resolvedTextColor = ChatBubbleStyle.resolveTextColor(
        conversationType: conversationType,
        isFromSelf: widget.isFromSelf,
        defaultColor: widget.fontStyle?.color);
    final TextStyle resolvedTextStyle = (widget.fontStyle ??
            TextStyle(
                fontSize: isDesktopScreen ? 14 : 16,
                textBaseline: TextBaseline.ideographic,
                height: widget.chatModel.chatConfig.textHeight))
        .copyWith(color: resolvedTextColor ?? widget.fontStyle?.color);
    // 翻译提示颜色，单聊蓝底跟随白字，其他场景降透明度弱化。
    final Color tipsColor =
        (resolvedTextColor ?? const Color(0xFF282C34)).withOpacity(0.7);

    final backgroundColor = isShowJumpState
        ? const Color.fromRGBO(245, 166, 35, 1)
        : resolvedBubbleColor;

    final LocalCustomDataModel localCustomData = LocalCustomDataModel.fromMap(
        json.decode(
            TencentUtils.checkString(widget.message.localCustomData) ?? "{}"));
    final String? translateText = localCustomData.translatedText;

    final textWithLink = LinkPreviewEntry.getHyperlinksText(translateText ?? "",
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

    final bool isVoiceTranscription = widget.message.soundElem != null;

    return TencentUtils.checkString(translateText) != null
        ? Container(
            margin: const EdgeInsets.only(top: 6),
            padding:
                widget.textPadding ?? EdgeInsets.all(isDesktopScreen ? 12 : 10),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: resolvedBorderRadius,
            ),
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // If the [elemType] is text message, it will not be null here.
                // You can render the widget from extension directly, with a [TextStyle] optionally.
                widget.chatModel.chatConfig.urlPreviewType !=
                        UrlPreviewType.none
                    ? textWithLink!(
                        style: resolvedTextStyle)
                    : ExtendedText(translateText!,
                        softWrap: true,
                        style: resolvedTextStyle,
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
                if (!isVoiceTranscription) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: tipsColor.withOpacity(0.7),
                        size: 12,
                      ),
                      const SizedBox(
                        width: 4,
                      ),
                      Text(
                        TIM_t("翻译完成"),
                        style: TextStyle(color: tipsColor, fontSize: 10),
                      )
                    ],
                  )
                ]
              ],
            ),
          )
        : const SizedBox(width: 0, height: 0);
  }
}
