import 'package:flutter/foundation.dart';

/// 子包内部的禁言校验占位实现，支持宿主注入真实校验逻辑。
/// - 用途：在发送前做可选的禁言判定，避免直接依赖宿主工程。
/// - 约束：默认总是允许发送，可通过 registerChecker 注册实际校验。
class ImMuteStatusManager {
  ImMuteStatusManager._();

  /// 单例入口，避免重复创建。
  static final ImMuteStatusManager instance = ImMuteStatusManager._();

  /// 可选的自定义校验器，返回 false 时阻断发送。
  /// - 入参：forceRefresh 由调用方传入，表示是否需要强制刷新禁言状态。
  /// - 返回：Future<bool>，true 代表允许发送，false 代表禁言。
  /// - 约束：宿主若要接管逻辑，可在应用启动时调用 registerChecker 注入。
  Future<bool> Function({bool forceRefresh})? _checker;

  /// 注册宿主实现的禁言校验器。
  /// - 入参：checker 为外部提供的异步函数。
  /// - 返回：无。
  /// - 约束：仅保留最后一次注册的实现，需保证线程安全和异常兜底。
  void registerChecker(Future<bool> Function({bool forceRefresh}) checker) {
    _checker = checker;
  }

  /// 校验当前是否允许发送消息。
  /// - 入参：forceRefresh 控制是否强制刷新禁言状态。
  /// - 返回：Future<bool>，true 表示允许发送，false 表示禁言。
  /// - 约束：若未注册校验器则默认放行；捕获异常后也默认放行，避免界面卡死。
  Future<bool> ensureSendAllowed({bool forceRefresh = false}) async {
    final handler = _checker;
    if (handler == null) {
      return true;
    }
    try {
      return await handler(forceRefresh: forceRefresh);
    } catch (error, stackTrace) {
      debugPrint('ensureSendAllowed failed: $error\n$stackTrace');
      return true;
    }
  }
}
