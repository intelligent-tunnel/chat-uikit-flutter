// ignore_for_file: unrelated_type_equality_checks

import 'package:flutter/material.dart';
import 'package:tencent_chat_i18n_tool/tencent_chat_i18n_tool.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_custom_elem.dart'
    if (dart.library.html) 'package:tencent_cloud_chat_sdk/web/compatible_models/v2_tim_custom_elem.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_message.dart'
    if (dart.library.html) 'package:tencent_cloud_chat_sdk/web/compatible_models/v2_tim_message.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_base.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_statelesswidget.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/view_models/tui_chat_global_model.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/chat_bubble_style.dart';

const BorderRadius _kSelfBubbleRadius = BorderRadius.all(Radius.circular(12));
const BorderRadius _kOtherBubbleRadius = BorderRadius.all(Radius.circular(12));

const Color _kDefaultSelfBubbleColor = Color(0xFFFCF0CA);
const Color _kDefaultOtherBubbleColor = Color(0xFFF8F8F8);

class TIMUIKitCustomElem extends TIMUIKitStatelessWidget {
  final V2TimCustomElem? customElem;
  final bool isFromSelf;
  final TextStyle? messageFontStyle;
  final BorderRadius? messageBorderRadius;
  final Color? messageBackgroundColor;
  final EdgeInsetsGeometry? textPadding;
  final V2TimMessage message;
  final bool? isShowMessageReaction;

  TIMUIKitCustomElem({
    Key? key,
    required this.message,
    this.isShowMessageReaction,
    this.customElem,
    this.isFromSelf = false,
    this.messageFontStyle,
    this.messageBorderRadius,
    this.messageBackgroundColor,
    this.textPadding,
  }) : super(key: key);

  @override
  Widget tuiBuild(BuildContext context, TUIKitBuildValue value) {
    final theme = value.theme;
    final BorderRadius resolvedBorderRadius = messageBorderRadius ??
        (isFromSelf ? _kSelfBubbleRadius : _kOtherBubbleRadius);
    final Color? themeBackground = isFromSelf
        ? (theme.chatMessageItemFromSelfBgColor ??
            theme.lightPrimaryMaterialColor.shade50)
        : (theme.chatMessageItemFromOthersBgColor ??
            theme.weakBackgroundColor);

    // 兜底会话类型，未传入时按消息体判断单聊/群聊。
    final ConvType conversationType = ChatBubbleStyle.resolveConversationType(
        conversationType: null, message: message);

    // 单聊强制灰底，未覆盖时退回主题或默认色。
    final Color resolvedBubbleColor = ChatBubbleStyle.resolveBubbleColor(
        conversationType: conversationType,
        backgroundColor: messageBackgroundColor,
        themeBackground: themeBackground,
        isFromSelf: isFromSelf,
        selfFallbackColor: _kDefaultSelfBubbleColor,
        otherFallbackColor: _kDefaultOtherBubbleColor);
    return Container(
        padding: textPadding ?? const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: resolvedBubbleColor,
          borderRadius: resolvedBorderRadius,
        ),
        constraints: const BoxConstraints(maxWidth: 240),
        child: Column(
          children: [Text(TIM_t("自定义消息"))],
        ));
  }
}
