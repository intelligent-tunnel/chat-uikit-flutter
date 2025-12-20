import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tencent_chat_i18n_tool/tencent_chat_i18n_tool.dart';
import 'package:tencent_cloud_chat_sdk/enum/get_group_message_read_member_list_filter.dart';
import 'package:tencent_cloud_chat_sdk/enum/group_member_filter_enum.dart';
import 'package:tencent_cloud_chat_sdk/enum/history_msg_get_type_enum.dart';
import 'package:tencent_cloud_chat_sdk/enum/message_priority_enum.dart';
import 'package:tencent_cloud_chat_sdk/enum/message_status.dart';
import 'package:tencent_cloud_chat_sdk/enum/offlinePushInfo.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_conversation.dart'
    if (dart.library.html) 'package:tencent_cloud_chat_sdk/web/compatible_models/v2_tim_conversation.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_custom_elem.dart'
    if (dart.library.html) 'package:tencent_cloud_chat_sdk/web/compatible_models/v2_tim_custom_elem.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_friend_info_result.dart'
    if (dart.library.html) 'package:tencent_cloud_chat_sdk/web/compatible_models/v2_tim_friend_info_result.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_group_info.dart'
    if (dart.library.html) 'package:tencent_cloud_chat_sdk/web/compatible_models/v2_tim_group_info.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_group_member_full_info.dart'
    if (dart.library.html) 'package:tencent_cloud_chat_sdk/web/compatible_models/v2_tim_group_member_full_info.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_group_message_read_member_list.dart'
    if (dart.library.html)
        'package:tencent_cloud_chat_sdk/web/compatible_models/v2_tim_group_message_read_member_list.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_message.dart'
    if (dart.library.html) 'package:tencent_cloud_chat_sdk/web/compatible_models/v2_tim_message.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_message_change_info.dart'
    if (dart.library.html) 'package:tencent_cloud_chat_sdk/web/compatible_models/v2_tim_message_change_info.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_message_receipt.dart'
    if (dart.library.html) 'package:tencent_cloud_chat_sdk/web/compatible_models/v2_tim_message_receipt.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_msg_create_info_result.dart'
    if (dart.library.html) 'package:tencent_cloud_chat_sdk/web/compatible_models/v2_tim_msg_create_info_result.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_user_full_info.dart'
    if (dart.library.html) 'package:tencent_cloud_chat_sdk/web/compatible_models/v2_tim_user_full_info.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_value_callback.dart'
    if (dart.library.html) 'package:tencent_cloud_chat_sdk/web/compatible_models/v2_tim_value_callback.dart';
import 'package:tencent_cloud_chat_sdk/models/v2_tim_video_elem.dart'
    if (dart.library.html) 'package:tencent_cloud_chat_sdk/web/compatible_models/v2_tim_video_elem.dart';
import 'package:tencent_cloud_chat_sdk/tencent_im_sdk_plugin.dart';
import 'package:tencent_cloud_chat_uikit/base_widgets/tim_callback.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/life_cycle/chat_life_cycle.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/separate_models/tui_chat_model_tools.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/view_models/tui_chat_global_model.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/view_models/tui_conversation_view_model.dart';
import 'package:tencent_cloud_chat_uikit/business_logic/view_models/tui_self_info_view_model.dart';
import 'package:tencent_cloud_chat_uikit/data_services/friendShip/friendship_services.dart';
import 'package:tencent_cloud_chat_uikit/data_services/group/group_services.dart';
import 'package:tencent_cloud_chat_uikit/data_services/message/message_services.dart';
import 'package:tencent_cloud_chat_uikit/data_services/services_locatar.dart';
import 'package:tencent_cloud_chat_uikit/tencent_cloud_chat_uikit.dart';
import 'package:tencent_cloud_chat_uikit/ui/constants/history_message_constant.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/logger.dart';
import 'package:tencent_cloud_chat_uikit/ui/utils/platform.dart';
import 'package:uuid/uuid.dart';

enum LoadDirection { previous, latest }

class TUIChatSeparateViewModel extends ChangeNotifier {
  final FriendshipServices _friendshipServices = serviceLocator<FriendshipServices>();
  final MessageService _messageService = serviceLocator<MessageService>();
  final GroupServices _groupServices = serviceLocator<GroupServices>();
  final TUIChatGlobalModel globalModel = serviceLocator<TUIChatGlobalModel>();
  final TUIChatModelTools tools = serviceLocator<TUIChatModelTools>();
  final TUISelfInfoViewModel selfModel = serviceLocator<TUISelfInfoViewModel>();
  final TUIConversationViewModel conversationViewModel = serviceLocator<TUIConversationViewModel>();
  final _uuid = const Uuid();

  ChatLifeCycle? lifeCycle;
  int _totalUnreadCount = 0;
  bool _isMultiSelect = false;
  bool _isInit = false;
  String conversationID = "";
  ConvType? conversationType;
  bool haveMoreData = false;
  bool haveMoreLatestData = false;
  String _currentPlayedMsgId = "";
  GroupReceiptAllowType? _groupType;
  // List<V2TimMessage> _multiSelectedMessageList = [];
  Map<String, bool> _selectedPositions = {};
  V2TimMessage? _repliedMessage;
  String _jumpMsgID = "";
  bool _isGroupExist = true;
  bool _isNotAMember = false;
  bool showC2cMessageEditStatus = true;
  TIMUIKitChatConfig chatConfig = const TIMUIKitChatConfig();
  ValueChanged<String>? setInputField;
  String? Function(V2TimMessage message)? abstractMessageBuilder;
  Function(String userID, TapDownDetails tapDetails)? onTapAvatar;
  V2TimGroupMemberFullInfo? _currentChatUserInfo;
  V2TimGroupInfo? _groupInfo;
  String groupMemberListSeq = "0";
  List<V2TimGroupMemberFullInfo?>? groupMemberList = [];
  V2TimGroupMemberFullInfo? selfMemberInfo;
  double atPositionX = 0.0;
  double atPositionY = 0.0;
  int _activeAtIndex = -1;
  List<V2TimGroupMemberFullInfo?> _showAtMemberList = [];
  Map<String, String> _groupUserShowName = {};
  String? _groupID;

  Map<String, String> get groupUserShowName => _groupUserShowName;
  // value 的 bool 值表示是否已经延迟显示过发送进度
  final Map<String, bool> _sendingMessageIDMap = {};
  Map<String, V2TimMessage> _readReceiptMap = {};

  set groupUserShowName(Map<String, String> value) {
    _groupUserShowName = value;
    _notify();
  }

  int get activeAtIndex => _activeAtIndex;

  set activeAtIndex(int value) {
    _activeAtIndex = value;
    _notify();
  }

  List<V2TimGroupMemberFullInfo?> get showAtMemberList => _showAtMemberList;

  set showAtMemberList(List<V2TimGroupMemberFullInfo?> value) {
    _showAtMemberList = value;
    _notify();
  }

  V2TimGroupInfo? get groupInfo => _groupInfo;

  set groupInfo(V2TimGroupInfo? value) {
    _groupInfo = value;
    _notify();
  }

  int get totalUnreadCount => _totalUnreadCount;

  set totalUnreadCount(int value) {
    _totalUnreadCount = value;
    _notify();
  }

  bool get isMultiSelect => _isMultiSelect;

  set isMultiSelect(bool value) {
    _isMultiSelect = value;
    _notify();
  }

  String get currentPlayedMsgId => _currentPlayedMsgId;

  set currentPlayedMsgId(String value) {
    _currentPlayedMsgId = value;
    _notify();
  }

  GroupReceiptAllowType? get groupType => _groupType;

  set groupType(GroupReceiptAllowType? value) {
    _groupType = value;
    _notify();
  }

  List<V2TimMessage> getSelectedMessageList() {
    List<V2TimMessage> selectList = [];
    if (_selectedPositions.isEmpty) {
      return selectList;
    }

    List<V2TimMessage> currentHistoryMsgList = getOriginMessageList();
    for (var v2TimMessage in currentHistoryMsgList) {
      if (_selectedPositions.containsKey(v2TimMessage.msgID) && _selectedPositions[v2TimMessage.msgID]!) {
        selectList.add(v2TimMessage);
      }
    }

    return selectList.reversed.toList();
  }

  List<String> getSelectedMessageIDList() {
    List<String> selectList = [];
    if (_selectedPositions.isEmpty) {
      return selectList;
    }

    for (String msgID in _selectedPositions.keys) {
      if (_selectedPositions[msgID]!) {
        selectList.add(msgID);
      }
    }

    return selectList;
  }

  V2TimMessage? get repliedMessage => _repliedMessage;

  set repliedMessage(V2TimMessage? value) {
    _repliedMessage = value;
    _notify();
  }

  String get jumpMsgID => _jumpMsgID;

  set jumpMsgID(String value) {
    _jumpMsgID = value;
    _notify();
  }

  bool get isGroupExist => _isGroupExist;

  set isGroupExist(bool value) {
    _isGroupExist = value;
    _notify();
  }

  bool get isNotAMember => _isNotAMember;

  set isNotAMember(bool value) {
    _isNotAMember = value;
    _notify();
  }

  V2TimGroupMemberFullInfo? get currentChatUserInfo => _currentChatUserInfo;

