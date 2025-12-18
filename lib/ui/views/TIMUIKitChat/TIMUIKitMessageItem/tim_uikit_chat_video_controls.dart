import 'dart:async';

import 'package:better_player_plus/better_player_plus.dart';
import 'package:flutter/material.dart';

/// 聊天视频预览页控制条样式配置（用于快速调参，模拟主流视频 App 的进度条体验）。
///
/// - 用途：集中管理播放/暂停按钮、时间文本、进度条（统一圆角容器承载）等视觉参数。
/// - 入参：通过构造函数传入各项样式字段；不传则使用默认值。
/// - 返回：纯数据对象，不包含业务逻辑。
/// - 约束：该样式仅用于聊天视频预览页的 BetterPlayer 自定义控制条。
@immutable
class TIMUIKitChatVideoControlsStyle {
  /// 播放/暂停图标颜色。
  final Color iconColor;

  /// 播放/暂停图标尺寸（dp）。
  final double iconSize;

  /// 时间文本样式（如 00:12）。
  final TextStyle timeTextStyle;

  /// 底部控制条与屏幕边缘的外边距（通过 Padding 实现）。
  ///
  /// - 用途：控制控制条距离左右/底部的安全区域，避免贴边影响点击与观感。
  /// - 约束：该值是“外边距”，不影响容器内部元素的排布间距。
  final EdgeInsetsGeometry controlsMargin;

  /// 控制条容器背景色（覆盖播放按钮/时间/进度条/总时长）。
  final Color controlsBackgroundColor;

  /// 控制条容器圆角半径（dp）。
  final double controlsBackgroundRadius;

  /// 控制条容器内边距（dp），用于让内容与圆角边缘留出呼吸感。
  final EdgeInsetsGeometry controlsPadding;

  /// 进度条区域内边距（dp），用于微调 Slider 的触控/视觉高度。
  final EdgeInsetsGeometry progressPadding;

  /// 进度条轨道高度（dp）。
  final double progressTrackHeight;

  /// 进度条拖拽圆点半径（dp）。
  final double progressThumbRadius;

  /// 进度条点击/拖拽时的波纹半径（dp）。
  final double progressOverlayRadius;

  /// 已播放进度颜色。
  final Color progressPlayedColor;

  /// 未播放进度颜色。
  final Color progressUnplayedColor;

  /// 控制条自动隐藏时长（播放中且无交互时生效）。
  final Duration autoHideDuration;

  /// 控制条淡入淡出动画时长。
  final Duration fadeDuration;

  const TIMUIKitChatVideoControlsStyle({
    this.iconColor = Colors.white,
    this.iconSize = 20,
    this.timeTextStyle = const TextStyle(
      color: Colors.white,
      fontSize: 12,
      height: 1.0,
    ),
    this.controlsMargin =
        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    this.controlsBackgroundColor = const Color(0x59000000),
    this.controlsBackgroundRadius = 10,
    this.controlsPadding = const EdgeInsets.symmetric(
      horizontal: 12,
      vertical: 8,
    ),
    this.progressPadding = const EdgeInsets.symmetric(horizontal: 6),
    this.progressTrackHeight = 2,
    this.progressThumbRadius = 6,
    this.progressOverlayRadius = 10,
    this.progressPlayedColor = Colors.white,
    this.progressUnplayedColor = Colors.white30,
    this.autoHideDuration = const Duration(seconds: 3),
    this.fadeDuration = const Duration(milliseconds: 200),
  });
}

/// 1v1 聊天视频预览页的 BetterPlayer 自定义控制条（可配置进度条样式）。
///
/// - 用途：
///   1) 替换 BetterPlayer 默认 Material 控制层在 Android 上的整屏发黑遮罩；
///   2) 提供可调的控制条样式（统一圆角容器包裹「播放按钮/时间/进度条/总时长」）。
/// - 入参：
///   - [betterPlayerController] BetterPlayer 控制器（用于播放/暂停/seek 与读取当前进度）。
///   - [onPlayerVisibilityChanged] 控制条显隐回调，用于同步 BetterPlayer 内部可见性流。
///   - [style] 控制条样式配置。
/// - 返回：覆盖在视频上的控制层 Widget。
/// - 约束：仅用于聊天视频预览页；不负责关闭/下载按钮等外层控件。
class TIMUIKitChatVideoControls extends StatefulWidget {
  const TIMUIKitChatVideoControls({
    super.key,
    required this.betterPlayerController,
    required this.onPlayerVisibilityChanged,
    this.style = const TIMUIKitChatVideoControlsStyle(),
  });

