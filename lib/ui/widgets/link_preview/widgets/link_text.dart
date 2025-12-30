// ignore_for_file: deprecated_member_use

import 'package:tencent_cloud_chat_uikit/ui/utils/platform.dart';
import 'package:extended_text/extended_text.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_stateless_widget.dart';
import 'package:tencent_cloud_chat_uikit/ui/views/TIMUIKitChat/TIMUIKitTextField/special_text/http_text.dart';
import 'package:tencent_cloud_chat_uikit/ui/widgets/link_preview/compiler/md_text.dart';
import 'package:tencent_cloud_chat_uikit/ui/views/TIMUIKitChat/TIMUIKitTextField/special_text/DefaultSpecialTextSpanBuilder.dart';
import 'package:tencent_cloud_chat_uikit/ui/widgets/link_preview/common/utils.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:tim_ui_kit_sticker_plugin/utils/tim_custom_face_data.dart';

typedef ImageBuilder = Widget Function(
    Uri uri, String? imageDirectory, double? width, double? height);

class LinkTextMarkdown extends TIMStatelessWidget {
  /// Callback for when link is tapped
  final void Function(String)? onLinkTap;

  /// message text
  final String messageText;

  /// text style for default words
  final TextStyle? style;

  final bool? isEnableTextSelection;

  final bool isUseQQPackage;

  final bool isUseTencentCloudChatPackage;

  final bool isUseTencentCloudChatPackageOldKeys;

  final List<CustomEmojiFaceData> customEmojiStickerList;

  const LinkTextMarkdown(
      {Key? key,
      required this.messageText,
      this.isUseQQPackage = false,
      this.isUseTencentCloudChatPackage = false,
      this.isUseTencentCloudChatPackageOldKeys = false,
      this.customEmojiStickerList = const [],
      this.isEnableTextSelection,
      this.onLinkTap,
      this.style})
      : super(key: key);

  /// 构建带超链接的 Markdown 文本展示。
  /// - 入参：[context] 当前上下文，用于处理点击跳转。
  /// - 返回：渲染 Markdown 文本的 Widget。
  /// - 业务约束：超链接样式跟随文本颜色，默认白色并带下划线。
  @override
  Widget timBuild(BuildContext context) {
    return MarkdownBody(
      data: mdTextCompiler(messageText,
          isUseTencentCloudChatPackage: isUseTencentCloudChatPackage,
          customEmojiStickerList: customEmojiStickerList),
      selectable: isEnableTextSelection ?? false,
      styleSheet: MarkdownStyleSheet.fromTheme(ThemeData(
              textTheme: TextTheme(
                  bodyMedium: style ?? const TextStyle(fontSize: 16.0))))
          .copyWith(
        a: LinkUtils.resolveLinkTextStyle(
          style ?? DefaultTextStyle.of(context).style,
        ),
      ),
      extensionSet: md.ExtensionSet.gitHubWeb,
      onTapLink: (
        String link,
        String? href,
        String title,
      ) {
        if (onLinkTap != null) {
          onLinkTap!(href ?? "");
        } else {
          LinkUtils.launchURL(context, href ?? "");
        }
      },
    );
  }
}

class LinkText extends TIMStatelessWidget {
  /// Callback for when link is tapped
  final void Function(String)? onLinkTap;

  /// message text
  final String messageText;

  /// text style for default words
  final TextStyle? style;

  final bool isUseQQPackage;

  final bool isUseTencentCloudChatPackage;

  final bool isUseTencentCloudChatPackageOldKeys;

  final List<CustomEmojiFaceData> customEmojiStickerList;

  final bool? isEnableTextSelection;

  const LinkText(
      {Key? key,
      required this.messageText,
      this.onLinkTap,
      this.isEnableTextSelection,
      this.style,
      this.isUseQQPackage = false,
      this.isUseTencentCloudChatPackage = false,
      this.isUseTencentCloudChatPackageOldKeys = false,
      this.customEmojiStickerList = const []})
      : super(key: key);

  /// 解析原始文本并标记超链接，返回用于 ExtendedText 的内容字符串。
  /// - 入参：[text] 原始消息文本；[context] 当前上下文用于打开链接。
  /// - 返回：插入特殊标记后的文本，用于 SpecialTextSpanBuilder 识别。
  /// - 业务约束：超链接样式跟随文本颜色，默认白色并带下划线。
  String _getContentSpan(String text, BuildContext context) {
    List<InlineSpan> _contentList = [];
    String contentData = PlatformUtils().isWeb ? '\u200B' : "";

    Iterable<RegExpMatch> matches = LinkUtils.urlReg.allMatches(text);

    int index = 0;
    for (RegExpMatch match in matches) {
      String c = text.substring(match.start, match.end);
      if (match.start == index) {
        index = match.end;
      }
      if (index < match.start) {
        String a = text.substring(index, match.start);
        index = match.end;
        contentData += a;
        _contentList.add(
          TextSpan(text: a),
        );
      }

      if (LinkUtils.urlReg.hasMatch(c)) {
        contentData += HttpText.flag + c + HttpText.flag;
        _contentList.add(TextSpan(
            text: c,
            style: LinkUtils.resolveLinkTextStyle(
              style ?? DefaultTextStyle.of(context).style,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                if (onLinkTap != null) {
                  onLinkTap!(text.substring(match.start, match.end));
                } else {
                  LinkUtils.launchURL(
                      context, text.substring(match.start, match.end));
                }
              }));
      } else {
        contentData += c;
        _contentList.add(
          TextSpan(text: c, style: style ?? const TextStyle(fontSize: 16.0)),
        );
      }
    }
    if (index < text.length) {
      String a = text.substring(index, text.length);
      contentData += a;
      _contentList.add(
        TextSpan(text: a, style: style ?? const TextStyle(fontSize: 16.0)),
      );
    }

    return contentData;
  }

  @override
  Widget timBuild(BuildContext context) {
    return ExtendedText(_getContentSpan(messageText, context), softWrap: true,
        onSpecialTextTap: (dynamic parameter) {
      if (parameter.toString().startsWith(HttpText.flag)) {
        if (onLinkTap != null) {
          onLinkTap!((parameter.toString()).replaceAll(HttpText.flag, ''));
        } else {
          LinkUtils.launchURL(
              context, (parameter.toString()).replaceAll(HttpText.flag, ''));
        }
      }
    },
        style: style ?? const TextStyle(fontSize: 16.0),
        specialTextSpanBuilder: DefaultSpecialTextSpanBuilder(
          isUseQQPackage: isUseQQPackage,
          isUseTencentCloudChatPackage: isUseTencentCloudChatPackage,
          isUseTencentCloudChatPackageOldKeys: isUseTencentCloudChatPackageOldKeys,
          customEmojiStickerList: customEmojiStickerList,
          showAtBackground: true,
        ));
  }
}