  set currentChatUserInfo(V2TimGroupMemberFullInfo? value) {
    _currentChatUserInfo = value;
    _notify();
  }

  setLoadingMessageMap(String conversationID, V2TimMessage messageInfo) {
    if (PlatformUtils().isWeb) {
      if (globalModel.loadingMessage[conversationID] != null &&
          globalModel.loadingMessage[conversationID]!.isNotEmpty) {
        globalModel.loadingMessage[conversationID]!.add(messageInfo);
      } else {
        globalModel.loadingMessage[conversationID] = <V2TimMessage>[messageInfo];
      }
    }
  }

  void getUserShowName(List<String> userIDs) async {
    final List<String> filteredList = userIDs.where((element) => !_groupUserShowName.containsKey(element)).toList();
    for (final element in filteredList) {
      _groupUserShowName[element] = element;
    }

    final String groupID = TencentUtils.checkString(_groupID) ?? conversationID;

    if (filteredList.isNotEmpty) {
      final res = await TencentImSDKPlugin.manager
          ?.getGroupManager()
          .getGroupMembersInfo(groupID: groupID, memberList: filteredList);
      if (res?.code == 0 && res?.data != null) {
        final data = res!.data;
        for (final userInfo in data!) {
          final showName = TencentUtils.checkString(userInfo.nameCard) ??
              TencentUtils.checkString(userInfo.nickName) ??
              TencentUtils.checkString(userInfo.userID);
          if (TencentUtils.checkString(showName) != null) {
            _groupUserShowName[userInfo.userID] = showName ?? userInfo.userID;
          }
        }
        if (data.isNotEmpty) {
          _notify();
        }
      }
    }
  }

  void initForEachConversation(ConvType convType, String convID, ValueChanged<String>? onChangeInputField,
      {String? groupID, List<V2TimGroupMemberFullInfo?>? preGroupMemberList}) async {
    if (_isInit) {
      return;
    }
    setInputField = onChangeInputField;
    conversationType = convType;
    conversationID = convID;

    _groupType = null;
    isGroupExist = true;
    _groupInfo = null;
    groupMemberList = null;
    selfMemberInfo = null;

    globalModel.setCurrentConversation(CurrentConversation(conversationID, conversationType ?? ConvType.c2c));
    globalModel.lifeCycle = lifeCycle;
    globalModel.setMessageListPosition(conversationID, HistoryMessagePosition.bottom);
    globalModel.setChatConfig(chatConfig);
    globalModel.clearReceivedNewMessageCount();

    if (conversationType == ConvType.group) {
      _groupID = groupID;
      _notify();
      Future.delayed(const Duration(milliseconds: 10), () async {
        globalModel.refreshGroupApplicationList();
        loadGroupInfo(groupID ?? convID);
        if (preGroupMemberList != null) {
          groupMemberList = preGroupMemberList;
          selfMemberInfo = preGroupMemberList.firstWhereOrNull((e) => e?.userID == selfModel.loginInfo?.userID);
        } else {
          await loadSelfMemberInfo(groupID: groupID ?? convID);
          loadGroupMemberList(groupID: groupID ?? convID);
        }
        if (selfMemberInfo == null) {
          await loadSelfMemberInfo(groupID: groupID ?? convID);
        }
      });
    } else {
      Future.delayed(const Duration(milliseconds: 10), () async {
        final List<V2TimFriendInfoResult>? friendRes = await _friendshipServices.getFriendsInfo(userIDList: [convID]);
        if (friendRes != null && friendRes.isNotEmpty) {
          final V2TimFriendInfoResult friendInfoResult = friendRes[0];
          currentChatUserInfo = V2TimGroupMemberFullInfo(
              userID: convID,
              faceUrl: friendInfoResult.friendInfo?.userProfile?.faceUrl,
              nickName: friendInfoResult.friendInfo?.userProfile?.nickName,
              friendRemark: friendInfoResult.friendInfo?.friendRemark);
        } else {
          final List<V2TimUserFullInfo>? userRes = await _friendshipServices.getUsersInfo(userIDList: [convID]);
          if (userRes != null && userRes.isNotEmpty) {
            final V2TimUserFullInfo userFullInfo = userRes[0];
            currentChatUserInfo = V2TimGroupMemberFullInfo(
              userID: convID,
              faceUrl: userFullInfo.faceUrl,
              nickName: userFullInfo.nickName,
            );
          }
        }
        _notify();
      });
    }

    _isInit = true;
    Future.delayed(const Duration(milliseconds: 300), () {
      markMessageAsRead();
    });
  }

  Future<bool> loadListForSpecificMessage({
    required int seq,
  }) async {
    List<V2TimMessage> msgList = [];
    bool tempHaveMoreData = false;

    final previousResponse = await _messageService.getHistoryMessageListWithComplete(
        count: 20,
        getType: HistoryMsgGetTypeEnum.V2TIM_GET_CLOUD_OLDER_MSG,
        userID: conversationType == ConvType.c2c ? conversationID : null,
        groupID: conversationType == ConvType.group ? conversationID : null,
        lastMsgSeq: max(seq, 0));
    msgList = previousResponse?.messageList ?? [];
    tempHaveMoreData = !(previousResponse?.isFinished ?? false);
    haveMoreLatestData = true;
    globalModel.setMessageListPosition(conversationID, HistoryMessagePosition.notShowLatest);

    msgList = await lifeCycle?.didGetHistoricalMessageList(msgList) ?? msgList;
    msgList.insert(
        msgList.length - 1,
        V2TimMessage(
            userID: '', isSelf: false, elemType: 101, msgID: msgList[0].msgID, seq: msgList[0].seq, timestamp: 9999));
    globalModel.setMessageList(conversationID, msgList, needResetNewMessageCount: false);

    if (chatConfig.isShowReadingStatus) {
      _getMsgReadReceipt(msgList);
    }

    haveMoreData = tempHaveMoreData;
    return haveMoreData;
  }

  // 加载聊天记录
  Future<bool> loadChatRecord({
    HistoryMsgGetTypeEnum? getType,
    int lastMsgSeq = -1,
    required int count,
    String? lastMsgID,
    LoadDirection direction = LoadDirection.previous,
  }) async {
    try {
      bool tempHaveMoreData = false;
      // 根据加载方向设置是否还能继续加载更多消息
      direction == LoadDirection.latest ? haveMoreLatestData = false : tempHaveMoreData = false;

      // 获取当前聊天对话的历史消息列表
      final currentRecordList = globalModel.messageListMap[conversationID];

      // 调用MessageService获取聊天记录
      final response = await _messageService.getHistoryMessageListWithComplete(
        count: count,
        getType: getType ??
            (direction == LoadDirection.previous
                ? HistoryMsgGetTypeEnum.V2TIM_GET_CLOUD_OLDER_MSG
                : HistoryMsgGetTypeEnum.V2TIM_GET_CLOUD_NEWER_MSG),
        userID: conversationType == ConvType.c2c ? conversationID : null,
        groupID: conversationType == ConvType.group ? conversationID : null,
        lastMsgID: lastMsgID,
        lastMsgSeq: lastMsgSeq,
      );

      if (response == null) {
        return false;
      }

      // 根据加载方向更新是否还能继续加载更多消息
      if (direction == LoadDirection.latest) {
        haveMoreLatestData = !response.isFinished;
      } else {
        tempHaveMoreData = !response.isFinished;
      }

      _notify();

      // 根据lastMsgID判断是否为分页加载
      if (lastMsgID != null && currentRecordList != null) {
        List<V2TimMessage> messageList = response.messageList;
        List<V2TimMessage> newList = [];

        // 根据加载方向拼接消息列表
        if (direction == LoadDirection.latest) {
          globalModel.receivedNewMessageCount = globalModel.receivedNewMessageCount + messageList.length;
          messageList = messageList.reversed.toList();
          newList = _combineMessageList(messageList, currentRecordList);
        } else {
          newList = _combineMessageList(currentRecordList, messageList);
        }

        // 处理新获取的消息列表后回调
        final List<V2TimMessage> msgList = await lifeCycle?.didGetHistoricalMessageList(newList) ?? newList;

        // 更新聊天记录到全局model
        globalModel.setMessageList(
          conversationID,
          msgList,
          needResetNewMessageCount: false,
        );
      } else {
        // 处理新获取的消息列表后回调
        List<V2TimMessage> receivedList =
            await lifeCycle?.didGetHistoricalMessageList(response.messageList) ?? response.messageList;
        globalModel.loadingMessage.remove(conversationID);

        // 更新聊天记录到全局model
        globalModel.setMessageList(
          conversationID,
          receivedList,
          needResetNewMessageCount: false,
        );
      }

      // 获取已读未读状态
      if (chatConfig.isShowReadingStatus && response.messageList.isNotEmpty) {
        _getMsgReadReceipt(response.messageList);
      }

      // 根据加载方向更新是否还能继续加载更多消息
      if (direction == LoadDirection.latest && !haveMoreLatestData) {
        globalModel.setMessageListPosition(conversationID, HistoryMessagePosition.inTwoScreen);
      }
      _notify();

      haveMoreData = tempHaveMoreData;
      return haveMoreData;
    } catch (e) {
      // ignore: avoid_print
      outputLogger.i('loadChatRecord error: $e');
      return false;
    }
  }