  /// BetterPlayer 控制器（用于播放/暂停/seek 与读取当前进度）。
  final BetterPlayerController betterPlayerController;

  /// 控制条显隐回调（用于同步 BetterPlayer 内部可见性流）。
  final Function(bool) onPlayerVisibilityChanged;

  /// 控制条样式配置（用于快速调参）。
  final TIMUIKitChatVideoControlsStyle style;

  @override
  State<TIMUIKitChatVideoControls> createState() =>
      _TIMUIKitChatVideoControlsState();
}

class _TIMUIKitChatVideoControlsState extends State<TIMUIKitChatVideoControls> {
  /// 底层视频控制器监听器（仅依赖 ValueNotifier 能力，避免引用第三方包的 src 实现）。
  ValueNotifier<VideoPlayerValue>? _videoPlayerController;

  /// 自动隐藏控制条的计时器（仅在播放中且控制条可见时启动）。
  Timer? _autoHideTimer;

  /// 当前控制条是否可见。
  bool _isControlsVisible = false;

  /// 拖动进度条前是否处于播放中，用于拖动结束后恢复播放状态。
  bool _wasPlayingBeforeDrag = false;

  /// 拖动进度条时的临时毫秒值；为空表示未在拖动中，使用视频真实进度。
  double? _draggingPositionMs;

  @override
  void initState() {
    super.initState();
    _bindVideoController();
  }

