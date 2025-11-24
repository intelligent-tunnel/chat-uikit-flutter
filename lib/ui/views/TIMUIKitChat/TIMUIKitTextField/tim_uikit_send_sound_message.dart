// ignore_for_file:  avoid_print, unused_import

import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:tencent_chat_i18n_tool/tencent_chat_i18n_tool.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_state.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/separate_models/tui_chat_separate_view_model.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/view_models/tui_chat_global_model.dart';
import 'package:tencent_cloud_chat_uikit/data_services/services_locatar.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/message.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/permission.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/sound_record.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_ui_kit_base.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/logger.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_callback.dart';
import 'package:tencent_cloud_chat_uikit/theme/tui_theme.dart';

class SendSoundMessage extends StatefulWidget {
  /// conversation ID
  final String conversationID;

  /// control the list to bottom
  final VoidCallback onDownBottom;

  /// the conversation type
  final ConvType conversationType;

  const SendSoundMessage(
      {required this.conversationID,
      required this.conversationType,
      Key? key,
      required this.onDownBottom})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _SendSoundMessageState();
}

class _SendSoundMessageState extends TIMUIKitState<SendSoundMessage> {
  final TUIChatGlobalModel model = serviceLocator<TUIChatGlobalModel>();
  String soundTipsText = "";
  bool isRecording = false;
  bool isInit = false;
  bool isCancelSend = false;
  bool isInCancelArea = false;
  DateTime startTime = DateTime.now();
  Duration _recordDuration = Duration.zero;
  Timer? _maxDurationTimer;
  Timer? _elapsedTimer;
  static const Duration _maxRecordDuration = Duration(seconds: 60);
  List<StreamSubscription<Object>> subscriptions = [];

  OverlayEntry? overlayEntry;
  String voiceIcon = "images/voice_volume_1.png";
  double volume = 0.1;

  buildOverLayView(BuildContext context) {
    if (overlayEntry == null) {
      overlayEntry = OverlayEntry(builder: (content) {
        return Positioned(
          top: 0,
          left: 0,
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: Material(
            color: Colors.transparent,
            type: MaterialType.canvas,
            child: Center(
                child: Container(
                  width: 172,
                  height: 149,
                  decoration: const BoxDecoration(
                    color: Color(0x9B282731),
                    borderRadius: BorderRadius.all(Radius.circular(20.0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      const SizedBox(
                        height: 6,
                      ),
                      Padding(padding: const EdgeInsets.only(left: 12) ,child:
                      Text(
                        _formatDuration(_recordDuration),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),),
                      const SizedBox(
                        height: 9,
                      ),
                      SizedBox(
                        width: 58,
                        height: 58,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Image.asset(
                              'assets/images/chat/microphone.png',
                              width: 58,
                              height: 58,
                              fit: BoxFit.cover,
                            ),
                            Positioned(
                              bottom: 18,
                              child: _MicWaveBar(level: volume),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        soundTipsText,
                        style: const TextStyle(
                          fontStyle: FontStyle.normal,
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      )
                    ],
                  ),
                ),
              ),
          ),
        );
      });
      Overlay.of(context).insert(overlayEntry!);
    }
  }

  onLongPressStart(_) {
    if (isInit) {
      setState(() {
        isInCancelArea = false;
        soundTipsText = _getRecordingTip(_maxRecordDuration.inSeconds);
      });
      startTime = DateTime.now();
      isCancelSend = false;
      _recordDuration = Duration.zero;
      _elapsedTimer?.cancel();
      _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted || !isRecording) return;
        final now = DateTime.now();
        final elapsed = now.difference(startTime);
        final int secondsLeft =
            max(0, _maxRecordDuration.inSeconds - elapsed.inSeconds);
        String? nextTips;
        if (!isInCancelArea) {
          nextTips = _getRecordingTip(secondsLeft);
        }
        setState(() {
          _recordDuration = elapsed;
          if (nextTips != null && soundTipsText != nextTips) {
            soundTipsText = nextTips;
          }
        });
        if (overlayEntry != null) {
          overlayEntry!.markNeedsBuild();
        }
      });
      SoundPlayer.startRecord();
      _maxDurationTimer?.cancel();
      _maxDurationTimer = Timer(_maxRecordDuration, () {
        if (!mounted || !isRecording) {
          return;
        }
        if (overlayEntry != null) {
          overlayEntry!.remove();
          overlayEntry = null;
        }
        isCancelSend = false;
        onTIMCallback(TIMCallback(
            type: TIMCallbackType.INFO,
            infoRecommendText: TIM_t("已达到录音时长上限"),
            infoCode: 6660405));
        stop();
      });
      buildOverLayView(context);
    }
  }

  onLongPressUpdate(e) {
    double height = MediaQuery.of(context).size.height * 0.5 - 240;
    double dy = e.localPosition.dy;

    final bool shouldCancel = dy.abs() > height;
    if (shouldCancel) {
      if (mounted && (!isInCancelArea || soundTipsText != TIM_t("松开取消"))) {
        setState(() {
          isInCancelArea = true;
          soundTipsText = TIM_t("松开取消");
        });
      }
    } else {
      final int secondsLeft = max(
        0,
        _maxRecordDuration.inSeconds -
            DateTime.now().difference(startTime).inSeconds,
      );
      final String nextTips = _getRecordingTip(secondsLeft);
      if (mounted && isInCancelArea) {
        setState(() {
          isInCancelArea = false;
          soundTipsText = nextTips;
        });
      } else if (mounted && soundTipsText != nextTips) {
        setState(() {
          soundTipsText = nextTips;
        });
      }
    }
  }

