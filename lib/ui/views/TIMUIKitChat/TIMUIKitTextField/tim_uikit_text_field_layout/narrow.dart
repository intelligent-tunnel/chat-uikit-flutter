// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:math';

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
import 'package:tencent_cloud_chat_uikit/theme/color.dart';
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
  VoidCallback? _controllerListener;

  bool showMore = false;
  bool showMoreButton = true;
  bool showSendSoundText = false;
  bool showEmojiPanel = false;
  bool showKeyboard = false;
  bool showInputScrollbar = false;
  Function? setKeyboardHeight;
  double? bottomPadding;

  @override
  void initState() {
    super.initState();
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

  void setSendButton() {
    final value = widget.textEditingController.text;
    if (isWebDevice() || isAndroidDevice()) {
      if (value.isEmpty && showMoreButton != true) {
        setState(() {
          showMoreButton = true;
        });
      } else if (value.isNotEmpty && showMoreButton == true) {
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

  Widget _getBottomContainer(TUITheme theme) {
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
              },
              addText: (int unicode) {
                final newText = String.fromCharCode(unicode);
                widget.addStickerToText(newText);
                setSendButton();
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
                  },
                  addText: (int unicode) {
                    final newText = String.fromCharCode(unicode);
                    widget.addStickerToText(newText);
                    setSendButton();
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
    _textScrollController.dispose();
    super.dispose();
  }

  double _getBottomHeight() {
    if (showKeyboard) {
      final currentKeyboardHeight = MediaQuery.of(context).viewInsets.bottom;
      double originHeight = settingModel.keyboardHeight;
      if (currentKeyboardHeight != 0) {
        if (currentKeyboardHeight >= originHeight) {
          originHeight = currentKeyboardHeight;
        }
        if (setKeyboardHeight != null) {
          setKeyboardHeight!(currentKeyboardHeight);
        }
      }
      final height = originHeight != 0 ? originHeight : currentKeyboardHeight;
      return height;
    } else if (showMore || showEmojiPanel) {
      final double panelHeight = showMore
          ? widget.model.chatConfig.mobileMorePanelHeight ?? 248.0
          : widget.model.chatConfig.mobileStickerPanelHeight ?? 248.0;
      return panelHeight + (bottomPadding ?? 0.0);
    } else if (widget.textEditingController.text.length >= 46 && showKeyboard == false) {
      return 25 + (bottomPadding ?? 0.0);
    } else {
      return bottomPadding ?? 0;
    }
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

  String getAbstractMessage(V2TimMessage message) {
    final String? customAbstractMessage =
        widget.model.abstractMessageBuilder != null ? widget.model.abstractMessageBuilder!(message) : null;
    return customAbstractMessage ?? MessageUtils.getAbstractMessageAsync(message, widget.model.groupMemberList ?? []);
  }

  _buildRepliedMessage(V2TimMessage? repliedMessage) {
    final haveRepliedMessage = repliedMessage != null;
    if (haveRepliedMessage) {
      final String text = "${MessageUtils.getDisplayName(repliedMessage)}:${getAbstractMessage(repliedMessage)}";
      return Container(
        color: widget.backgroundColor ?? hexToColor("f5f5f6"),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                text,
                softWrap: true,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: hexToColor("8f959e"), fontSize: 14),
              ),
            ),
            const SizedBox(
              width: 16,
            ),
            InkWell(
              onTap: () {
                widget.model.repliedMessage = null;
              },
              child: Icon(Icons.clear, color: hexToColor("8f959e"), size: 18),
            )
          ],
        ),
      );
    }
    return Container();
  }

  @override
  Widget tuiBuild(BuildContext context, TUIKitBuildValue value) {
    final theme = value.theme;

    setKeyboardHeight ??= OptimizeUtils.debounce((height) {
      settingModel.keyboardHeight = height;
    }, const Duration(seconds: 1));

    final debounceFunc = _debounce((value) {
      if (isWebDevice() || isAndroidDevice()) {
        if (value.isEmpty && showMoreButton != true) {
          setState(() {
            showMoreButton = true;
          });
        } else if (value.isNotEmpty && showMoreButton == true) {
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
      final isEmpty = value.isEmpty;
      if (isEmpty) {
        widget.handleSoftKeyBoardDelete();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_textScrollController.hasClients &&
              _textScrollController.position.pixels != _textScrollController.position.minScrollExtent) {
            _textScrollController.jumpTo(_textScrollController.position.minScrollExtent);
          }
        });
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
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
    }, const Duration(milliseconds: 80));

    final MediaQueryData data = MediaQuery.of(context);
    EdgeInsets padding = data.padding;
    if (bottomPadding == null || padding.bottom > bottomPadding!) {
      bottomPadding = padding.bottom;
    }

    return GestureDetector(
      onTap: () {},
      child: Column(
        children: [
          _buildRepliedMessage(widget.repliedMessage),
          Container(
            color: Colors.white,
            // padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
            child: Column(
              children: [
                Container(
                  constraints: const BoxConstraints(minHeight: 54),
                  margin: const EdgeInsets.symmetric(horizontal: 20).copyWith(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 18,
                      offset: Offset(0, 1),
                    )
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
                                      interactive: true,
                                      thickness: 4,
                                      radius: const Radius.circular(2),
                                      thumbColor: const Color(0xF8B8B8B8),
                                      trackColor: const Color(0xF8EAEAEA),
                                      trackBorderColor: Colors.transparent,
                                      padding: const EdgeInsets.only(top: 10, bottom: 4),
                                      child: KeyboardVisibility(
                                          child: ExtendedTextField(
                                              maxLines: 5,
                                              minLines: 1,
                                              focusNode: widget.focusNode,
                                              style: const TextStyle(fontSize: 14, color: Color(0xFF282731)),
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
                                                setState(() {
                                                  if (widget.textEditingController.text.isEmpty) {
                                                    showMoreButton = true;
                                                  }
                                                });
                                              },
                                              textAlignVertical: TextAlignVertical.center,
                                              decoration: InputDecoration(
                                                  border: InputBorder.none,
                                                  isDense: true,
                                                  contentPadding: const EdgeInsets.only(bottom: 6),
                                                  hintStyle: const TextStyle(color: Color(0xFFAEA4A3), fontSize: 14),
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
                      // const SizedBox(width: 12),
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
                      if ((isAndroidDevice() || isWebDevice()) && !showMoreButton)
                        SizedBox(
                          height: 36,
                          child: ElevatedButton(
                            onPressed: () {
                              widget.onSubmitted();
                              if (showKeyboard) {
                                widget.focusNode.requestFocus();
                              }
                              if (widget.textEditingController.text.isEmpty) {
                                setState(() {
                                  showMoreButton = true;
                                });
                              }
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
                ),
                AnimatedContainer(
                  duration: Duration(milliseconds: (showKeyboard && PlatformUtils().isAndroid) ? 200 : 340),
                  curve: Curves.fastOutSlowIn,
                  height: max(_getBottomHeight(), 0.0),
                  child: ListView(
                    physics: const NeverScrollableScrollPhysics(),
                    children: [_getBottomContainer(theme)],
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
