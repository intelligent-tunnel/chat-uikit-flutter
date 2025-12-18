import 'dart:async';

import 'package:extended_text/extended_text.dart';
import 'package:flutter/material.dart';
import 'package:tencent_chat_i18n_tool/tencent_chat_i18n_tool.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_merger_elem.dart'
    if (dart.library.html) 'package:tencent_cloud_chat_sdk/web/compatible_models/v2_tim_merger_elem.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_message.dart'
    if (dart.library.html) 'package:tencent_cloud_chat_sdk/web/compatible_models/v2_tim_message.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_state.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/separate_models/tui_chat_separate_view_model.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/view_models/tui_chat_global_model.dart';
import 'package:tencent_cloud_chat_uikit/data_services/core/tim_uikit_wide_modal_operation_key.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/chat_bubble_style.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/screen_utils.dart';
import 'package:tencent_cloud_chat_uikit/ui/views/TIMUIKitChat/TIMUIKItMessageList/tim_uikit_chat_history_message_list_item.dart';
import 'package:tencent_cloud_chat_uikit/ui/widgets/merger_message_screen.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_callback.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_base.dart';
import 'package:tencent_cloud_chat_uikit/ui/widgets/wide_popup.dart';
import 'package:tencent_cloud_chat_uikit/theme/color.dart';
import 'package:tencent_cloud_chat_uikit/theme/tui_theme.dart';
import 'package:tencent_cloud_chat_uikit/ui/views/TIMUIKitChat/TIMUIKitTextField/special_text/DefaultSpecialTextSpanBuilder.dart';
import 'TIMUIKitMessageReaction/tim_uikit_message_reaction_show_panel.dart';

const BorderRadius _kSelfBubbleRadius = BorderRadius.all(Radius.circular(12));
const BorderRadius _kOtherBubbleRadius = BorderRadius.all(Radius.circular(12));

const Color _kDefaultSelfBubbleColor = Color(0xFFFCF0CA);
const Color _kDefaultOtherBubbleColor = Color(0xFFF8F8F8);

class TIMUIKitMergerElem extends StatefulWidget {
  final V2TimMergerElem mergerElem;
  final String messageID;
  final bool isSelf;
  final bool isShowJump;
  final VoidCallback? clearJump;
  final V2TimMessage message;
  final bool? isShowMessageReaction;
  final TUIChatSeparateViewModel model;
  final MessageItemBuilder? messageItemBuilder;

  const TIMUIKitMergerElem(
      {Key? key,
      required this.message,
      required this.model,
      required this.mergerElem,
      required this.isSelf,
      this.isShowMessageReaction,
      required this.messageID,
      required this.isShowJump,
      this.clearJump,
      this.messageItemBuilder})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => TIMUIKitMergerElemState();
}

class TIMUIKitMergerElemState extends TIMUIKitState<TIMUIKitMergerElem> {
  bool isShowJumpState = false;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  _showJumpColor() {
    int shineAmount = 6;
    setState(() {
      isShowJumpState = true;
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      if (widget.clearJump != null) {
        widget.clearJump!();
      }
    });
    Timer.periodic(const Duration(milliseconds: 300), (timer) {
      if (mounted) {
        setState(() {
          isShowJumpState = shineAmount.isOdd ? true : false;
        });
      }
      if (shineAmount == 0 || !mounted) {
        timer.cancel();
      }
      shineAmount--;
    });
  }