  // 拼接聊天记录
  List<V2TimMessage> _combineMessageList(List<V2TimMessage> first, List<V2TimMessage> second) {
    return [...first, ...second];
  }

  Future<bool> loadDataFromController({int? count}) {
    return loadChatRecord(
      count: count ?? HistoryMessageDartConstant.getCount, //20
    );
  }

  Future<V2TimValueCallback<List<V2TimMessageReceipt>>> getMessageReadReceipts(List<String> messageIDList) {
    return _messageService.getMessageReadReceipts(messageIDList: messageIDList);
  }

  _getMsgReadReceipt(List<V2TimMessage> message) async {
    final msgID = message
        .where((e) =>
            (e.isSelf ?? true) &&
            (e.needReadReceipt ?? false) &&
            (e.status == MessageStatus.V2TIM_MSG_STATUS_SEND_SUCC))
        .map((e) => e.msgID ?? '')
        .toList();
    if (msgID.isNotEmpty) {
      final res = await getMessageReadReceipts(msgID);
      if (res.code == 0) {
        final receiptList = res.data;
        if (receiptList != null) {
          for (var item in receiptList) {
            globalModel.messageReadReceiptMap[item.msgID!] = item;
          }
        }
      }
      _notify();
    }
  }

  translateText(V2TimMessage message) async {
    final String originText = message.textElem?.text ?? "";
    final String deviceLocale = TIM_getCurrentDeviceLocale();
    final String targetMessage = deviceLocale.split("-")[0];
    final translatedText = await _messageService.translateText(originText, targetMessage);

    final LocalCustomDataModel localCustomData =
        LocalCustomDataModel.fromMap(json.decode(TencentUtils.checkString(message.localCustomData) ?? "{}"));
    localCustomData.translatedText = translatedText;
    message.localCustomData = json.encode(localCustomData.toMap());
    globalModel.onMessageModified(message);
    TencentImSDKPlugin.v2TIMManager.v2TIMMessageManager
        .setLocalCustomData(msgID: message.msgID!, localCustomData: message.localCustomData ?? "");
  }

  addToMessageReadReceiptList(V2TimMessage message) {
    if (chatConfig.isShowReadingStatus) {
      if (message.msgID != null) {
        _readReceiptMap[message.msgID!] = message;
      }

      Future.delayed(const Duration(milliseconds: 200), () {
        _setMsgReadReceipt(_readReceiptMap.values.toList());
      });
    }
  }

  _setMsgReadReceipt(List<V2TimMessage> messageList) async {
    final msgIDList = List<String>.empty(growable: true);
    for (var item in messageList) {
      final isSelf = item.isSelf ?? true;
      final needReadReceipt = item.needReadReceipt ?? false;
      final isRead = item.isRead ?? false;
      if (!isRead && !isSelf && needReadReceipt && item.msgID != null) {
        msgIDList.add(item.msgID!);
        item.needReadReceipt = false;
      }
    }
    if (msgIDList.isNotEmpty) {
      sendMessageReadReceipts(msgIDList);
    }
  }

  sendMessageReadReceipts(List<String> messageIDList) async {
    final res = await _messageService.sendMessageReadReceipts(messageIDList: messageIDList);
    return res;
  }

  markMessageAsRead() async {
    if (conversationType == ConvType.c2c) {
      return _messageService.markC2CMessageAsRead(userID: conversationID);
    }

    final res = await _messageService.markGroupMessageAsRead(groupID: conversationID);
    if (res.code == 10015) {
      isGroupExist = false;
    }
  }

  Future<void> loadSelfMemberInfo({required String groupID}) async {
    V2TimValueCallback<List<V2TimGroupMemberFullInfo>> getGroupMembersInfoRes =
        await TencentImSDKPlugin.v2TIMManager.getGroupManager().getGroupMembersInfo(
      groupID: groupID,
      memberList: [selfModel.loginInfo?.userID ?? ""],
    );
    if (getGroupMembersInfoRes.code == 0) {
      final userList = getGroupMembersInfoRes.data;
      selfMemberInfo = userList?.firstWhereOrNull((e) => e.userID == selfModel.loginInfo?.userID);
      _notify();
    }
    return;
  }

  Future<void> loadGroupMemberList({required String groupID, int count = 100, String? seq}) async {
    final String? nextSeq = await _loadGroupMemberListFunction(groupID: groupID, seq: seq, count: count);
    if (nextSeq != null && nextSeq != "0" && nextSeq != "") {
      return await loadGroupMemberList(groupID: groupID, count: count, seq: nextSeq);
    } else {
      selfMemberInfo = groupMemberList?.firstWhereOrNull((e) => e?.userID == selfModel.loginInfo?.userID);
      _notify();
    }
  }

