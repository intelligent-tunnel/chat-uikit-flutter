// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:math';

import 'package:extended_text/extended_text.dart';
import 'package:extended_text_field/extended_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:tencent_chat_i18n_tool/tencent_chat_i18n_tool.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_message.dart'
    if (dart.library.html) 'package:tencent_cloud_chat_sdk/web/compatible_models/v2_tim_message.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_base.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_state.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/separate_models/tui_chat_separate_view_model.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/view_models/tui_chat_global_model.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/view_models/tui_setting_model.dart';
import 'package:tencent_cloud_chat_uikit/data_services/services_locatar.dart';
import 'package:tencent_cloud_chat_uikit/tencent_cloud_chat_uikit.dart';
import 'package:tencent_cloud_chat_uikit/theme/tui_theme.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/message.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/optimize_utils.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/permission.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/platform.dart';
import 'package:tencent_cloud_chat_uikit/ui/views/TIMUIKitChat/TIMUIKitTextField/special_text/DefaultSpecialTextSpanBuilder.dart';
import 'package:tencent_cloud_chat_uikit/ui/views/TIMUIKitChat/TIMUIKitTextField/special_text/emoji_text.dart';
import 'package:tencent_cloud_chat_uikit/ui/views/TIMUIKitChat/TIMUIKitTextField/tim_uikit_send_sound_message.dart';
import 'package:tencent_keyboard_visibility/tencent_keyboard_visibility.dart';

GlobalKey<_TIMUIKitTextFieldLayoutNarrowState> narrowTextFieldKey = GlobalKey();

/// 窄屏输入框正文字号，提升文字与表情的可读性。
const double _kNarrowInputFontSize = 16;

/// 窄屏输入框提示文字字号，保持与正文相近的观感。
const double _kNarrowInputHintFontSize = 16;

class TIMUIKitTextFieldLayoutNarrow extends StatefulWidget {
  /// sticker panel customization
  final CustomStickerPanel? customStickerPanel;

  final VoidCallback onEmojiSubmitted;
  final Function(int, String) onCustomEmojiFaceSubmitted;
  final Function(String, bool) handleSendEditStatus;
  final VoidCallback backSpaceText;
  final ValueChanged<String> addStickerToText;

  final ValueChanged<String> handleAtText;

  /// Whether to use the default emoji
  final bool isUseDefaultEmoji;

  final bool isUseTencentCloudChatPackageOldKeys;

  final TUIChatSeparateViewModel model;

  /// background color
  final Color? backgroundColor;

  /// control input field behavior
  final TIMUIKitInputTextFieldController? controller;

  /// config for more panel
  final MorePanelConfig? morePanelConfig;

  final String languageType;

  final TextEditingController textEditingController;

  /// conversation id
  final String conversationID;

  /// conversation type
  final ConvType conversationType;

  final FocusNode focusNode;

  /// show more panel
  final bool showMorePanel;

  /// hint text for textField widget
  final String? hintText;

  final int? currentCursor;

  final ValueChanged<int?> setCurrentCursor;

  final VoidCallback onCursorChange;

  /// show send audio icon
  final bool showSendAudio;

  final VoidCallback handleSoftKeyBoardDelete;

  /// on text changed
  final void Function(String)? onChanged;

  final V2TimMessage? repliedMessage;

  final void Function(String)? onDeleteText;

  /// show send emoji icon
  final bool showSendEmoji;

  final VoidCallback onSubmitted;

  final VoidCallback goDownBottom;

  final List<CustomEmojiFaceData> customEmojiStickerList;

  final List<CustomStickerPackage> stickerPackageList;

  const TIMUIKitTextFieldLayoutNarrow(
      {Key? key,
      this.customStickerPanel,
      required this.onEmojiSubmitted,
      required this.onCustomEmojiFaceSubmitted,
      required this.backSpaceText,
      required this.addStickerToText,
      required this.isUseDefaultEmoji,
      this.isUseTencentCloudChatPackageOldKeys = false,
      required this.languageType,
      required this.textEditingController,
      this.morePanelConfig,
      required this.conversationID,
      required this.conversationType,
      required this.focusNode,
      this.currentCursor,
      required this.setCurrentCursor,
      required this.onCursorChange,
      required this.model,
      this.backgroundColor,
      this.onChanged,
      this.onDeleteText,
      required this.handleSendEditStatus,
      required this.handleAtText,
      required this.handleSoftKeyBoardDelete,
      this.repliedMessage,
      required this.onSubmitted,
      required this.goDownBottom,
      required this.showSendAudio,
      required this.showSendEmoji,
      required this.showMorePanel,
      this.hintText,
      required this.customEmojiStickerList,
      this.controller,
      required this.stickerPackageList})
      : super(key: key);