  @override
  void didUpdateWidget(covariant TIMUIKitChatVideoControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.betterPlayerController != widget.betterPlayerController) {
      _unbindVideoController();
      _bindVideoController();
    }
  }

  @override
  void dispose() {
    _cancelAutoHideTimer();
    _unbindVideoController();
    super.dispose();
  }

  /// 绑定底层 VideoPlayerController 的监听，用于刷新进度与播放状态。
  void _bindVideoController() {
    _videoPlayerController =
        widget.betterPlayerController.videoPlayerController;
    _videoPlayerController?.addListener(_onVideoValueChanged);
  }

  /// 解绑底层 VideoPlayerController 的监听，避免组件销毁后继续回调导致异常。
  void _unbindVideoController() {
    _videoPlayerController?.removeListener(_onVideoValueChanged);
    _videoPlayerController = null;
  }

  /// 底层视频状态变化回调：刷新 UI，并按需启动/取消自动隐藏。
  void _onVideoValueChanged() {
    if (!mounted) {
      return;
    }
    _syncAutoHideState();
    setState(() {});
  }

  /// 同步控制条自动隐藏逻辑：仅在播放中且控制条可见时启动倒计时。
  void _syncAutoHideState() {
    if (!_isControlsVisible) {
      return;
    }
    final bool isPlaying = _videoPlayerController?.value.isPlaying ?? false;
    if (!isPlaying) {
      _cancelAutoHideTimer();
      return;
    }
    if (_autoHideTimer != null) {
      return;
    }
    _autoHideTimer = Timer(widget.style.autoHideDuration, () {
      if (!mounted) {
        return;
      }
      _setControlsVisible(false);
    });
  }

  /// 重启自动隐藏计时器（会先取消旧计时器）。
  void _restartAutoHideTimer() {
    _cancelAutoHideTimer();
    _syncAutoHideState();
  }

  /// 取消自动隐藏计时器。
  void _cancelAutoHideTimer() {
    _autoHideTimer?.cancel();
    _autoHideTimer = null;
  }

  /// 设置控制条显隐，并同步 BetterPlayer 内部可见性事件与回调。
  /// [visible] true 显示；false 隐藏。
  void _setControlsVisible(bool visible) {
    if (_isControlsVisible == visible) {
      if (visible) {
        _restartAutoHideTimer();
      }
      return;
    }
    _isControlsVisible = visible;
    widget.betterPlayerController.toggleControlsVisibility(visible);
    widget.onPlayerVisibilityChanged(visible);
    if (!visible) {
      _cancelAutoHideTimer();
    } else {
      _syncAutoHideState();
    }
    setState(() {});
  }

  /// 点击视频区域：切换控制条显隐。
  void _handleTap() {
    _setControlsVisible(!_isControlsVisible);
  }

  /// 双击视频区域：切换播放/暂停，并确保控制条可见以便用户感知状态变化。
  void _handleDoubleTap() {
    unawaited(_togglePlayPause());
    _setControlsVisible(true);
  }

  /// 切换视频播放/暂停状态。
  Future<void> _togglePlayPause() async {
    try {
      final bool isPlaying = _videoPlayerController?.value.isPlaying ?? false;
      if (isPlaying) {
        await widget.betterPlayerController.pause();
        _cancelAutoHideTimer();
      } else {
        await widget.betterPlayerController.play();
        _syncAutoHideState();
      }
    } catch (_) {
      // 控制器可能尚未初始化完成；此处静默失败，避免影响页面交互。
    }
  }

  /// 拖动进度条开始：记录播放状态并暂停，避免拖动时画面继续前进。
  void _onSeekStart() {
    _wasPlayingBeforeDrag = _videoPlayerController?.value.isPlaying ?? false;
    _cancelAutoHideTimer();
    if (!_wasPlayingBeforeDrag) {
      return;
    }
    try {
      widget.betterPlayerController.pause();
    } catch (_) {
      // ignore
    }
  }

  /// 拖动进度条更新：seek 到目标位置并更新 UI 临时进度。
  /// [positionMs] 目标位置（毫秒）。
  void _onSeekChanged(double positionMs) {
    _draggingPositionMs = positionMs;
    setState(() {});
    try {
      widget.betterPlayerController
          .seekTo(Duration(milliseconds: positionMs.toInt()));
    } catch (_) {
      // ignore
    }
  }

  /// 拖动进度条结束：清空临时进度，并在需要时恢复播放与自动隐藏。
  /// [positionMs] 目标位置（毫秒）。
  void _onSeekEnd(double positionMs) {
    _draggingPositionMs = null;
    setState(() {});

    if (_wasPlayingBeforeDrag) {
      try {
        widget.betterPlayerController.play();
      } catch (_) {
        // ignore
      }
    }
    _syncAutoHideState();
  }

  /// 将毫秒值安全转换为可用的时长文本。
  /// [milliseconds] 输入毫秒数。
  /// 返回格式化后的字符串（00:00 或 00:00:00）。
  String _formatMilliseconds(int milliseconds) {
    final int totalSeconds = (milliseconds ~/ 1000).clamp(0, 1 << 31);
    final int hours = totalSeconds ~/ 3600;
    final int minutes = (totalSeconds % 3600) ~/ 60;
    final int seconds = totalSeconds % 60;

    String twoDigits(int value) => value.toString().padLeft(2, '0');

    if (hours > 0) {
      return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  /// 构建控制层的手势区域（单击显隐 / 双击播放暂停）。
  Widget _buildGestureLayer() {
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _handleTap,
        onDoubleTap: _handleDoubleTap,
      ),
    );
  }

  /// 构建进度条（Slider）区域。
  ///
  /// - 用途：负责播放进度展示与拖拽/点击 Seek；背景由外层控制条容器统一承载。
  /// [durationMs] 视频总时长（毫秒）。
  /// [sliderValue] 当前 slider 值（毫秒，可能来自拖动中临时值）。
  Widget _buildProgressBar({
    required int durationMs,
    required double sliderValue,
  }) {
    return Padding(
      padding: widget.style.progressPadding,
      child: SliderTheme(
        data: SliderTheme.of(context).copyWith(
          trackHeight: widget.style.progressTrackHeight,
          thumbShape: RoundSliderThumbShape(
            enabledThumbRadius: widget.style.progressThumbRadius,
          ),
          overlayShape: RoundSliderOverlayShape(
            overlayRadius: widget.style.progressOverlayRadius,
          ),
          trackShape: const RectangularSliderTrackShape(),
        ),
        child: Slider(
          value: sliderValue,
          min: 0,
          max: durationMs.toDouble(),
          onChangeStart: (_) => _onSeekStart(),
          onChanged: (double v) => _onSeekChanged(v),
          onChangeEnd: (double v) => _onSeekEnd(v),
          activeColor: widget.style.progressPlayedColor,
          inactiveColor: widget.style.progressUnplayedColor,
        ),
      ),
    );
  }

  /// 构建控制条容器（统一承载背景与内边距）。
  ///
  /// - 用途：让播放按钮/时间/进度条/总时长都被同一个圆角半透明容器包裹。
  /// - 入参：[child] 为容器内部内容区域。
  /// - 返回：带背景与圆角的容器 Widget。
  Widget _buildControlsContainer({required Widget child}) {
    return Container(
      padding: widget.style.controlsPadding,
      decoration: BoxDecoration(
        color: widget.style.controlsBackgroundColor,
        borderRadius: BorderRadius.circular(
          widget.style.controlsBackgroundRadius,
        ),
      ),
      child: child,
    );
  }

  /// 构建控制条内部布局（播放按钮 + 当前时间 + 进度条 + 总时长）。
  ///
  /// - 入参：
  ///   - [value] 当前视频播放状态（用于判断播放/暂停图标）。
  ///   - [durationMs] 视频总时长（毫秒）。
  ///   - [positionMs] 当前播放位置（毫秒）。
  ///   - [sliderValue] 进度条展示值（毫秒，拖动中可能与 positionMs 不同）。
  /// - 返回：控制条内部 Row 布局。
  Widget _buildControlsContent({
    required VideoPlayerValue value,
    required int durationMs,
    required int positionMs,
    required double sliderValue,
  }) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => unawaited(_togglePlayPause()),
          child: Icon(
            value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            color: widget.style.iconColor,
            size: widget.style.iconSize,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          _formatMilliseconds(positionMs),
          style: widget.style.timeTextStyle,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildProgressBar(
            durationMs: durationMs,
            sliderValue: sliderValue,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          _formatMilliseconds(durationMs),
          style: widget.style.timeTextStyle,
        ),
      ],
    );
  }

  /// 构建底部控制条区域（播放按钮 + 时间 + 进度条 + 总时长）。
  /// [value] 当前视频播放状态。
  /// [durationMs] 视频总时长（毫秒）。
  /// [positionMs] 当前播放位置（毫秒）。
  /// [sliderValue] 当前 slider 值（毫秒，可能来自拖动中临时值）。
  Widget _buildBottomBar({
    required VideoPlayerValue value,
    required int durationMs,
    required int positionMs,
    required double sliderValue,
  }) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: IgnorePointer(
        ignoring: !_isControlsVisible,
        child: AnimatedOpacity(
          opacity: _isControlsVisible ? 1.0 : 0.0,
          duration: widget.style.fadeDuration,
          child: Padding(
            padding: widget.style.controlsMargin,
            child: _buildControlsContainer(
              child: _buildControlsContent(
                value: value,
                durationMs: durationMs,
                positionMs: positionMs,
                sliderValue: sliderValue,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final VideoPlayerValue? value = _videoPlayerController?.value;
    final Duration? duration = value?.duration;
    if (value == null || duration == null || !value.initialized) {
      return const SizedBox.shrink();
    }

    final int durationMs = duration.inMilliseconds.clamp(0, 1 << 31);
    final int positionMs = value.position.inMilliseconds.clamp(0, durationMs);
    final double sliderValue = (_draggingPositionMs ?? positionMs.toDouble())
        .clamp(0, durationMs.toDouble());

    return Stack(
      children: [
        _buildGestureLayer(),
        _buildBottomBar(
          value: value,
          durationMs: durationMs,
          positionMs: positionMs,
          sliderValue: sliderValue,
        ),
      ],
    );
  }
}
