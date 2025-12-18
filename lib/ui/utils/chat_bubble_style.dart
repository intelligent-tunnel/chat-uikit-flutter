import 'package:flutter/material.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_message.dart'
    if (dart.library.html) 'package:tencent_cloud_chat_sdk/web/compatible_models/v2_tim_message.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/view_models/tui_chat_global_model.dart';

/// 气泡样式工具，集中处理单聊灰色背景等统一配色策略。
class ChatBubbleStyle {
  /// 单聊默认的灰色气泡底色，保证 1v1 对话风格统一。
  static const Color c2cBubbleBackground = Color(0xFFF2F2F2);

  /// 计算气泡背景色。
  /// 入参：conversationType 会话类型；backgroundColor 外部指定颜色；themeBackground 主题色；
  /// isFromSelf 是否本人；selfFallbackColor 自己消息兜底色；otherFallbackColor 对端兜底色。
  /// 返回：最终用于渲染的气泡底色。
  /// 业务约束：单聊优先使用灰色背景，除非明确传入覆盖色，其余场景保持主题/默认配色。
  static Color resolveBubbleColor({
    required ConvType? conversationType,
    required Color? backgroundColor,
    required Color? themeBackground,
    required bool isFromSelf,
    required Color selfFallbackColor,
    required Color otherFallbackColor,
  }) {
    if (backgroundColor != null) {
      return backgroundColor;
    }

    if (conversationType == ConvType.c2c) {
      return c2cBubbleBackground;
    }

    if (themeBackground != null) {
      return themeBackground;
    }

    return isFromSelf ? selfFallbackColor : otherFallbackColor;
  }

  /// 兜底推断会话类型。
  /// 入参：conversationType 外部传入的会话类型；message 当前消息体。
  /// 返回：优先使用外部类型，其次依靠 groupID 判定群聊，否则视为单聊。
  /// 业务约束：消息为空时也回落到单聊，避免因空值导致颜色不可控。
  static ConvType resolveConversationType({
    required ConvType? conversationType,
    V2TimMessage? message,
  }) {
    if (conversationType != null) {
      return conversationType;
    }

    if (message != null && (message.groupID?.isNotEmpty ?? false)) {
      return ConvType.group;
    }

    return ConvType.c2c;
  }
}