  @override
  State<TIMUIKitTextFieldLayoutNarrow> createState() => _TIMUIKitTextFieldLayoutNarrowState();
}

class _TIMUIKitTextFieldLayoutNarrowState extends TIMUIKitState<TIMUIKitTextFieldLayoutNarrow> {
  final TUISettingModel settingModel = serviceLocator<TUISettingModel>();
  final ScrollController _textScrollController = ScrollController();
  /// 输入框状态 Key，用于表情插入后滚动光标到可见区域。
  final GlobalKey<ExtendedTextFieldState> _textFieldKey =
      GlobalKey<ExtendedTextFieldState>();
  VoidCallback? _controllerListener;

  bool showMore = false;
  bool showMoreButton = true;
  bool showSendSoundText = false;
  bool showEmojiPanel = false;
  bool showKeyboard = false;
  bool showInputScrollbar = false;
  Function? setKeyboardHeight;
  double? bottomPadding;
  final GlobalKey _inputPanelKey = GlobalKey();
  final GlobalKey _replyPanelKey = GlobalKey();
  double _inputPanelHeight = 0;
  double _replyPanelHeight = 0;

  @override
  void initState() {
    super.initState();
    widget.textEditingController.addListener(_handleTextEditingValueChanged);
    if (widget.controller != null) {
      _controllerListener = () {
        final actionType = widget.controller?.actionType;
        if (actionType == ActionType.hideAllPanel) {
          hideAllPanel();
        }
      };
      widget.controller?.addListener(_controllerListener!);
    }
  }

  /// 监听输入框文本变化，同步滚动条与发送按钮状态。
  /// 入参：无。
  /// 返回：无。
  /// 业务约束：文本为空时隐藏滚动条，Android/Web 下依赖文本状态切换发送按钮显隐。
  void _handleTextEditingValueChanged() {
    if (!mounted) {
      return;
    }
    if (widget.textEditingController.text.isEmpty && showInputScrollbar) {
      _updateInputScrollbar(forceHide: true);
    }
    setSendButton();
  }

