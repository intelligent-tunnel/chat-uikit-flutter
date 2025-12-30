
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:tencent_cloud_chat_uikit/ui/widgets/link_preview/common/utils.dart';
import 'package:extended_text/extended_text.dart';

class HttpText extends SpecialText {
  HttpText(TextStyle? textStyle, SpecialTextGestureTapCallback? onTap,
      {this.start})
      : super(flag, flag, textStyle, onTap: onTap);
  static const String flag = '!@TURL#*&\$';
  final int? start;

  /// 构建超链接的富文本展示。
  /// - 入参：无显式入参，使用 [textStyle] 与当前文本内容构建。
  /// - 返回：带点击事件的 [InlineSpan]，用于渲染超链接。
  /// - 业务约束：超链接样式统一走 [LinkUtils.resolveLinkTextStyle]，
  ///   跟随文本颜色并补充下划线。
  @override
  InlineSpan finishText() {
    final String text = getContent();

    return SpecialTextSpan(
        text: text,
        actualText: toString(),
        start: start!,

        ///caret can move into special text
        deleteAll: true,
        style: LinkUtils.resolveLinkTextStyle(textStyle),
        recognizer: TapGestureRecognizer()
          ..onTap = () {
            if (onTap != null) {
              onTap!(toString());
            }
          });
  }
}
