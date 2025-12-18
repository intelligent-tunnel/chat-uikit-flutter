import 'package:flutter/material.dart';
import 'package:tencent_chat_i18n_tool/tencent_chat_i18n_tool.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_statelesswidget.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/platform.dart';

import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_base.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/logger.dart';

import 'package:tencent_cloud_chat_uikit/theme/color.dart';

class EmojiPanel extends TIMUIKitStatelessWidget {
  final void Function(int unicode) onTapEmoji;
  final void Function() onSubmitted;
  final void Function() delete;
  final bool showBottomContainer;

  EmojiPanel({
    Key? key,
    required this.onTapEmoji,
    required this.onSubmitted,
    required this.delete,
    this.showBottomContainer = true, // 可选参数，是否展示下方的底部导航栏
  }) : super(key: key);

  @override
  Widget tuiBuild(BuildContext context, TUIKitBuildValue value) {
    // ignore: avoid_print
    outputLogger.i(TIM_t(
        "暂未安装表情包插件，如需使用表情相关功能，请根据本文档安装：https://cloud.tencent.com/document/product/269/70746"));
    return SingleChildScrollView(
        child: Column(
      children: [
        Container(
          height: showBottomContainer ? 190 : 248,
          // color: theme.weakBackgroundColor,
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(TIM_t("暂无表情包")),
            ],
          ),
        ),
        showBottomContainer
            ? Row(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SingleChildScrollView(
                    child: Container(
                        // color: Colors.white,
                        margin: const EdgeInsets.only(right: 25),
                        // height: MediaQuery.of(context).padding.bottom,
                        child: ElevatedButton(
                            child: Text(TIM_t("发送")),
                            style: ElevatedButton.styleFrom(),
                            onPressed: () {
                              onSubmitted();
                            })),
                  ),
                ],
              )
            : Container()
      ],
    ));
  }
}

class EmojiItem extends TIMUIKitStatelessWidget {
  EmojiItem({Key? key, required this.name, required this.unicode})
      : super(key: key);
  /// 表情名称，供占位或调试使用。
  final String name;

  /// 表情对应的 Unicode 码点。
  final int unicode;

  /// Android 端放大的默认表情字号。
  static const double _kAndroidEmojiFontSize = 24;

  /// 其他端放大的默认表情字号。
  static const double _kDefaultEmojiFontSize = 30;

  // final String toUser;
  // final int type;
  // final Function close;
  @override
  Widget tuiBuild(BuildContext context, TUIKitBuildValue value) {
    return DefaultTextStyle(
      style: TextStyle(
        fontSize:
            (PlatformUtils().isAndroid) ? _kAndroidEmojiFontSize : _kDefaultEmojiFontSize,
        color: hexToColor("f9453d")
      ),
      child: Text(
        String.fromCharCode(unicode),
      ),
    );
  }
}