  void _notify() {
    try {
      notifyListeners();
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<V2TimMessage?> _invokeMessageWillSend(V2TimMessage message) async {
    final hook = lifeCycle?.messageWillSend;
    if (hook == null) {
      return message;
    }
    return await hook(message, _repliedMessage);
  }

  V2TimValueCallback<V2TimMessage> _buildBlockedResult(
      V2TimMessage message) {
    return V2TimValueCallback<V2TimMessage>(
      code: 1,
      desc: 'message blocked by lifecycle',
      data: message,
    );
  }

  Future<V2TimValueCallback<V2TimMessage>?> _processAndSendMessage({
    required V2TimMessage message,
    required String messageId,
    required String convID,
    required ConvType convType,
    OfflinePushInfo? offlinePushInfo,
    MessagePriorityEnum priority = MessagePriorityEnum.V2TIM_PRIORITY_NORMAL,
    bool? onlineUserOnly,
    bool? isExcludedFromUnreadCount,
    bool? needReadReceipt,
    String? cloudCustomData,
    String? localCustomData,
    bool? isExcludedFromContentModeration,
  }) async {
    final V2TimMessage? processed = await _invokeMessageWillSend(message);
    if (processed == null) {
      return null;
    }
    message = processed;
    final bool shouldSend =
        message.status == MessageStatus.V2TIM_MSG_STATUS_SENDING;

    List<V2TimMessage> currentHistoryMsgList = getOriginMessageList();
    if (globalModel.getMessageListPosition(conversationID) !=
        HistoryMessagePosition.notShowLatest) {
      currentHistoryMsgList = [message, ...currentHistoryMsgList];
      globalModel.setMessageList(conversationID, currentHistoryMsgList);
      _notify();
    }

    if (!shouldSend) {
      return _buildBlockedResult(message);
    }

    addSendingMessageID(messageId);
    return _sendMessage(
      convID: convID,
      id: messageId,
      convType: convType,
      messageInfo: message,
      offlinePushInfo: offlinePushInfo,
      priority: priority,
      onlineUserOnly: onlineUserOnly,
      isExcludedFromUnreadCount: isExcludedFromUnreadCount,
      needReadReceipt: needReadReceipt,
      cloudCustomData: cloudCustomData,
      localCustomData: localCustomData,
      isExcludedFromContentModeration: isExcludedFromContentModeration,
    );
  }

  Future<String?> _loadGroupMemberListFunction({required String groupID, int count = 100, String? seq}) async {
    if (seq == null || seq == "" || seq == "0") {
      groupMemberList?.clear();
    }
    try {
      final res = await _groupServices.getGroupMemberList(
          groupID: groupID,
          filter: GroupMemberFilterTypeEnum.V2TIM_GROUP_MEMBER_FILTER_ALL,
          count: count,
          nextSeq: seq ?? groupMemberListSeq);
      final groupMemberListRes = res.data;
      if (res.code == 0 && groupMemberListRes != null) {
        final groupMemberListTemp = groupMemberListRes.memberInfoList ?? [];
        groupMemberList = [...?groupMemberList, ...groupMemberListTemp];
        groupMemberListSeq = groupMemberListRes.nextSeq ?? "0";
      } else if (res.code == 10010) {
        isGroupExist = false;
      } else if (res.code == 10007) {
        isNotAMember = true;
      }
      return groupMemberListRes?.nextSeq;
    } catch (e) {
      return "";
    }
  }

  Future<(V2TimGroupInfo?, GroupReceiptAllowType?)> loadGroupInfo(String groupID) async {
    final groupInfoList = await _groupServices.getGroupsInfo(groupIDList: [groupID]);
    if (groupInfoList != null && groupInfoList.isNotEmpty) {
      final groupRes = groupInfoList.first;
      if (groupRes.resultCode == 0) {
        _groupInfo = groupRes.groupInfo;

        const groupTypeMap = {
          "Meeting": GroupReceiptAllowType.meeting,
          "Public": GroupReceiptAllowType.public,
          "Work": GroupReceiptAllowType.work
        };
        _groupType = groupTypeMap[groupRes.groupInfo?.groupType];

        _notify();
        return (_groupInfo, _groupType);
      }
    }
    return (null, null);
  }

  Future<void> updateMessageFromController({required String msgID, V2TimMessage? message}) async {
    V2TimMessage? newMessage = message ??
        await tools.getExistingMessageByID(
            msgID: msgID, conversationType: conversationType ?? ConvType.c2c, conversationID: conversationID);
    if (newMessage != null) {
      globalModel.onMessageModified(newMessage, conversationID);
    } else {
      loadChatRecord(
        count: HistoryMessageDartConstant.getCount,
      );
    }
  }

  Future<V2TimValueCallback<V2TimMessageChangeInfo>?> modifyMessage({required V2TimMessage message}) async {
    return _messageService.modifyMessage(message: message);
  }

  Future<V2TimValueCallback<V2TimMessage>> _sendMessage({
    required String id,
    required String convID,
    required ConvType convType,
    V2TimMessage? messageInfo,
    OfflinePushInfo? offlinePushInfo,
    bool? onlineUserOnly = false,
    MessagePriorityEnum priority = MessagePriorityEnum.V2TIM_PRIORITY_NORMAL,
    bool? isExcludedFromUnreadCount,
    bool? needReadReceipt,
    String? cloudCustomData,
    String? localCustomData,
    bool? isEditStatusMessage = false,
    bool? isExcludedFromContentModeration,
  }) async {
    String receiver = convType == ConvType.c2c ? convID : '';
    String groupID = convType == ConvType.group ? convID : '';
    if (convType == ConvType.group && _groupType == null) {
      await loadGroupInfo(groupID);
    }
    if (messageInfo != null) {
      setLoadingMessageMap(convID, messageInfo);
    }
    final sendMsgRes = await _messageService.sendMessage(
      priority: priority,
      localCustomData: localCustomData,
      isExcludedFromUnreadCount: isExcludedFromUnreadCount ?? false,
      id: id,
      receiver: receiver,
      needReadReceipt: needReadReceipt ?? chatConfig.isShowReadingStatus,
      groupID: groupID,
      offlinePushInfo: offlinePushInfo,
      onlineUserOnly: onlineUserOnly ?? false,
      isExcludedFromContentModeration: isExcludedFromContentModeration ?? false,
      cloudCustomData: cloudCustomData ??
          (showC2cMessageEditStatus == true
              ? json.encode({
                  "messageFeature": {
                    "needTyping": 1,
                    "version": 1,
                  }
                })
              : ""),
    );
    removeSendingMessageID(id);
    if (isEditStatusMessage == false &&
        globalModel.getMessageListPosition(conversationID) != HistoryMessagePosition.notShowLatest) {
      globalModel.updateMessage(sendMsgRes, convID, id, convType, groupType, setInputField);
    }
    if (lifeCycle?.messageDidSend != null) {
      lifeCycle!.messageDidSend(sendMsgRes);
    }

    return sendMsgRes;
  }

  List<V2TimMessage> getOriginMessageList() {
    return globalModel.messageListMap[conversationID] ?? [];
  }

  int getConversationUnreadCount() {
    return globalModel.unreadCountForTongue;
  }

  Future<V2TimValueCallback<V2TimMessage>?> sendTextAtMessage(
      {required String text,
      required String convID,
      required ConvType convType,
      required List<String> atUserList}) async {
    if (text.isEmpty) {
      return null;
    }
    final textATMessageInfo = await _messageService.createTextAtMessage(text: text, atUserList: atUserList);
    if (textATMessageInfo == null) {
      return null;
    }
    final V2TimMessage? messageInfo = textATMessageInfo.messageInfo;
    if (messageInfo == null) {
      return null;
    }
    final V2TimMessage message =
        tools.setUserInfoForMessage(messageInfo, textATMessageInfo.id!);
    message.status = MessageStatus.V2TIM_MSG_STATUS_SENDING;
    final Object? textAtRawId = textATMessageInfo.id;
    if (textAtRawId == null) {
      return null;
    }
    final String textAtMessageId = textAtRawId as String;
    return _processAndSendMessage(
      message: message,
      messageId: textAtMessageId,
      convID: convID,
      convType: ConvType.group,
      offlinePushInfo:
          tools.buildMessagePushInfo(textATMessageInfo.messageInfo!, convID, convType),
    );
  }

  Future<V2TimValueCallback<V2TimMessage>?> sendCustomMessage(
      {required String data, required String convID, required ConvType convType}) async {
    final customMessageInfo = await _messageService.createCustomMessage(data: data);
    if (customMessageInfo == null) {
      return null;
    }
    final V2TimMessage? messageInfo = customMessageInfo.messageInfo;
    if (messageInfo == null) {
      return null;
    }
    final V2TimMessage message =
        tools.setUserInfoForMessage(messageInfo, customMessageInfo.id!);
    message.status = MessageStatus.V2TIM_MSG_STATUS_SENDING;
    final Object? customRawId = customMessageInfo.id;
    if (customRawId == null) {
      return null;
    }
    final String customMessageId = customRawId as String;
    return _processAndSendMessage(
      message: message,
      messageId: customMessageId,
      convID: convID,
      convType: convType,
      offlinePushInfo:
          tools.buildMessagePushInfo(customMessageInfo.messageInfo!, convID, convType),
    );
  }

  Future<V2TimValueCallback<V2TimMessage>?> sendFaceMessage(
      {required int index, required String data, required String convID, required ConvType convType}) async {
    final faceMessageInfo = await _messageService.createFaceMessage(index: index, data: data);
    if (faceMessageInfo == null) {
      return null;
    }
    final V2TimMessage? messageInfo = faceMessageInfo.messageInfo;
    if (messageInfo == null) {
      return null;
    }
    final V2TimMessage message =
        tools.setUserInfoForMessage(messageInfo, faceMessageInfo.id!);
    message.status = MessageStatus.V2TIM_MSG_STATUS_SENDING;
    final Object? faceRawId = faceMessageInfo.id;
    if (faceRawId == null) {
      return null;
    }
    final String faceMessageId = faceRawId as String;
    return _processAndSendMessage(
      message: message,
      messageId: faceMessageId,
      convID: convID,
      convType: convType,
      offlinePushInfo:
          tools.buildMessagePushInfo(faceMessageInfo.messageInfo!, convID, convType),
    );
  }

  /// 发送语音消息（统一走 messageWillSend 生命周期，便于业务侧拦截发消息）。
  /// - 入参：
  ///   - [soundPath] 语音文件路径。
  ///   - [duration] 语音时长（秒）。
  ///   - [convID] 会话 ID。
  ///   - [convType] 会话类型（单聊/群聊）。
  /// - 返回：发送结果回调；若被生命周期拦截则返回 code=1 的结果且不会触发 SDK 发送。
  /// - 约束：若 messageWillSend 将 message.status 改为非 SENDING，则视为拦截，不再调用 _sendMessage。
  Future<V2TimValueCallback<V2TimMessage>?> sendSoundMessage({
    required String soundPath,
    required int duration,
    required String convID,
    required ConvType convType,
  }) async {
    final soundMessageInfo = await _messageService.createSoundMessage(
      soundPath: soundPath,
      duration: duration,
    );
    if (soundMessageInfo == null) {
      return null;
    }
    final V2TimMessage? messageInfo = soundMessageInfo.messageInfo;
    if (messageInfo == null) {
      return null;
    }
    final Object? soundRawId = soundMessageInfo.id;
    if (soundRawId == null) {
      return null;
    }
    final String soundMessageId = soundRawId as String;
    final V2TimMessage message =
        tools.setUserInfoForMessage(messageInfo, soundMessageId);
    message.status = MessageStatus.V2TIM_MSG_STATUS_SENDING;

    return _processAndSendMessage(
      message: message,
      messageId: soundMessageId,
      convID: convID,
      convType: convType,
      offlinePushInfo: tools.buildMessagePushInfo(message, convID, convType),
    );
  }

  Future<V2TimValueCallback<V2TimMessage>?> sendReplyMessage({
    required String text,
    required String convID,
    required ConvType convType,
    List<String>? atUserIDList,
  }) async {
    if (text.isEmpty) {
      return null;
    }
    if (_repliedMessage != null) {
      V2TimMsgCreateInfoResult? textMessageInfo = await _messageService.createTextMessage(text: text);
      if (atUserIDList != null && atUserIDList.isNotEmpty) {
        textMessageInfo = await _messageService.createTextAtMessage(text: text, atUserList: atUserIDList);
      }
      final V2TimMessage? messageInfo = textMessageInfo!.messageInfo;
      final receiver = convType == ConvType.c2c ? convID : '';
      final groupID = convType == ConvType.group ? convID : '';
      if (messageInfo != null) {
        V2TimMessage messageInfoWithSender = tools.setUserInfoForMessage(messageInfo, textMessageInfo.id!);
        messageInfoWithSender.status = MessageStatus.V2TIM_MSG_STATUS_SENDING;
        addSendingMessageID(messageInfo.id);
        final hasNickName = _repliedMessage?.nickName != null && _repliedMessage?.nickName != "";
        final cloudCustomData = {
          "messageReply": {
            "messageID": _repliedMessage!.msgID,
            "messageAbstract": tools.getMessageAbstract(_repliedMessage!, abstractMessageBuilder),
            "messageSender": hasNickName ? _repliedMessage!.nickName : _repliedMessage?.sender,
            "messageType": _repliedMessage?.elemType,
            "version": 1
          }
        };
        messageInfoWithSender.cloudCustomData = json.encode(cloudCustomData);
        List<V2TimMessage> currentHistoryMsgList = getOriginMessageList();
        currentHistoryMsgList = [messageInfoWithSender, ...currentHistoryMsgList];
        globalModel.setMessageList(conversationID, currentHistoryMsgList);

        _repliedMessage = null;
        final sendMsgRes = await _messageService.sendMessage(
            cloudCustomData:
                TencentUtils.checkString(messageInfoWithSender?.cloudCustomData) ?? json.encode(cloudCustomData),
            id: textMessageInfo.id as String,
            offlinePushInfo: tools.buildMessagePushInfo(messageInfoWithSender, convID, convType),
            needReadReceipt: chatConfig.isShowReadingStatus,
            groupID: groupID,
            receiver: receiver);
        _notify();
        globalModel.updateMessage(
            sendMsgRes, convID, messageInfoWithSender.id ?? "", convType, groupType, setInputField);
        if (lifeCycle?.messageDidSend != null) {
          lifeCycle!.messageDidSend(sendMsgRes);
        }
        return sendMsgRes;
      }
    }
    return null;
  }

  double getFileSize(File file) {
    int sizeInBytes = file.lengthSync();
    double sizeInMb = sizeInBytes / (1024 * 1024);
    return sizeInMb;
  }

  Future<String> getTempPath() async {
    final id = _uuid.v4();
    return getTemporaryDirectory().then((appDocDir) {
      String filePath = appDocDir.path + id + ".jpeg";
      return filePath;
    });
  }

  /// 解析本地图片宽高比，用于发送时稳定首帧布局尺寸。
  /// [imagePath] 本地图片路径。
  /// 返回：宽高比（width / height），解析失败返回 null。
  /// 业务约束：文件不存在、内容为空或宽高为 0 时返回 null。
  Future<double?> _resolveImageAspectRatio(String imagePath) async {
    try {
      final File file = File(imagePath);
      if (!file.existsSync()) {
        return null;
      }
      final Uint8List bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        return null;
      }
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frame = await codec.getNextFrame();
      final int width = frame.image.width;
      final int height = frame.image.height;
      frame.image.dispose();
      codec.dispose();
      if (width == 0 || height == 0) {
        return null;
      }
      return width / height;
    } catch (_) {
      return null;
    }
  }

  /// 合并图片消息本地自定义数据，补充宽高比字段。
  /// [origin] 原始 localCustomData 字符串；[aspectRatio] 预计算宽高比。
  /// 返回：合并后的 JSON 字符串；若宽高比无效则返回原值。
  /// 业务约束：origin 非 JSON 时会回退为仅包含宽高比的 JSON。
  String? _buildImageLocalCustomData({
    required String? origin,
    required double? aspectRatio,
  }) {
    if (aspectRatio == null || aspectRatio <= 0) {
      return origin;
    }
    try {
      final Map<String, dynamic> base = origin == null || origin.isEmpty
          ? <String, dynamic>{}
          : (json.decode(origin) as Map<String, dynamic>);
      base.putIfAbsent(
        HistoryMessageDartConstant.imgAspectRatioKey,
        () => aspectRatio,
      );
      return json.encode(base);
    } catch (_) {
      return json.encode(<String, dynamic>{
        HistoryMessageDartConstant.imgAspectRatioKey: aspectRatio,
      });
    }
  }

  /// 发送图片消息（统一走 messageWillSend 生命周期，便于业务侧拦截发消息）。
  /// - 入参：
  ///   - [imagePath] 本地图片路径（移动端使用）。
  ///   - [imageName] 图片文件名（可选）。
  ///   - [convID] 会话 ID。
  ///   - [inputElement] Web 侧输入元素（可选）。
  ///   - [convType] 会话类型（单聊/群聊）。
  ///   - [forceJpegCompress] 是否强制将图片重编码为 JPEG 后发送：
  ///     - 用途：统一“拍摄/相册”图片在各端的宽高与方向信息，
  ///       避免气泡按错误比例布局出现边缘缝隙。
  ///     - 约束：为避免破坏动图，gif 格式会忽略该开关，仍按原文件发送。
  ///   - 预处理：发送前会尝试写入图片宽高比到 localCustomData，
  ///     用于首帧占位稳定，避免图片突然放大。
  /// - 返回：发送结果回调；若被生命周期拦截则返回 code=1 的结果且不会触发 SDK 发送。
  /// - 约束：若 messageWillSend 将 message.status 改为非 SENDING，则视为拦截，不再调用 _sendMessage。
  Future<V2TimValueCallback<V2TimMessage>?> sendImageMessage(
      {String? imagePath,
      String? imageName,
      required String convID,
      dynamic inputElement,
      required ConvType convType,
      bool forceJpegCompress = false}) async {
    // 发送前可能生成的压缩图片路径，用于统一图片方向与大小。
    String? optimizedImagePath;
    if ((PlatformUtils().isAndroid || PlatformUtils().isIOS) &&
        imagePath != null &&
        imagePath.isNotEmpty) {
      try {
        final size = getFileSize(File(imagePath));
        final format = imagePath.split(".").last.toLowerCase();
        // 强制重编码为 JPEG：
        // - 用途：消除 EXIF 方向/宽高差异，统一拍摄图与相册图的渲染比例，
        //   避免 iOS 端出现 1px 级边缘缝隙。
        // - 约束：gif 需要保留动图能力，禁止重编码为 jpeg。
        final bool canReencodeToJpeg = format != "gif";
        if (canReencodeToJpeg &&
            (forceJpegCompress ||
                size > 20 ||
                (format != "jpg" && format != "png" && format != "gif"))) {
          final target = await getTempPath();
          final result = await FlutterImageCompress.compressAndGetFile(
            imagePath,
            target,
            format: CompressFormat.jpeg,
            quality: 85,
            keepExif: false,
            autoCorrectionAngle: true,
          );
          optimizedImagePath = result?.path;
        }
        // ignore: empty_catches
      } catch (e) {}
    }
    // 预计算图片宽高比，用于首帧布局稳定。
    double? aspectRatio;
    // 宽高比计算时优先使用压缩后的路径，保证方向信息一致。
    final String? ratioSourcePath = optimizedImagePath ?? imagePath;
    if ((PlatformUtils().isAndroid || PlatformUtils().isIOS) &&
        ratioSourcePath != null &&
        ratioSourcePath.isNotEmpty) {
      aspectRatio = await _resolveImageAspectRatio(ratioSourcePath);
    }
    final imageMessageInfo = await _messageService.createImageMessage(
      imageName: imageName,
      imagePath: optimizedImagePath ?? imagePath,
      inputElement: inputElement,
    );
    if (imageMessageInfo == null) {
      return null;
    }
    final V2TimMessage? messageInfo = imageMessageInfo.messageInfo;
    if (messageInfo == null) {
      return null;
    }
    final Object? imageRawId = imageMessageInfo.id;
    if (imageRawId == null) {
      return null;
    }
    final String imageMessageId = imageRawId as String;
    final V2TimMessage message =
        tools.setUserInfoForMessage(messageInfo, imageMessageId);
    message.status = MessageStatus.V2TIM_MSG_STATUS_SENDING;
    // 合并并写入宽高比字段，避免发送中占位尺寸跳变。
    final String? mergedLocalCustomData = _buildImageLocalCustomData(
      origin: message.localCustomData,
      aspectRatio: aspectRatio,
    );
    if (mergedLocalCustomData != null) {
      message.localCustomData = mergedLocalCustomData;
    }

    return _processAndSendMessage(
      message: message,
      messageId: imageMessageId,
      convID: convID,
      convType: convType,
      offlinePushInfo: tools.buildMessagePushInfo(message, convID, convType),
      localCustomData: mergedLocalCustomData,
    );
  }

  /// 发送视频消息（统一走 messageWillSend 生命周期，便于业务侧拦截发消息）。
  /// - 入参：
  ///   - [videoPath] 本地视频路径（移动端使用）。
  ///   - [duration] 视频时长（秒，可选）。
  ///   - [snapshotPath] 视频首帧截图路径（可选）。
  ///   - [convID] 会话 ID。
  ///   - [convType] 会话类型（单聊/群聊）。
  ///   - [inputElement] Web 侧输入元素（可选）。
  /// - 返回：发送结果回调；若被生命周期拦截则返回 code=1 的结果且不会触发 SDK 发送。
  /// - 约束：若 messageWillSend 将 message.status 改为非 SENDING，则视为拦截，不再调用 _sendMessage。
  Future<V2TimValueCallback<V2TimMessage>?> sendVideoMessage(
      {String? videoPath,
      int? duration,
      String? snapshotPath,
      required String convID,
      required ConvType convType,
      dynamic inputElement}) async {
    final String videoType =
        videoPath != null ? videoPath.split(".").last : 'mp4';
    final videoMessageInfo = await _messageService.createVideoMessage(
      videoPath: videoPath,
      type: videoType,
      duration: duration,
      inputElement: inputElement,
      snapshotPath: snapshotPath,
    );
    if (videoMessageInfo == null) {
      return null;
    }
    final V2TimMessage? messageInfo = videoMessageInfo.messageInfo;
    if (messageInfo == null) {
      return null;
    }
    final Object? videoRawId = videoMessageInfo.id;
    if (videoRawId == null) {
      return null;
    }
    final String videoMessageId = videoRawId as String;
    final V2TimMessage message =
        tools.setUserInfoForMessage(messageInfo, videoMessageId);
    message.status = MessageStatus.V2TIM_MSG_STATUS_SENDING;

    return _processAndSendMessage(
      message: message,
      messageId: videoMessageId,
      convID: convID,
      convType: convType,
      offlinePushInfo: tools.buildMessagePushInfo(message, convID, convType),
    );
  }

  Future<V2TimValueCallback<V2TimMessage>?> sendFileMessage(
      {String? filePath,
      String? fileName,
      int? size,
      dynamic inputElement,
      required String convID,
      required ConvType convType}) async {
    if (await tools.hasZeroSize(filePath ?? "")) {
      final CoreServicesImpl _coreServices = serviceLocator<CoreServicesImpl>();
      _coreServices.callOnCallback(
        TIMCallback(
          type: TIMCallbackType.INFO,
          infoRecommendText: "不支持 0KB 文件的传输",
          infoCode: 6660417,
        ),
      );
      return null;
    }
    final fileMessageInfo = await _messageService.createFileMessage(
        inputElement: inputElement, fileName: fileName ?? filePath?.split('/').last ?? "", filePath: filePath);
    List<V2TimMessage> currentHistoryMsgList = getOriginMessageList();
    final messageInfo = fileMessageInfo!.messageInfo;
    if (messageInfo != null) {
      final messageInfoWithSender = tools.setUserInfoForMessage(messageInfo, fileMessageInfo.id);
      messageInfoWithSender.status = MessageStatus.V2TIM_MSG_STATUS_SENDING;
      addSendingMessageID(messageInfo.id);
      messageInfoWithSender.fileElem!.fileSize = size;
      if (globalModel.getMessageListPosition(conversationID) != HistoryMessagePosition.notShowLatest) {
        currentHistoryMsgList = [messageInfoWithSender, ...currentHistoryMsgList];
        globalModel.setMessageList(conversationID, currentHistoryMsgList);
        _notify();
      }

      return _sendMessage(
        convID: convID,
        messageInfo: messageInfoWithSender,
        id: fileMessageInfo.id as String,
        convType: convType,
        offlinePushInfo: tools.buildMessagePushInfo(fileMessageInfo.messageInfo!, convID, convType),
      );
    }
    return null;
  }

  Future<V2TimValueCallback<V2TimMessage>?> sendLocationMessage(
      {required String desc,
      required double longitude,
      required double latitude,
      required String convID,
      required ConvType convType}) async {
    List<V2TimMessage> currentHistoryMsgList = getOriginMessageList();
    final locationMessageInfo =
        await _messageService.createLocationMessage(desc: desc, longitude: longitude, latitude: latitude);
    final messageInfo = locationMessageInfo!.messageInfo;
    if (messageInfo != null) {
      final messageInfoWithSender = tools.setUserInfoForMessage(messageInfo, locationMessageInfo.id);
      messageInfoWithSender.status = MessageStatus.V2TIM_MSG_STATUS_SENDING;
      addSendingMessageID(messageInfo.id);
      if (globalModel.getMessageListPosition(conversationID) != HistoryMessagePosition.notShowLatest) {
        currentHistoryMsgList = [messageInfoWithSender, ...currentHistoryMsgList];
        globalModel.setMessageList(conversationID, currentHistoryMsgList);
        _notify();
      }
      return _sendMessage(
        convID: convID,
        id: locationMessageInfo.id as String,
        convType: convType,
        offlinePushInfo: tools.buildMessagePushInfo(locationMessageInfo.messageInfo!, convID, convType),
      );
    }
    return null;
  }

  /// 逐条转发
  sendForwardMessage({
    required List<V2TimConversation> conversationList,
  }) async {
    final selectedMessages = getSelectedMessageList();
    for (var conversation in conversationList) {
      final convID = conversation.groupID ?? conversation.userID ?? "";
      final convType = conversation.type;
      List<V2TimMessage> currentHistoryMsgList = globalModel.messageListMap[conversationID] ?? [];
      for (var message in selectedMessages) {
        final forwardMessageInfo = await _messageService.createForwardMessage(msgID: message.msgID!);
        final messageInfo = forwardMessageInfo!.messageInfo;
        if (messageInfo != null) {
          tools.setUserInfoForMessage(messageInfo, forwardMessageInfo.id);
          messageInfo.status = MessageStatus.V2TIM_MSG_STATUS_SENDING;
          addSendingMessageID(messageInfo.id);
          // 如果转发的会话是当前会话，则直接添加到当前会话的消息列表中
          if (convID == conversationID) {
            if (globalModel.getMessageListPosition(convID) != HistoryMessagePosition.notShowLatest) {
              currentHistoryMsgList = [messageInfo, ...currentHistoryMsgList];
              globalModel.setMessageList(conversationID, currentHistoryMsgList);
              _notify();
            }
          }
          await Future.delayed(Duration(milliseconds: 100), () {
            _sendMessage(
              id: forwardMessageInfo.id!,
              convID: convID,
              convType: convType == 1 ? ConvType.c2c : ConvType.group,
              offlinePushInfo: tools.buildMessagePushInfo(
                  forwardMessageInfo.messageInfo!, convID, convType == 1 ? ConvType.c2c : ConvType.group),
            );
          });
        }
      }
    }
  }

  /// 合并转发
  Future<V2TimValueCallback<V2TimMessage>?> sendMergerMessage({
    required List<V2TimConversation> conversationList,
    required String title,
    required List<String> abstractList,
    required BuildContext context,
  }) async {
    final List<String> msgIDList =
        getSelectedMessageList().map((e) => e.msgID ?? "").where((element) => element != "").toList();
    for (var conversation in conversationList) {
      final convID = conversation.groupID ?? conversation.userID ?? "";
      final convType = conversation.type;
      List<V2TimMessage> currentHistoryMsgList = globalModel.messageListMap[conversationID] ?? [];
    final mergerMessageInfo = await _messageService.createMergerMessage(
      msgIDList: msgIDList,
      title: title,
      abstractList: abstractList,
      compatibleText: TIM_t("该版本不支持此消息"),
    );
      final messageInfo = mergerMessageInfo!.messageInfo;
      if (messageInfo != null) {
        tools.setUserInfoForMessage(messageInfo, mergerMessageInfo.id);
        messageInfo.status = MessageStatus.V2TIM_MSG_STATUS_SENDING;
        addSendingMessageID(messageInfo.id);
        // 如果转发的会话是当前会话，则直接添加到当前会话的消息列表中
        if (convID == conversationID) {
          if (globalModel.getMessageListPosition(convID) != HistoryMessagePosition.notShowLatest) {
            currentHistoryMsgList = [messageInfo, ...currentHistoryMsgList];
            globalModel.setMessageList(conversationID, currentHistoryMsgList);
            _notify();
          }
        }
        _sendMessage(
          id: mergerMessageInfo.id!,
          convID: convID,
          convType: convType == 1 ? ConvType.c2c : ConvType.group,
          offlinePushInfo: tools.buildMessagePushInfo(
              mergerMessageInfo.messageInfo!, convID, convType == 1 ? ConvType.c2c : ConvType.group),
        );
      }
    }
    return null;
  }

  Future<V2TimValueCallback<V2TimMessage>?> reSendFailMessage({
    required V2TimMessage message,
    required String convID,
    required ConvType convType,
  }) async {
    final List<V2TimMessage> currentHistoryMsgList = getOriginMessageList();
    if (currentHistoryMsgList.isEmpty) {
      return null;
    }

    final String? oldMsgID = message.msgID;
    final bool isGreetingBlocked = (message.localCustomInt ?? 0) == 90001;

    currentHistoryMsgList.removeWhere((element) => element.msgID == message.msgID);
    globalModel.setMessageList(convID, currentHistoryMsgList);
    await _deleteLocalMessage(oldMsgID);

    if (isGreetingBlocked) {
      return _reSendGreetingBlockedMessage(
        message: message,
        convID: convID,
        convType: convType,
        oldMsgID: oldMsgID,
      );
    }

    final V2TimValueCallback<V2TimMessage>? rebuilt =
        await _rebuildAndSendMessage(message: message, convID: convID, convType: convType);
    if (rebuilt != null) {
      return rebuilt;
    }

    return _fallbackResend(message, convID, 'unsupported resend type');
  }

  /// 处理被打招呼拦截的失败消息重发。
  /// [message] 为拦截失败的消息，[convID]/[convType] 为会话信息，
  /// [oldMsgID] 用于清理旧本地记录。
  /// 返回新的发送结果，如内容无法识别则复原原消息并返回失败结果。
  Future<V2TimValueCallback<V2TimMessage>?> _reSendGreetingBlockedMessage({
    required V2TimMessage message,
    required String convID,
    required ConvType convType,
    String? oldMsgID,
  }) async {
    final String? text = message.textElem?.text;
    if (text != null && text.trim().isNotEmpty) {
      await _deleteGreetingBlockedLocalMessage(oldMsgID);
      final result = await sendTextMessage(text: text, convID: convID, convType: convType);
      return result ?? _fallbackGreetingResend(message, convID);
    }

    final faceElem = message.faceElem;
    if (faceElem != null) {
      final String data = faceElem.data ?? '';
      final int? faceIndex = faceElem.index;
      if (data.isNotEmpty && faceIndex != null) {
        await _deleteGreetingBlockedLocalMessage(oldMsgID);
        final result = await sendFaceMessage(
          index: faceIndex,
          data: data,
          convID: convID,
          convType: convType,
        );
        return result ?? _fallbackGreetingResend(message, convID);
      }
    }

    final String? customData = message.customElem?.data;
    if (customData != null && customData.isNotEmpty) {
      await _deleteGreetingBlockedLocalMessage(oldMsgID);
      final result = await sendCustomMessage(
        data: customData,
        convID: convID,
        convType: convType,
      );
      return result ?? _fallbackGreetingResend(message, convID);
    }

    await _deleteGreetingBlockedLocalMessage(oldMsgID);
    return _fallbackGreetingResend(message, convID);
  }

  /// 删除失败消息的本地存储，避免刷新后再次出现。
  Future<void> _deleteLocalMessage(String? msgID) async {
    if (msgID == null || msgID.isEmpty) {
      return;
    }
    try {
      await _messageService.deleteMessages(
        msgIDs: [msgID],
        webMessageInstanceList: [],
      );
    } catch (error) {
      outputLogger.i('deleteLocalMessage failed: $error');
    }
  }

  /// 将失败消息拆解内容并重新发送；支持文本/表情/语音/自定义/视频，缺少资源时返回 null。
  Future<V2TimValueCallback<V2TimMessage>?> _rebuildAndSendMessage({
    required V2TimMessage message,
    required String convID,
    required ConvType convType,
  }) async {
    // 按消息类型依次尝试重发，命中后立即返回。
    final V2TimValueCallback<V2TimMessage>? textResult =
        await _reSendTextMessage(message, convID, convType);
    if (textResult != null) {
      return textResult;
    }

    final V2TimValueCallback<V2TimMessage>? faceResult =
        await _reSendFaceMessage(message, convID, convType);
    if (faceResult != null) {
      return faceResult;
    }

    final V2TimValueCallback<V2TimMessage>? soundResult =
        await _reSendSoundMessage(message, convID, convType);
    if (soundResult != null) {
      return soundResult;
    }

    final V2TimValueCallback<V2TimMessage>? videoResult =
        await _reSendVideoMessage(
      videoElem: message.videoElem,
      convID: convID,
      convType: convType,
    );
    if (videoResult != null) {
      return videoResult;
    }

    final V2TimValueCallback<V2TimMessage>? customResult =
        await _reSendCustomMessage(message, convID, convType);
    if (customResult != null) {
      return customResult;
    }

    return null;
  }

  /// 重发文本消息，兼容被回复场景；文本内容为空时返回 null。
  /// [message] 失败的原始消息，用于提取文本与回复信息。
  /// [convID]/[convType] 指定会话上下文。
  Future<V2TimValueCallback<V2TimMessage>?> _reSendTextMessage(
    V2TimMessage message,
    String convID,
    ConvType convType,
  ) async {
    final String? text = message.textElem?.text;
    if (text == null || text.trim().isEmpty) {
      return null;
    }
    final String? replyMsgId = _parseReplyMsgId(message.cloudCustomData);
    if (replyMsgId != null && replyMsgId.isNotEmpty) {
      final V2TimMessage? replied = await findMessage(replyMsgId);
      if (replied != null) {
        _repliedMessage = replied;
        final V2TimValueCallback<V2TimMessage>? replyResult =
            await sendReplyMessage(text: text, convID: convID, convType: convType);
        _repliedMessage = null;
        if (replyResult != null) {
          return replyResult;
        }
      }
    }
    return await sendTextMessage(text: text, convID: convID, convType: convType);
  }

  /// 重发表情消息，缺少索引或数据时返回 null。
  /// [message] 原始失败消息。
  /// [convID]/[convType] 当前会话信息。
  Future<V2TimValueCallback<V2TimMessage>?> _reSendFaceMessage(
    V2TimMessage message,
    String convID,
    ConvType convType,
  ) async {
    final faceElem = message.faceElem;
    if (faceElem == null) {
      return null;
    }
    final String data = faceElem.data ?? '';
    final int? faceIndex = faceElem.index;
    if (data.isEmpty || faceIndex == null) {
      return null;
    }
    return await sendFaceMessage(
      index: faceIndex,
      data: data,
      convID: convID,
      convType: convType,
    );
  }

  /// 重发语音消息，需本地路径存在，否则返回 null。
  /// [message] 原始失败语音消息。
  /// [convID]/[convType] 当前会话标识。
  Future<V2TimValueCallback<V2TimMessage>?> _reSendSoundMessage(
    V2TimMessage message,
    String convID,
    ConvType convType,
  ) async {
    final soundElem = message.soundElem;
    if (soundElem == null) {
      return null;
    }
    final String soundPath =
        (soundElem.path ?? soundElem.localUrl ?? soundElem.url ?? '').trim();
    if (soundPath.isEmpty) {
      return null;
    }
    final int rawDuration = soundElem.duration ?? 0;
    final int duration = rawDuration > 0 ? rawDuration : 1;
    return await sendSoundMessage(
      soundPath: soundPath,
      duration: duration,
      convID: convID,
      convType: convType,
    );
  }

  /// 重发自定义消息，缺少数据时返回 null。
  /// [message] 失败的自定义消息。
  /// [convID]/[convType] 当前会话标识。
  Future<V2TimValueCallback<V2TimMessage>?> _reSendCustomMessage(
    V2TimMessage message,
    String convID,
    ConvType convType,
  ) async {
    final String? customData = message.customElem?.data;
    if (customData == null || customData.isEmpty) {
      return null;
    }
    return await sendCustomMessage(
      data: customData,
      convID: convID,
      convType: convType,
    );
  }

  /// 基于失败消息中的视频元素重建并发送视频，缺少本地文件或元素为空时返回 null。
  /// [videoElem] 失败消息携带的视频元素，用于提取本地资源。
  /// [convID]/[convType] 指当前会话标识，确保重发走对的目标。
  Future<V2TimValueCallback<V2TimMessage>?> _reSendVideoMessage({
    required V2TimVideoElem? videoElem,
    required String convID,
    required ConvType convType,
  }) async {
    if (videoElem == null) {
      return null;
    }
    final String videoPath = _resolveResendVideoPath(videoElem);
    final String snapshotPath = _resolveResendSnapshotPath(videoElem);
    if (videoPath.isEmpty || snapshotPath.isEmpty) {
      return null;
    }
    if (!File(videoPath).existsSync() || !File(snapshotPath).existsSync()) {
      return null;
    }
    final int durationSeconds = _normalizeVideoDurationSeconds(videoElem.duration);
    return await sendVideoMessage(
      videoPath: videoPath,
      duration: durationSeconds,
      snapshotPath: snapshotPath,
      convID: convID,
      convType: convType,
    );
  }

  /// 解析失败视频消息的本地视频路径，优先发送时的路径，其次下载缓存。
  /// [videoElem] 视频元素，包含本地路径字段。
  /// 返回可用于重发的本地视频路径，缺失时返回空字符串。
  String _resolveResendVideoPath(V2TimVideoElem videoElem) {
    final String primaryPath = (videoElem.videoPath ?? '').trim();
    if (primaryPath.isNotEmpty) {
      return primaryPath;
    }
    final String cachedPath = (videoElem.localVideoUrl ?? '').trim();
    if (cachedPath.isNotEmpty) {
      return cachedPath;
    }
    return '';
  }

  /// 解析失败视频消息的封面路径，保障 SDK 重发必需的缩略图文件。
  /// [videoElem] 视频元素，包含发送时或下载后的封面路径。
  /// 返回存在的本地封面路径，缺失时返回空字符串。
  String _resolveResendSnapshotPath(V2TimVideoElem videoElem) {
    final String primarySnapshot = (videoElem.snapshotPath ?? '').trim();
    if (primarySnapshot.isNotEmpty) {
      return primarySnapshot;
    }
    final String cachedSnapshot = (videoElem.localSnapshotUrl ?? '').trim();
    if (cachedSnapshot.isNotEmpty) {
      return cachedSnapshot;
    }
    return '';
  }

  /// 规范化视频重发的时长，单位秒，避免 0 秒导致 SDK 报错。
  /// [duration] 视频原始时长（秒），为空或非正数时兜底为 1。
  int _normalizeVideoDurationSeconds(int? duration) {
    if (duration == null || duration <= 0) {
      return 1;
    }
    return duration;
  }

  V2TimValueCallback<V2TimMessage> _fallbackResend(
    V2TimMessage message,
    String convID,
    String desc,
  ) {
    final List<V2TimMessage> fallbackList = getOriginMessageList();
    globalModel.setMessageList(convID, [message, ...fallbackList]);
    return V2TimValueCallback<V2TimMessage>(
      code: 1,
      desc: desc,
      data: message,
    );
  }

  String? _parseReplyMsgId(String? cloudCustomData) {
    if (cloudCustomData == null || cloudCustomData.isEmpty) {
      return null;
    }
    try {
      final Map<String, dynamic> data =
          json.decode(cloudCustomData) as Map<String, dynamic>;
      final Object? reply = data['messageReply'];
      if (reply is Map<String, dynamic>) {
        final Object? msgId = reply['messageID'];
        if (msgId is String && msgId.isNotEmpty) {
          return msgId;
        }
      }
    } catch (_) {}
    return null;
  }

  /// 删除被拦截消息的本地记录，防止刷新后重新出现。
  /// [msgID] 为需要清理的本地消息 ID，空则跳过处理。
  Future<void> _deleteGreetingBlockedLocalMessage(String? msgID) async {
    if (msgID == null || msgID.isEmpty) {
      return;
    }
    await _messageService.deleteMessages(
      msgIDs: [msgID],
      webMessageInstanceList: [],
    );
  }

  /// 构建打招呼拦截重发失败的兜底结果，并把原消息重新插回列表。
  /// [message] 指原始失败消息，[convID] 为对应的会话 ID。
  /// 返回包装后的失败结果供上层处理。
  V2TimValueCallback<V2TimMessage> _fallbackGreetingResend(
    V2TimMessage message,
    String convID,
  ) {
    final List<V2TimMessage> fallbackList = getOriginMessageList();
    globalModel.setMessageList(convID, [message, ...fallbackList]);
    return V2TimValueCallback<V2TimMessage>(
      code: 1,
      desc: 'unsupported greeting blocked resend',
      data: message,
    );
  }

  Future<V2TimValueCallback<V2TimMessage>?> sendTextMessage(
      {required String text, required String convID, required ConvType convType}) async {
    if (text.isEmpty) {
      return null;
    }
    final textMessageInfo = await _messageService.createTextMessage(text: text);
    if (textMessageInfo == null) {
      return null;
    }
    final V2TimMessage? messageInfo = textMessageInfo.messageInfo;
    if (messageInfo == null) {
      return null;
    }
    final V2TimMessage message =
        tools.setUserInfoForMessage(messageInfo, textMessageInfo.id!);
    message.status = MessageStatus.V2TIM_MSG_STATUS_SENDING;
    final Object? textRawId = textMessageInfo.id;
    if (textRawId == null) {
      return null;
    }
    final String textMessageId = textRawId as String;
    return _processAndSendMessage(
      message: message,
      messageId: textMessageId,
      convID: convID,
      convType: convType,
      offlinePushInfo:
          tools.buildMessagePushInfo(textMessageInfo.messageInfo!, convID, convType),
    );
  }

  Future<V2TimValueCallback<V2TimMessage>?>? sendMessageFromController({
    required V2TimMessage? messageInfo,

    /// Offline push info
    OfflinePushInfo? offlinePushInfo,
    MessagePriorityEnum priority = MessagePriorityEnum.V2TIM_PRIORITY_NORMAL,
    bool? onlineUserOnly,
    bool? isExcludedFromUnreadCount,
    bool? needReadReceipt,
    String? cloudCustomData,
    String? localCustomData,
  }) {
    if (messageInfo == null) {
      return null;
    }
    final V2TimMessage messageWithSender =
        messageInfo.sender == null ? tools.setUserInfoForMessage(messageInfo, messageInfo.id!) : messageInfo;
    messageWithSender.status = MessageStatus.V2TIM_MSG_STATUS_SENDING;
    final String? messageId = messageWithSender.id;
    if (messageId == null || messageId.isEmpty) {
      return null;
    }
    return _processAndSendMessage(
      message: messageWithSender,
      messageId: messageId,
      convID: conversationID,
      convType: conversationType ?? ConvType.c2c,
      offlinePushInfo: offlinePushInfo ??
          tools.buildMessagePushInfo(messageWithSender, conversationID, conversationType ?? ConvType.c2c),
      priority: priority,
      onlineUserOnly: onlineUserOnly,
      isExcludedFromUnreadCount: isExcludedFromUnreadCount,
      needReadReceipt: needReadReceipt,
      cloudCustomData: cloudCustomData,
      localCustomData: localCustomData,
      isExcludedFromContentModeration: messageWithSender.isExcludedFromContentModeration,
    );
  }

  deleteMsg(String msgID, {String? id, Object? webMessageInstance}) async {
    if (lifeCycle?.shouldDeleteMessage != null && await lifeCycle!.shouldDeleteMessage(msgID) == false) {
      return;
    }
    final messageList = getOriginMessageList();
    final res = await _messageService.deleteMessages(msgIDs: [msgID], webMessageInstanceList: [webMessageInstance]);
    if (res.code == 0) {
      messageList.removeWhere((element) {
        return element.msgID == msgID || (id != null && element.id == id);
      });
    }
    globalModel.setMessageList(conversationID, messageList);
  }

  clearHistory() async {
    if (lifeCycle?.shouldClearHistoricalMessageList != null &&
        await lifeCycle!.shouldClearHistoricalMessageList(conversationID) == false) {
      return;
    }
    globalModel.setMessageList(conversationID, []);
  }

  Future<Object?> revokeMsg(String msgID, bool isAdmin, [Object? webMessageInstance]) async {
    if (chatConfig.isGroupAdminRecallEnabled) {
      final V2TimMessage? message =
          globalModel.messageListMap[conversationID]?.firstWhere((element) => element.msgID == msgID);
      if (message != null) {
        if (PlatformUtils().isWeb) {
          final decodedMessage = jsonDecode(message.messageFromWeb!);
          decodedMessage["cloudCustomData"] = jsonEncode({"isRevoke": true, "revokeByAdmin": isAdmin});
          message.messageFromWeb = jsonEncode(decodedMessage);
        } else {
          message.cloudCustomData = jsonEncode({"isRevoke": true, "revokeByAdmin": isAdmin});
        }
        return await modifyMessage(message: message);
      }
    }

    final res = await _messageService.revokeMessage(msgID: msgID, webMessageInstance: webMessageInstance);
    if (res.code == 0) {
      globalModel.onMessageRevoked(msgID, conversationID);
    }
    return res;
  }

  setMessageItemChecked(V2TimMessage message, bool isChecked) {
    if (message.msgID != null) {
      _selectedPositions[message.msgID!] = isChecked;
    }

    _notify();
  }

  deleteSelectedMsg() async {
    List<V2TimMessage> messageList = getOriginMessageList();
    final msgIDs = getSelectedMessageIDList();
    final webMessageInstanceList = getSelectedMessageIDList();

    final res = await _messageService.deleteMessages(msgIDs: msgIDs, webMessageInstanceList: webMessageInstanceList);
    if (res.code == 0) {
      for (var msgID in msgIDs) {
        messageList.removeWhere((element) => element.msgID == msgID);
      }
      globalModel.setMessageList(conversationID, messageList, isDeleteMsg: true);
    }
  }

  updateMultiSelectStatus(bool isSelect) {
    _isMultiSelect = isSelect;
    if (!isSelect) {
      _selectedPositions.clear();
    }
    _notify();
  }

  Future<V2TimValueCallback<V2TimGroupMessageReadMemberList>> getGroupMessageReadMemberList(
      String messageID, GetGroupMessageReadMemberListFilter fileter, int nextSeq) async {
    final res =
        await _messageService.getGroupMessageReadMemberList(nextSeq: nextSeq, messageID: messageID, filter: fileter);
    return res;
  }

  Future<List<V2TimMessage>?> downloadMergerMessage(String msgID) async {
    await _messageService.getHistoryMessageList(
      count: 100,
      getType: HistoryMsgGetTypeEnum.V2TIM_GET_CLOUD_OLDER_MSG,
      userID: conversationType == ConvType.c2c ? conversationID : null,
      groupID: conversationType == ConvType.group ? conversationID : null,
    );
    return _messageService.downloadMergerMessage(msgID: msgID);
  }

  Future<V2TimMessage?> findMessage(String msgID) async {
    List<V2TimMessage> messageList = getOriginMessageList();
    final repliedMessage = messageList.where((element) => element.msgID == msgID).toList();
    if (repliedMessage.isNotEmpty) {
      return repliedMessage.first;
    }
    final message = await _messageService.findMessages(messageIDList: [msgID]);
    if (message != null && message.isNotEmpty) {
      return message.first;
    }
    return null;
  }

  showLatestUnread() {
    globalModel.unreadCountForTongue = 0;
    markMessageAsRead();
    globalModel.setMessageListPosition(conversationID, HistoryMessagePosition.bottom);
  }

  // 添加发送中的消息的 id 或者 msgID(id 不存在时使用 msgID)
  void addSendingMessageID(String? id) {
    if (id?.isNotEmpty == true) {
      _sendingMessageIDMap[id!] = false;
    }
  }

  // 移除发送中的消息的 id 或者 msgID(id 不存在时使用 msgID)
  void removeSendingMessageID(String id) {
    _sendingMessageIDMap.remove(id);
  }

  // 是否已经延迟渲染
  bool? hasDelayedRenderSendingStatus(String id) {
    if (_sendingMessageIDMap.containsKey(id)) {
      return _sendingMessageIDMap[id];
    }

    return true;
  }

  // 设置已经延迟渲染过的消息
  void setDelayedRenderSendingStatus(String id) {
    if (_sendingMessageIDMap.containsKey(id)) {
      _sendingMessageIDMap[id] = true;
    }
  }

  bool isVoteMessage(V2TimMessage message) {
    bool isVote = false;
    V2TimCustomElem? custom = message.customElem;

    if (custom != null) {
      String? data = custom.data;
      if (data != null && data.isNotEmpty) {
        try {
          Map<String, dynamic> mapData = json.decode(data);
          if (mapData["businessID"] == "group_poll") {
            isVote = true;
          }
        } catch (err) {
          // err
        }
      }
    }
    return isVote;
  }

  @override
  void dispose() {
    markMessageAsRead();
    final TUIChatGlobalModel global = globalModel;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      global.unreadCountForTongue = 0;
    });
    global.clearCurrentConversation();
    _isInit = false;
    super.dispose();
  }
}
