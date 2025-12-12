import 'package:flutter/foundation.dart';

/// 轻量级的提示工具，专用于子包内部的简单 Toast 展示。
/// - 用途：提供最小可用的全局提示，避免依赖宿主工程的实现，同时允许宿主注入自定义样式。
/// - 约束：调用前需确保 Flutter 环境已初始化，适合在 UI 线程使用。
class NotifyUtil {
  /// 可选的宿主自定义 Toast 渲染器。
  /// - 用途：覆盖默认样式，保持与主包一致。
  /// - 约束：需要自行处理异常与重复弹窗。
  static Future<void> Function(String message, {int durationSeconds})?
      _toastHandler;

  /// 注册宿主侧的 Toast 渲染器。
  /// - 入参：handler 为自定义的异步展示方法；durationSeconds 表示展示时长（秒）。
  /// - 返回：无。
  /// - 约束：仅保留最后一次注册的处理器，需保证线程安全。
  static void registerToastHandler(
    Future<void> Function(String message, {int durationSeconds}) handler,
  ) {
    _toastHandler = handler;
  }

  /// 显示短暂的 Toast 文案（需提前注册渲染器）。
  /// - 入参：message 为提示内容；durationSeconds 控制展示时长（秒），默认 1 秒。
  /// - 返回：无。
  /// - 约束：未注册 handler 时直接返回且打印调试日志，不提供默认样式。
  static void showToast(String message, {int durationSeconds = 1}) {
    if (message.isEmpty) {
      return;
    }
    final handler = _toastHandler;
    if (handler != null) {
      handler(message, durationSeconds: durationSeconds);
      return;
    }
    debugPrint('NotifyUtil.showToast skipped: toast handler not registered.');
  }
}