  onLongPressEnd(e) {
    double dy = e.localPosition.dy;
    // 此高度为 160为录音取消组件距离顶部的预留距离
    double height = MediaQuery.of(context).size.height * 0.5 - 240;
    if (dy.abs() > height) {
      isCancelSend = true;
    } else {
      isCancelSend = false;
    }
    if (overlayEntry != null) {
      overlayEntry!.remove();
      overlayEntry = null;
    }
    // Did not receive onStop from FlutterPluginRecord if the duration is too short.
    if (DateTime.now().difference(startTime).inSeconds < 1) {
      isCancelSend = true;
      onTIMCallback(TIMCallback(
          type: TIMCallbackType.INFO,
          infoRecommendText: TIM_t("说话时间太短"),
          infoCode: 6660404));
    }
    stop();
  }

  onLonePressCancel() {
    if (isRecording) {
      isCancelSend = true;
      if (overlayEntry != null) {
        overlayEntry!.remove();
        overlayEntry = null;
      }
      stop();
    }
  }

  void stop() {
    setState(() {
      isRecording = false;
      isInCancelArea = false;
    });
    _maxDurationTimer?.cancel();
    _maxDurationTimer = null;
    _elapsedTimer?.cancel();
    _elapsedTimer = null;
    SoundPlayer.stopRecord();
    setState(() {
      soundTipsText = TIM_t("手指上滑，取消发送");
      _recordDuration = Duration.zero;
    });
  }

  sendSound(
      {required String path,
      required int duration,
      required TUIChatSeparateViewModel model}) {
    final convID = widget.conversationID;
    final convType = widget.conversationType;
    final int safeDuration =
        min(duration, _maxRecordDuration.inSeconds); // 限制录音长度不超过 60 秒

    if (safeDuration > 0) {
      if (!isCancelSend) {
        MessageUtils.handleMessageError(
            model.sendSoundMessage(
                soundPath: path,
                duration: safeDuration,
                convID: convID,
                convType: convType),
            context);
        widget.onDownBottom();
      } else {
        isCancelSend = false;
      }
    } else {
      onTIMCallback(TIMCallback(
          type: TIMCallbackType.INFO,
          infoRecommendText: TIM_t("说话时间太短"),
          infoCode: 6660404));
    }
  }

  @override
  dispose() {
    for (var subscription in subscriptions) {
      subscription.cancel();
    }
    _maxDurationTimer?.cancel();
    _maxDurationTimer = null;
    _elapsedTimer?.cancel();
    _elapsedTimer = null;
    super.dispose();
  }

  initRecordSound(TUIChatSeparateViewModel model) {
    final responseSubscription = SoundPlayer.responseListener((recordResponse) {
      final status = recordResponse.msg;
      if (status == "onStop") {
        if (!isCancelSend) {
          final soundPath = recordResponse.path;
          final recordDuration = recordResponse.audioTimeLength;
          sendSound(
              path: soundPath!, duration: recordDuration!.ceil(), model: model);
        }
      } else if (status == "onStart") {
        outputLogger.i("start record");
        setState(() {
          isRecording = true;
        });
      } else {
        outputLogger.i(status.toString());
      }
    });
    final amplitudesResponseSubscription =
        SoundPlayer.responseFromAmplitudeListener((recordResponse) {
      setState(() {
        volume = double.parse(recordResponse.msg!) * 1.1;
        if (overlayEntry != null) {
          overlayEntry!.markNeedsBuild();
        }
      });
    });
    subscriptions = [responseSubscription, amplitudesResponseSubscription];
    SoundPlayer.initSoundPlayer();
    isInit = true;
  }

  @override
  Widget tuiBuild(BuildContext context, TUIKitBuildValue value) {
    final TUITheme theme = value.theme;
    final TUIChatSeparateViewModel model =
        Provider.of<TUIChatSeparateViewModel>(context);
    return GestureDetector(
      onTapDown: (detail) async {
        if (!isInit) {
          bool hasMicrophonePermission = await Permissions.checkPermission(
            context,
            Permission.microphone.value,
            theme,
          );
          if (!hasMicrophonePermission) {
            return;
          }
          initRecordSound(model);
        }
      },
      onLongPressStart: onLongPressStart,
      onLongPressMoveUpdate: onLongPressUpdate,
      onLongPressEnd: onLongPressEnd,
      onLongPressCancel: onLonePressCancel,
      child: Container(
        height: 32,
        color: isRecording ? theme.weakBackgroundColor : Colors.white,
        alignment: Alignment.center,
        child: Text(
          TIM_t("按住说话"),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: theme.darkTextColor,
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final totalSeconds = duration.inSeconds.clamp(0, _maxRecordDuration.inSeconds);
    return '$totalSeconds”';
  }

  String _getRecordingTip(int secondsLeft) {
    if (secondsLeft > 0 && secondsLeft <= 10) {
      final option1Text = secondsLeft.toString();
      return TIM_t_para("{{option1}}秒后录音结束", "$option1Text秒后录音结束")(
          option1: option1Text);
    }
    return TIM_t("手指上滑，取消发送");
  }
}

class _MicWaveBar extends StatelessWidget {
  const _MicWaveBar({required this.level});

  final double level;

  @override
  Widget build(BuildContext context) {
    final double normalized = level.clamp(0.0, 1.0);
    final double barHeight = 12 + normalized * 28;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 80),
      curve: Curves.easeOut,
      width: 12,
      height: barHeight,
      decoration: const BoxDecoration(
        color: Color(0x80FFFFFF),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(0),
          topRight: Radius.circular(0),
          bottomLeft: Radius.circular(5),
          bottomRight: Radius.circular(5),
        ),
      ),
    );
  }
}