  @override
  void didUpdateWidget(covariant TIMUIKitTextFieldLayoutNarrow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.textEditingController != widget.textEditingController) {
      oldWidget.textEditingController.removeListener(_handleTextEditingValueChanged);
      widget.textEditingController.addListener(_handleTextEditingValueChanged);
    }
    if (widget.repliedMessage != oldWidget.repliedMessage && widget.repliedMessage != null) {
      _collapseBottomPanelsForReply();
    }
  }

  /// 计算当前输入框是否包含可发送的有效文本。
  /// 入参：rawText 为输入框原始内容。
  /// 返回：去除首尾空格后非空即返回 true。
  /// 业务约束：仅用于窄屏 Android/Web 的发送按钮显隐判定，空白字符不触发展示。
  bool _hasSendableText(String rawText) {
    final String trimmedText = rawText.trim();
    return trimmedText.isNotEmpty;
  }

  /// 根据输入框内容切换“更多”与“发送”按钮的展示。
  /// 入参：无，直接读取 textEditingController。
  /// 返回：无。
  /// 业务约束：Android/Web 窄屏下有有效文本才展示发送按钮，空文本时回退到更多按钮。
  void setSendButton() {
    final String value = widget.textEditingController.text;
    final bool hasSendableText = _hasSendableText(value);
    if (isWebDevice() || isAndroidDevice()) {
      if (!hasSendableText && showMoreButton != true) {
        setState(() {
          showMoreButton = true;
        });
      } else if (hasSendableText && showMoreButton == true) {
        setState(() {
          showMoreButton = false;
        });
      }
    }
  }

  hideAllPanel() {
    widget.focusNode.unfocus();
    widget.currentCursor == null;
    if (showKeyboard != false || showMore != false || showEmojiPanel != false) {
      setState(() {
        showKeyboard = false;
        showMore = false;
        showEmojiPanel = false;
      });
    }
  }

  void _collapseBottomPanelsForReply() {
    if (!showMore && !showEmojiPanel && !showSendSoundText) {
      return;
    }
    setState(() {
      showMore = false;
      showEmojiPanel = false;
      showSendSoundText = false;
    });
    widget.focusNode.requestFocus();
  }

  /// 构建底部的表情/更多面板容器。
  /// 入参：theme 为主题色，hasSendableText 表示输入框是否有有效文本。
  /// 返回：当前应展示的底部面板组件。
  /// 业务约束：表情面板需联动发送按钮显隐，避免无内容时误触发送。
  Widget _getBottomContainer(TUITheme theme, bool hasSendableText) {
    if (showEmojiPanel) {
      return widget.customStickerPanel != null
          ? widget.customStickerPanel!(
              height: widget.model.chatConfig.mobileStickerPanelHeight,
              sendTextMessage: () {
                widget.onEmojiSubmitted();
                setSendButton();
              },
              sendFaceMessage: widget.onCustomEmojiFaceSubmitted,
              deleteText: () {
                widget.backSpaceText();
                setSendButton();
                _ensureCursorVisible();
              },
              addText: (int unicode) {
                final newText = String.fromCharCode(unicode);
                widget.addStickerToText(newText);
                setSendButton();
                _ensureCursorVisible();
                // handleSetDraftText();
              },
              addCustomEmojiText: ((String singleEmojiName) {
                String? emojiName = singleEmojiName.split('.png')[0];
                String compatibleEmojiName = emojiName;
                if (widget.isUseTencentCloudChatPackageOldKeys) {
                  compatibleEmojiName = EmojiUtil.getCompatibleEmojiName(emojiName);
                }

                String newText = '[$compatibleEmojiName]';
                widget.addStickerToText(newText);
                setSendButton();
                _ensureCursorVisible();
              }),
              defaultCustomEmojiStickerList: widget.isUseDefaultEmoji ? TUIKitStickerConstData.emojiList : [])
          : Padding(
              padding: const EdgeInsets.only(top: 12),
              child: StickerPanel(
                  isWideScreen: false,
                  sendTextMsg: () {
                    widget.onEmojiSubmitted();
                    setSendButton();
                  },
                  sendFaceMsg: widget.onCustomEmojiFaceSubmitted,
                  deleteText: () {
                    widget.backSpaceText();
                    setSendButton();
                    _ensureCursorVisible();
                  },
                  addText: (int unicode) {
                    final newText = String.fromCharCode(unicode);
                    widget.addStickerToText(newText);
                    setSendButton();
                    _ensureCursorVisible();
                    // handleSetDraftText();
                  },
                  addCustomEmojiText: ((String singleEmojiName) {
                    String? emojiName = singleEmojiName.split('.png')[0];
                    String compatibleEmojiName = emojiName;
                    if (widget.isUseTencentCloudChatPackageOldKeys) {
                      compatibleEmojiName = EmojiUtil.getCompatibleEmojiName(emojiName);
                    }

                    String newText = '[$compatibleEmojiName]';
                    widget.addStickerToText(newText);
                    setSendButton();
                    _ensureCursorVisible();
                  }),
                  customStickerPackageList: widget.stickerPackageList,
                  lightPrimaryColor: theme.lightPrimaryColor),
            );
    }

    if (showMore) {
      return MorePanel(
          morePanelConfig: widget.morePanelConfig,
          conversationID: widget.conversationID,
          conversationType: widget.conversationType,
          height: widget.model.chatConfig.mobileMorePanelHeight);
    }

    return const SizedBox(height: 0);
  }

  @override
  void dispose() {
    if (widget.controller != null && _controllerListener != null) {
      widget.controller?.removeListener(_controllerListener!);
    }
    widget.textEditingController.removeListener(_handleTextEditingValueChanged);
    _textScrollController.dispose();
    super.dispose();
  }

  /// 计算输入区域底部留白。
  /// 入参：无。
  /// 返回：需要追加的底部高度，保证键盘/面板/引用卡片切换时引用条不会贴底。
  /// 业务约束：面板展开时按面板高度处理，键盘收起时至少保留36并叠加安全区与引用卡片间距。
  double _getBottomHeight() {
    // 面板展开时，仍按面板高度处理
    if (showMore || showEmojiPanel) {
      final double panelHeight = showMore
          ? widget.model.chatConfig.mobileMorePanelHeight ?? 248.0
          : widget.model.chatConfig.mobileStickerPanelHeight ?? 248.0;
      return panelHeight + (bottomPadding ?? 0.0);
    }

    // 键盘展开/收起的固定高度策略：
    // 有键盘：保留 24 的基础间距，避免输入条贴边
    // 无键盘：至少 36，并叠加底部安全区与引用留白抬高回复卡片
    final double physicalSafeBottom = MediaQuery.of(context).viewPadding.bottom;
    // 回复引用存在时需额外抬高底部间距
    final bool hasReplyCard =
        !showSendSoundText && widget.repliedMessage != null;
    // 引用条与底部手势区的额外安全间距
    final double replyExtraPadding = hasReplyCard ? 16.0 : 0.0;

    if (!showKeyboard) {
      return max(physicalSafeBottom + replyExtraPadding, 36.0);
    }
    return 24.0;
  }

  _openMore() {
    if (!showMore) {
      widget.focusNode.unfocus();
      widget.setCurrentCursor(null);
    }
    setState(() {
      showKeyboard = false;
      showEmojiPanel = false;
      showSendSoundText = false;
      showMore = !showMore;
    });
  }

  _openEmojiPanel() {
    widget.onCursorChange();
    showKeyboard = showEmojiPanel;
    if (showEmojiPanel) {
      widget.focusNode.requestFocus();
    } else {
      widget.focusNode.unfocus();
    }

    setState(() {
      showMore = false;
      showSendSoundText = false;
      showEmojiPanel = !showEmojiPanel;
    });
  }

  _debounce(
    Function(String text) fun, [
    Duration delay = const Duration(milliseconds: 30),
  ]) {
    Timer? timer;
    return (String text) {
      if (timer != null) {
        timer?.cancel();
      }

      timer = Timer(delay, () {
        fun(text);
      });
    };
  }

  void _updateInputScrollbar({bool forceHide = false}) {
    if (!mounted) {
      return;
    }
    if (forceHide) {
      if (_textScrollController.hasClients &&
          _textScrollController.position.pixels !=
              _textScrollController.position.minScrollExtent) {
        _textScrollController.jumpTo(
          _textScrollController.position.minScrollExtent,
        );
      }
      if (showInputScrollbar) {
        setState(() {
          showInputScrollbar = false;
        });
      }
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (!_textScrollController.hasClients) {
        if (showInputScrollbar) {
          setState(() {
            showInputScrollbar = false;
          });
        }
        return;
      }
      final bool needScrollbar = _textScrollController.position.maxScrollExtent > 0;
      if (showInputScrollbar != needScrollbar) {
        setState(() {
          showInputScrollbar = needScrollbar;
        });
      }
    });
  }

  /// 触发表情插入后的光标滚动，确保输入区域可见。
  /// 入参：无。
  /// 返回：void。
  /// 业务约束：需等待下一帧布局完成，selection 必须有效且不越界。
  void _ensureCursorVisible() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final ExtendedTextFieldState? textFieldState = _textFieldKey.currentState;
      if (textFieldState == null) {
        return;
      }
      final TextSelection selection = widget.textEditingController.selection;
      if (!selection.isValid) {
        return;
      }
      final int offset = selection.extentOffset;
      if (offset < 0 || offset > widget.textEditingController.text.length) {
        return;
      }
      textFieldState.bringIntoView(TextPosition(offset: offset));
    });
  }

  String getAbstractMessage(V2TimMessage message) {
    final String? customAbstractMessage =
        widget.model.abstractMessageBuilder != null ? widget.model.abstractMessageBuilder!(message) : null;
    return customAbstractMessage ?? MessageUtils.getAbstractMessageAsync(message, widget.model.groupMemberList ?? []);
  }

  void _updatePanelMetrics(bool hasReplyCard) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final BuildContext? replyContext = _replyPanelKey.currentContext;
      final double? measuredReplyHeight = hasReplyCard ? replyContext?.size?.height : 0;

      double updatedReplyHeight = _replyPanelHeight;
      bool needUpdate = false;

      if (hasReplyCard) {
        if (measuredReplyHeight != null && (measuredReplyHeight - _replyPanelHeight).abs() > 0.5) {
          updatedReplyHeight = measuredReplyHeight;
          needUpdate = true;
        }
      } else if (_replyPanelHeight != 0) {
        updatedReplyHeight = 0;
        needUpdate = true;
      }

      if (needUpdate) {
        setState(() {
          _replyPanelHeight = updatedReplyHeight;
        });
      }
    });
  }

  Widget? _buildRepliedMessage(V2TimMessage? repliedMessage, {required bool isDarkMode}) {
    if (repliedMessage == null) {
      return null;
    }
    final String text = "${MessageUtils.getDisplayName(repliedMessage)}:${getAbstractMessage(repliedMessage)}";
    final stickerConfig = widget.model.chatConfig.stickerPanelConfig;
    final DefaultSpecialTextSpanBuilder spanBuilder = DefaultSpecialTextSpanBuilder(
      isUseQQPackage: stickerConfig?.useQQStickerPackage ?? true,
      isUseTencentCloudChatPackage: stickerConfig?.useTencentCloudChatStickerPackage ?? true,
      isUseTencentCloudChatPackageOldKeys:
          stickerConfig?.useTencentCloudChatStickerPackageOldKeys ?? false,
      customEmojiStickerList: widget.customEmojiStickerList,
      showAtBackground: true,
      checkHttpLink: true,
    );

    final Color replyCardColor = widget.backgroundColor ??
        (isDarkMode ? const Color(0xFF2E2F33) : Color(0xFFF8F8F8));
    final Color replyTextColor = isDarkMode ? Colors.white.withOpacity(0.85) : const Color(0xFF3D3E40);
    final Color closeIconColor = isDarkMode ? Colors.white.withOpacity(0.6) : const Color(0xFF8F959E);
    final Color replyShadowColor = isDarkMode ? Colors.black.withOpacity(0.45) : const Color(0x1A000000);

    final Widget replyCard = Container(
      key: _replyPanelKey,
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16).copyWith(top: 34),
      decoration: BoxDecoration(
        color: replyCardColor,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: ExtendedText(
              text,
              softWrap: true,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: replyTextColor, fontSize: 14,  fontWeight: FontWeight.w500),
              specialTextSpanBuilder: spanBuilder,
            ),
          ),
          const SizedBox(width: 12),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                setState(() {
                  widget.model.repliedMessage = null;
                });
              },
              child: SizedBox(
                width: 32,
                height: 32,
                child: Center(
                  child: Icon(
                    Icons.close,
                    size: 18,
                    color: closeIconColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    return replyCard;
  }

  @override
  Widget tuiBuild(BuildContext context, TUIKitBuildValue value) {
    final theme = value.theme;

    setKeyboardHeight ??= OptimizeUtils.debounce((height) {
      settingModel.keyboardHeight = height;
    }, const Duration(seconds: 1));

    final debounceFunc = _debounce((value) {
      final bool hasSendableText = _hasSendableText(value);
      if (isWebDevice() || isAndroidDevice()) {
        if (!hasSendableText && showMoreButton != true) {
          setState(() {
            showMoreButton = true;
          });
        } else if (hasSendableText && showMoreButton == true) {
          setState(() {
            showMoreButton = false;
          });
        }
      }
      if (widget.onChanged != null) {
        widget.onChanged!(value);
      }
      widget.handleAtText(value);
      widget.handleSendEditStatus(value, true);
      final bool isEmpty = value.isEmpty;
      if (isEmpty) {
        widget.handleSoftKeyBoardDelete();
        _updateInputScrollbar(forceHide: true);
      } else {
        _updateInputScrollbar();
      }
    }, const Duration(milliseconds: 80));

    final MediaQueryData data = MediaQuery.of(context);
    EdgeInsets padding = data.padding;
    if (bottomPadding == null || padding.bottom > bottomPadding!) {
      bottomPadding = padding.bottom;
    }

    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bool shouldShowReplyCard =
        !showSendSoundText && widget.repliedMessage != null;
    final Widget? repliedMessageCard = shouldShowReplyCard
        ? _buildRepliedMessage(widget.repliedMessage, isDarkMode: isDarkMode)
        : null;
    final bool hasReplyCard = repliedMessageCard != null;

    _updatePanelMetrics(hasReplyCard);
    // 当前输入框是否存在可发送内容，用于控制发送按钮与表情面板行为。
    final bool hasSendableText = _hasSendableText(widget.textEditingController.text);

    final Widget inputPanel = Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      constraints: const BoxConstraints(minHeight: 40),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(color: Color(0xFFF2F2F2), borderRadius: BorderRadius.circular(28), boxShadow: const [
        // BoxShadow(
        //   color: Color(0x1A000000),
        //   blurRadius: 18,
        //   offset: Offset(0, 1),
        // )
      ]),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (PlatformUtils().isMobile && widget.showSendAudio)
            InkWell(
              onTap: () async {
                showKeyboard = showSendSoundText;
                if (showSendSoundText) {
                  widget.focusNode.requestFocus();
                }
                if (await Permissions.checkPermission(
                  context,
                  Permission.microphone.value,
                  theme,
                )) {
                  setState(() {
                    showEmojiPanel = false;
                    showMore = false;
                    showSendSoundText = !showSendSoundText;
                  });
                }
              },
              child: SizedBox(
                width: 32,
                height: 32,
                child: Center(
                  child: showSendSoundText
                      ? SvgPicture.asset(
                          'assets/images/chat/keyboard.svg',
                          width: 24,
                          height: 24,
                        )
                      : SvgPicture.asset(
                          'assets/images/chat/voice.svg',
                          width: 24,
                          height: 24,
                        ),
                ),
              ),
            ),
          const SizedBox(width: 4),
          Expanded(
            child: showSendSoundText
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 0),
                    child: SendSoundMessage(
                        onDownBottom: widget.goDownBottom,
                        conversationID: widget.conversationID,
                        conversationType: widget.conversationType),
                  )
                : Stack(children: [
                    Center(
                      child: RawScrollbar(
                          controller: _textScrollController,
                          thumbVisibility: showInputScrollbar,
                          trackVisibility: showInputScrollbar,
                          fadeDuration: Duration.zero,
                          timeToFade: Duration.zero,
                          interactive: true,
                          thickness: 4,
                          radius: const Radius.circular(2),
                          thumbColor: const Color(0xF8B8B8B8),
                          trackColor: const Color(0xF8EAEAEA),
                          trackBorderColor: Colors.transparent,
                          padding: const EdgeInsets.only(top: 10, bottom: 4),
                          child: KeyboardVisibility(
                              child: ExtendedTextField(
                                  key: _textFieldKey,
                                  maxLines: 5,
                                  minLines: 1,
                                  focusNode: widget.focusNode,
                                  style: const TextStyle(
                                      fontSize: _kNarrowInputFontSize,
                                      color: Color(0xFF282731)),
                                  onChanged: debounceFunc,
                                  onTap: () {
                                    showKeyboard = true;
                                    widget.goDownBottom();
                                    setState(() {
                                      showEmojiPanel = false;
                                      showMore = false;
                                    });
                                  },
                                  keyboardType: TextInputType.multiline,
                                  textInputAction: PlatformUtils().isAndroid
                                      ? TextInputAction.newline
                                      : TextInputAction.send,
                                  onEditingComplete: () {
                                    widget.onSubmitted();
                                    if (showKeyboard) {
                                      widget.focusNode.requestFocus();
                                    }
                                    final bool currentHasSendableText =
                                        _hasSendableText(widget.textEditingController.text);
                                    setState(() {
                                      if (!currentHasSendableText) {
                                        showMoreButton = true;
                                      }
                                    });
                                    _updateInputScrollbar(forceHide: true);
                                  },
                                  textAlignVertical: TextAlignVertical.center,
                                  decoration: InputDecoration(
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: const EdgeInsets.only(bottom: 6),
                                      hintStyle: const TextStyle(
                                          color: Color(0xFFAEA4A3),
                                          fontSize: _kNarrowInputHintFontSize),
                                      hintText: widget.hintText ?? ''),
                                  controller: widget.textEditingController,
                                  scrollController: _textScrollController,
                                  specialTextSpanBuilder: PlatformUtils().isWeb
                                      ? null
                                      : DefaultSpecialTextSpanBuilder(
                                          isUseQQPackage: widget.model.chatConfig.stickerPanelConfig
                                                  ?.useQQStickerPackage ??
                                              true,
                                          isUseTencentCloudChatPackage: widget.model.chatConfig
                                                  .stickerPanelConfig?.useTencentCloudChatStickerPackage ??
                                              true,
                                          isUseTencentCloudChatPackageOldKeys: widget
                                                  .model
                                                  .chatConfig
                                                  .stickerPanelConfig
                                                  ?.useTencentCloudChatStickerPackageOldKeys ??
                                              false,
                                          customEmojiStickerList: widget.customEmojiStickerList,
                                          showAtBackground: true,
                                          checkHttpLink: false,
                                        )),
                          onChanged: (bool visibility) {
                            if (showKeyboard != visibility) {
                              setState(() {
                                showKeyboard = visibility;
                              });
                            }
                          })),
                    ),
                    RawKeyboardListener(
                      autofocus: true,
                      focusNode: FocusNode(),
                      onKey: (key) {
                        if (key is RawKeyDownEvent && key.logicalKey == LogicalKeyboardKey.backspace) {
                          if (widget.onDeleteText != null) {
                            widget.onDeleteText!(widget.textEditingController.text);
                          }
                        }
                      },
                      child: Container(),
                    ),
                  ]),
          ),
          const SizedBox(width: 0),
          if (widget.showSendEmoji)
            InkWell(
              onTap: () {
                _openEmojiPanel();
                widget.goDownBottom();
              },
              child: SizedBox(
                width: 32,
                height: 32,
                child: Center(
                  child: showEmojiPanel
                      ? SvgPicture.asset(
                          'assets/images/chat/keyboard.svg',
                          width: 24,
                          height: 24,
                        )
                      : SvgPicture.asset(
                          'assets/images/chat/emoji.svg',
                          width: 24,
                          height: 24,
                        ),
                ),
              ),
            ),
          if (widget.showMorePanel && showMoreButton)
            InkWell(
              onTap: () {
                _openMore();
                widget.goDownBottom();
              },
              child: SizedBox(
                width: 32,
                height: 32,
                child: Center(
                  child: SvgPicture.asset(
                    'assets/images/chat/smile.svg',
                    width: 24,
                    height: 24,
                  ),
                ),
              ),
            ),
          if ((isAndroidDevice() || isWebDevice()) && !showMoreButton && hasSendableText)
            SizedBox(
              height: 36,
              child: ElevatedButton(
                onPressed: () {
                  widget.onSubmitted();
                  if (showKeyboard) {
                    widget.focusNode.requestFocus();
                  }
                  final bool currentHasSendableText =
                      _hasSendableText(widget.textEditingController.text);
                  if (!currentHasSendableText) {
                    setState(() {
                      showMoreButton = true;
                    });
                  }
                  _updateInputScrollbar(forceHide: true);
                },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                child: Text(TIM_t("发送")),
              ),
            ),
        ],
      ),
    );

    const double replyOverlapOffset = 40;
    // 如果回复容器高度是固定的，可直接使用固定高度来计算留白
    const double replyCardFixedHeight = 68.0;
    final double replyBottomPadding = hasReplyCard
        ? max((replyCardFixedHeight - replyOverlapOffset), 0)
        : 0;

    final Widget layeredInput = Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        if (hasReplyCard)
          Positioned(
            left: 20,
            right: 20,
            bottom: -10,
            child: repliedMessageCard,
          ),
        Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: EdgeInsets.only(bottom: replyBottomPadding),
            child: inputPanel,
          ),
        ),
      ],
    );

    return GestureDetector(
      onTap: () {},
      child: Column(
        children: [
          Container(
            color: Colors.white,
            // padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
            child: Column(
              children: [
                layeredInput,
                 // SizedBox(height:36),
                AnimatedContainer(
                  duration: Duration(milliseconds: (showKeyboard && PlatformUtils().isAndroid) ? 200 : 340),
                  curve: Curves.fastOutSlowIn,
                  height: max(_getBottomHeight(), 0.0),
                  child: ListView(
                    physics: const NeverScrollableScrollPhysics(),
                    children: [_getBottomContainer(theme, hasSendableText)],
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