  _handleTap(BuildContext context, TUIChatSeparateViewModel model) async {
    try {
      if (widget.messageID != "") {
        final isDesktopScreen =
            TUIKitScreenUtils.getFormFactor(context) == DeviceType.Desktop;

        if (isDesktopScreen) {
          TUIKitWidePopup.showPopupWindow(
            operationKey: TUIKitWideModalOperationKey.mergerMessageList,
            context: context,
            width: MediaQuery.of(context).size.width * 0.7,
            title: TIM_t("聊天记录"),
            height: MediaQuery.of(context).size.height * 0.7,
            child: (onClose) => Scrollbar(
              controller: _scrollController,
              child: MergerMessageScreen(
                  messageItemBuilder: widget.messageItemBuilder,
                  model: model,
                  msgID: widget.messageID),
            ),
          );
        } else {
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MergerMessageScreen(
                    messageItemBuilder: widget.messageItemBuilder,
                    model: model,
                    msgID: widget.messageID),
              ));
        }
      }
    } catch (e) {
      onTIMCallback(TIMCallback(
          type: TIMCallbackType.INFO,
          infoRecommendText: TIM_t("无法定位到原消息"),
          infoCode: 6660401));
    }
  }

  List<String>? _getAbstractList() {
    final length = widget.mergerElem.abstractList!.length;
    if (length <= 4) {
      return widget.mergerElem.abstractList;
    }
    return widget.mergerElem.abstractList!.getRange(0, 4).toList();
  }

  @override
  Widget tuiBuild(BuildContext context, TUIKitBuildValue value) {
    final TUITheme theme = value.theme;
    if (widget.isShowJump) {
      Future.delayed(Duration.zero, () {
        _showJumpColor();
      });
    }
    final isDesktopScreen =
        TUIKitScreenUtils.getFormFactor(context) == DeviceType.Desktop;
    final BorderRadius resolvedBorderRadius =
        widget.isSelf ? _kSelfBubbleRadius : _kOtherBubbleRadius;
    final Color? themeBackground = widget.isSelf
        ? (theme.chatMessageItemFromSelfBgColor ??
            theme.lightPrimaryMaterialColor.shade50)
        : (theme.chatMessageItemFromOthersBgColor ??
            theme.weakBackgroundColor);

    // 兜底会话类型，优先使用控制器类型，缺省按消息体推断单聊/群聊。
    final ConvType conversationType = ChatBubbleStyle.resolveConversationType(
        conversationType: widget.model.conversationType,
        message: widget.message);

    // 单聊气泡统一灰色，其他场景沿用主题或默认配色。
    final Color resolvedBubbleColor = ChatBubbleStyle.resolveBubbleColor(
        conversationType: conversationType,
        backgroundColor: null,
        themeBackground: themeBackground,
        isFromSelf: widget.isSelf,
        selfFallbackColor: _kDefaultSelfBubbleColor,
        otherFallbackColor: _kDefaultOtherBubbleColor);
    return Container(
      constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width *
              (isDesktopScreen ? 0.3 : 0.6)),
      decoration: BoxDecoration(
        color: resolvedBubbleColor,
        borderRadius: resolvedBorderRadius,
        border: Border.all(
          color: isShowJumpState
              ? const Color.fromRGBO(245, 166, 35, 1)
              : (theme.weakDividerColor ?? CommonColor.weakDividerColor),
          width: 1,
        ),
      ),
      child: GestureDetector(
        onTap: () {
          _handleTap(context, widget.model);
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.mergerElem.title!,
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.left,
                      maxLines: 1,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                  )
                ],
              ),
              const SizedBox(
                height: 4,
              ),
              // const Divider(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: _getAbstractList()!
                    .map(
                      (e) => Row(
                        children: [
                          Expanded(
                            child: ExtendedText(
                              e,
                              textAlign: TextAlign.left,
                              softWrap: true,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                              style: TextStyle(
                                color: theme.weakTextColor,
                                fontSize: 12,
                              ),
                              specialTextSpanBuilder: DefaultSpecialTextSpanBuilder(
                                isUseQQPackage: true,
                                isUseTencentCloudChatPackage: true,
                                showAtBackground: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(
                height: 4,
              ),
              const Divider(),
              Text(
                TIM_t("聊天记录"),
                style: TextStyle(
                  color: theme.weakTextColor,
                  fontSize: 10,
                ),
              ),
              if (widget.isShowMessageReaction ?? true)
                TIMUIKitMessageReactionShowPanel(message: widget.message)
            ],
          ),
        ),
      ),
    );
  }
}
