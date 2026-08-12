import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';

// =====================================================
// 程式入口
// =====================================================

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

// =====================================================
// App
// =====================================================

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Calculator',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const CalculatorPage(),
    );
  }
}

// =====================================================
// 計算機
// =====================================================

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key});

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  String _display = '0';
  String _expression = '';

  // ⭐ 聊天室密碼改為 7766%
  String _secretInput = '';

  double? _firstNumber;
  String? _operator;
  bool _shouldResetDisplay = false;

  bool _checkingSavedUser = true;
  String? _savedUserId;

  @override
  void initState() {
    super.initState();
    _loadSavedUser();
  }

  // =====================================================
  // 讀取設備使用者
  // =====================================================

  Future<void> _loadSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUser = prefs.getString('device_user_id');

    if (!mounted) {
      return;
    }

    setState(() {
      _savedUserId = savedUser;
      _checkingSavedUser = false;
    });
  }

  // =====================================================
  // 儲存設備使用者
  // =====================================================

  Future<void> _saveUser(String userId) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('device_user_id', userId);

    if (!mounted) {
      return;
    }

    setState(() {
      _savedUserId = userId;
    });
  }

  // =====================================================
  // 使用者名稱
  // =====================================================

  String _userName(String userId) {
    if (userId == 'user1') {
      return '使用者 1';
    }

    return '使用者 2';
  }

  // =====================================================
  // 選擇使用者
  // =====================================================

  Future<String?> _chooseUser() async {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('選擇使用者'),
          content: const Text(
            '第一次使用此設備，請選擇使用者。\n'
            '選擇後此設備會記住你的使用者。',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, 'user1');
              },
              child: const Text('使用者 1'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, 'user2');
              },
              child: const Text('使用者 2'),
            ),
          ],
        );
      },
    );
  }

  // =====================================================
  // 進入聊天室
  // =====================================================

  Future<void> _openChat() async {
    if (_checkingSavedUser) {
      return;
    }

    String? userId = _savedUserId;

    if (userId == null) {
      userId = await _chooseUser();

      if (userId == null) {
        return;
      }

      await _saveUser(userId);
    }

    if (!mounted) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) {
          return ChatPage(
            userId: userId!,
            userName: _userName(userId!),
            onLeaveChat: () async {},
          );
        },
      ),
    );
  }

  // =====================================================
  // 格式化數字
  // =====================================================

  String _formatNumber(double number) {
    if (number.isNaN || number.isInfinite) {
      return '錯誤';
    }

    if (number == number.truncateToDouble()) {
      return number.toInt().toString();
    }

    String result = number.toStringAsFixed(10);

    result = result.replaceFirst(RegExp(r'0+$'), '');
    result = result.replaceFirst(RegExp(r'\.$'), '');

    return result;
  }

  // =====================================================
  // 輸入數字
  // =====================================================

  void _inputNumber(String value) {
    if (_display == '錯誤') {
      _display = value;
      _expression = value;
      _shouldResetDisplay = false;
      return;
    }

    if (_shouldResetDisplay || _display == '0') {
      _display = value;
      _shouldResetDisplay = false;
    } else {
      _display += value;
    }

    if (_operator != null && _firstNumber != null) {
      final operatorText = _operator!;
      final firstText = _formatNumber(_firstNumber!);

      _expression = '$firstText $operatorText $_display';
    } else {
      _expression = _display;
    }
  }

  // =====================================================
  // 小數
  // =====================================================

  void _inputDecimal() {
    if (_display == '錯誤') {
      _display = '0.';
      _expression = '0.';
      _shouldResetDisplay = false;
      return;
    }

    if (_shouldResetDisplay) {
      _display = '0.';
      _shouldResetDisplay = false;

      if (_operator != null && _firstNumber != null) {
        _expression = '${_formatNumber(_firstNumber!)} $_operator 0.';
      } else {
        _expression = '0.';
      }

      return;
    }

    if (!_display.contains('.')) {
      _display += '.';

      if (_operator != null && _firstNumber != null) {
        _expression = '${_formatNumber(_firstNumber!)} $_operator $_display';
      } else {
        _expression = _display;
      }
    }
  }

  // =====================================================
  // 運算
  // =====================================================

  void _setOperator(String operator) {
    final currentNumber = double.tryParse(_display);

    if (currentNumber == null) {
      return;
    }

    if (_firstNumber != null && _operator != null) {
      _calculate();

      final result = double.tryParse(_display);

      if (result != null) {
        _firstNumber = result;
      }
    } else {
      _firstNumber = currentNumber;
    }

    _operator = operator;
    _shouldResetDisplay = true;

    _expression = '${_formatNumber(_firstNumber!)} $operator';
  }

  // =====================================================
  // 計算
  // =====================================================

  void _calculate() {
    if (_firstNumber == null || _operator == null) {
      return;
    }

    final secondNumber = double.tryParse(_display);

    if (secondNumber == null) {
      return;
    }

    final firstNumber = _firstNumber!;
    final operator = _operator!;

    double result;

    switch (operator) {
      case '+':
        result = firstNumber + secondNumber;
        break;

      case '-':
        result = firstNumber - secondNumber;
        break;

      case '×':
        result = firstNumber * secondNumber;
        break;

      case '÷':
        if (secondNumber == 0) {
          _display = '錯誤';
          _expression = '錯誤';
          _firstNumber = null;
          _operator = null;
          _shouldResetDisplay = true;
          return;
        }

        result = firstNumber / secondNumber;
        break;

      default:
        return;
    }

    _expression =
        '${_formatNumber(firstNumber)} $operator ${_formatNumber(secondNumber)}';

    _display = _formatNumber(result);

    _firstNumber = null;
    _operator = null;
    _shouldResetDisplay = true;
  }

  // =====================================================
  // 正負
  // =====================================================

  void _toggleSign() {
    if (_display == '0' || _display == '錯誤') {
      return;
    }

    if (_display.startsWith('-')) {
      _display = _display.substring(1);
    } else {
      _display = '-$_display';
    }

    if (_operator != null && _firstNumber != null) {
      _expression = '${_formatNumber(_firstNumber!)} $_operator $_display';
    } else {
      _expression = _display;
    }
  }

  // =====================================================
  // 百分比
  // =====================================================

  void _percentage() {
    final number = double.tryParse(_display);

    if (number == null) {
      return;
    }

    _display = _formatNumber(number / 100);

    if (_operator != null && _firstNumber != null) {
      _expression = '${_formatNumber(_firstNumber!)} $_operator $_display';
    } else {
      _expression = _display;
    }
  }

  // =====================================================
  // AC
  // =====================================================

  void _clear() {
    _display = '0';
    _expression = '';
    _firstNumber = null;
    _operator = null;
    _shouldResetDisplay = false;
    _secretInput = '';
  }

  // =====================================================
  // 按鍵
  // =====================================================

  void _press(String value) {
    if (value == 'AC') {
      setState(() {
        _clear();
      });
      return;
    }

    if ('0123456789'.contains(value)) {
      setState(() {
        _inputNumber(value);

        _secretInput += value;

        if (_secretInput.length > 5) {
          _secretInput = _secretInput.substring(_secretInput.length - 5);
        }
      });

      return;
    }

    if (value == '.') {
      setState(() {
        _inputDecimal();
      });
      return;
    }

    if (value == '±') {
      setState(() {
        _toggleSign();
      });
      return;
    }

    if (value == '%') {
      setState(() {
        _percentage();

        // ⭐ 7766%
        if (_secretInput == '7766') {
          _secretInput = '7766%';
        }
      });

      if (_secretInput == '7766%') {
        _checkSecretCode();
      }

      return;
    }

    if (value == '+' || value == '-' || value == '×' || value == '÷') {
      setState(() {
        _setOperator(value);
      });
      return;
    }

    if (value == '=') {
      setState(() {
        _calculate();
      });
      return;
    }
  }

  // =====================================================
  // 7766%
  // =====================================================

  Future<void> _checkSecretCode() async {
    if (_secretInput == '7766%') {
      setState(() {
        _display = '0';
        _expression = '';
        _secretInput = '';
        _firstNumber = null;
        _operator = null;
        _shouldResetDisplay = false;
      });

      await _openChat();

      return;
    }

    setState(() {
      _secretInput = '';
    });
  }

  // =====================================================
  // 計算機按鈕
  // =====================================================

  Widget _calculatorButton(
    String text, {
    bool dark = false,
    bool orange = false,
    bool wide = false,
  }) {
    final bool isSelectedOperator = orange && _operator == text;

    return Expanded(
      flex: wide ? 2 : 1,
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: SizedBox(
          height: 75,
          child: ElevatedButton(
            onPressed: () {
              _press(text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isSelectedOperator
                  ? Colors.white
                  : orange
                  ? Colors.orange
                  : dark
                  ? const Color(0xFF333333)
                  : const Color(0xFFA5A5A5),
              foregroundColor: isSelectedOperator
                  ? Colors.orange
                  : orange || dark
                  ? Colors.white
                  : Colors.black,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(40),
              ),
              padding: EdgeInsets.zero,
            ),
            child: Text(
              text,
              style: TextStyle(
                fontSize: text == 'AC' ? 25 : 28,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // =====================================================
  // 計算機畫面
  // =====================================================

  @override
  Widget build(BuildContext context) {
    if (_checkingSavedUser) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text(
          '計算機',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Column(
                children: [
                  Expanded(
                    flex: 3,
                    child: Container(
                      width: double.infinity,
                      alignment: Alignment.bottomRight,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (_expression.isNotEmpty)
                            SizedBox(
                              width: double.infinity,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerRight,
                                child: Text(
                                  _expression,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 30,
                                    fontWeight: FontWeight.w300,
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(height: 4),
                          SizedBox(
                            width: double.infinity,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: Text(
                                _display,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 72,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 5,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            _calculatorButton('AC'),
                            _calculatorButton('±'),
                            _calculatorButton('%'),
                            _calculatorButton('÷', orange: true),
                          ],
                        ),
                        Row(
                          children: [
                            _calculatorButton('7', dark: true),
                            _calculatorButton('8', dark: true),
                            _calculatorButton('9', dark: true),
                            _calculatorButton('×', orange: true),
                          ],
                        ),
                        Row(
                          children: [
                            _calculatorButton('4', dark: true),
                            _calculatorButton('5', dark: true),
                            _calculatorButton('6', dark: true),
                            _calculatorButton('-', orange: true),
                          ],
                        ),
                        Row(
                          children: [
                            _calculatorButton('1', dark: true),
                            _calculatorButton('2', dark: true),
                            _calculatorButton('3', dark: true),
                            _calculatorButton('+', orange: true),
                          ],
                        ),
                        Row(
                          children: [
                            _calculatorButton('0', dark: true, wide: true),
                            _calculatorButton('.', dark: true),
                            _calculatorButton('=', orange: true),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =====================================================
// 聊天室
// =====================================================

class ChatPage extends StatefulWidget {
  final String userId;
  final String userName;
  final Future<void> Function() onLeaveChat;

  const ChatPage({
    super.key,
    required this.userId,
    required this.userName,
    required this.onLeaveChat,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();

  final ScrollController _scrollController = ScrollController();

  final CollectionReference<Map<String, dynamic>> messagesRef =
      FirebaseFirestore.instance.collection('messages');

  final CollectionReference<Map<String, dynamic>> onlineUsersRef =
      FirebaseFirestore.instance.collection('online_users');

  Timer? _heartbeatTimer;
  Timer? _inactivityTimer;

  // ⭐ 每 5 秒重新判斷對方是否仍在線
  Timer? _onlineCheckTimer;

  bool _leaving = false;

  static const Duration inactivityDuration = Duration(minutes: 5);

  final Map<String, GlobalKey> _messageKeys = <String, GlobalKey>{};

  bool _checkingVisibleMessages = false;

  String get _otherUserId => widget.userId == 'user1' ? 'user2' : 'user1';

  String get _otherUserName => widget.userId == 'user1' ? '使用者 2' : '使用者 1';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _scrollController.addListener(_onScroll);

    _startHeartbeat();

    // ⭐ 每 5 秒刷新一次畫面
    _onlineCheckTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted && !_leaving) {
        setState(() {});
      }
    });

    _resetInactivityTimer();
  }

  // =====================================================
  // Scroll
  // =====================================================

  void _onScroll() {
    _onUserActivity();
    _scheduleCheckVisibleMessages();
  }

  void _scheduleCheckVisibleMessages() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _leaving) {
        return;
      }

      _markVisibleMessagesAsRead();
    });
  }

  // =====================================================
  // 使用者操作
  // =====================================================

  void _resetInactivityTimer() {
    if (_leaving) {
      return;
    }

    _inactivityTimer?.cancel();

    _inactivityTimer = Timer(inactivityDuration, _autoLogout);
  }

  void _onUserActivity() {
    _resetInactivityTimer();
  }

  // =====================================================
  // 5 分鐘沒有操作
  // =====================================================

  Future<void> _autoLogout() async {
    if (_leaving) {
      return;
    }

    await _leaveChat(showMessage: true);
  }

  // =====================================================
  // 在線心跳
  // =====================================================

  void _startHeartbeat() {
    _updateOnlineStatus();

    _heartbeatTimer?.cancel();

    _heartbeatTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (!_leaving) {
        _updateOnlineStatus();
      }
    });
  }

  Future<void> _updateOnlineStatus() async {
    if (_leaving) {
      return;
    }

    try {
      await onlineUsersRef.doc(widget.userId).set({
        'userId': widget.userId,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  // =====================================================
  // App 背景 / 前景
  // =====================================================

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_leaving) {
      return;
    }

    if (state == AppLifecycleState.resumed) {
      _startHeartbeat();
      _resetInactivityTimer();
      _scheduleCheckVisibleMessages();
    }
  }

  // =====================================================
  // Dispose
  // =====================================================

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _heartbeatTimer?.cancel();
    _inactivityTimer?.cancel();
    _onlineCheckTimer?.cancel();

    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();

    _releaseUser();

    _messageController.dispose();

    super.dispose();
  }

  // =====================================================
  // 釋放在線狀態
  // =====================================================

  Future<void> _releaseUser() async {
    _heartbeatTimer?.cancel();

    try {
      await onlineUsersRef.doc(widget.userId).delete();
    } catch (_) {}
  }

  // =====================================================
  // 離開聊天室
  // =====================================================

  Future<void> _leaveChat({bool showMessage = false}) async {
    if (_leaving) {
      return;
    }

    _leaving = true;

    _heartbeatTimer?.cancel();
    _inactivityTimer?.cancel();
    _onlineCheckTimer?.cancel();

    try {
      await onlineUsersRef.doc(widget.userId).delete();
    } catch (_) {}

    await widget.onLeaveChat();

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop();

    if (showMessage) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (!mounted) {
          return;
        }

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('5 分鐘沒有操作，已回到計算機')));
      });
    }
  }

  // =====================================================
  // 傳送訊息
  // =====================================================

  Future<void> _sendMessage() async {
    _onUserActivity();

    final text = _messageController.text.trim();

    if (text.isEmpty) {
      return;
    }

    await messagesRef.add({
      'text': text,
      'sender': widget.userId,
      'createdAt': FieldValue.serverTimestamp(),
      'readBy': [widget.userId],
    });

    _messageController.clear();

    _onUserActivity();
  }

  // =====================================================
  // 訊息 Key
  // =====================================================

  GlobalKey _getMessageKey(String messageId) {
    return _messageKeys.putIfAbsent(messageId, () => GlobalKey());
  }

  // =====================================================
  // 判斷訊息是否可見
  // =====================================================

  bool _isMessageVisible(GlobalKey key) {
    final BuildContext? keyContext = key.currentContext;

    if (keyContext == null) {
      return false;
    }

    final RenderObject? renderObject = keyContext.findRenderObject();

    if (renderObject == null ||
        renderObject is! RenderBox ||
        !renderObject.hasSize) {
      return false;
    }

    final RenderBox box = renderObject;

    final Offset position = box.localToGlobal(Offset.zero);

    final double top = position.dy;

    final double screenHeight = MediaQuery.of(context).size.height;

    const double bottomLimitOffset = 80;

    final double bottomLimit = screenHeight - bottomLimitOffset;

    if (top >= bottomLimit) {
      return false;
    }

    return true;
  }

  // =====================================================
  // 標記已讀
  // =====================================================

  Future<void> _markVisibleMessagesAsRead() async {
    if (_leaving || !mounted || _checkingVisibleMessages) {
      return;
    }

    _checkingVisibleMessages = true;

    try {
      final snapshot = await messagesRef.orderBy('createdAt').get();

      if (_leaving || !mounted) {
        return;
      }

      final batch = FirebaseFirestore.instance.batch();

      bool hasChanges = false;

      for (final doc in snapshot.docs) {
        final data = doc.data();

        final String sender = data['sender']?.toString() ?? '';

        if (sender == widget.userId) {
          continue;
        }

        final GlobalKey? key = _messageKeys[doc.id];

        if (key == null) {
          continue;
        }

        if (!_isMessageVisible(key)) {
          continue;
        }

        final rawReadBy = data['readBy'];

        bool alreadyRead = false;

        if (rawReadBy is List) {
          alreadyRead = rawReadBy.contains(widget.userId);
        }

        if (alreadyRead) {
          continue;
        }

        batch.update(doc.reference, {
          'readBy': FieldValue.arrayUnion([widget.userId]),
        });

        hasChanges = true;
      }

      if (!hasChanges) {
        return;
      }

      try {
        await batch.commit();
      } catch (_) {}
    } finally {
      _checkingVisibleMessages = false;
    }
  }

  // =====================================================
  // 判斷已讀
  // =====================================================

  bool _isMessageRead(Map<String, dynamic> data) {
    final String sender = data['sender']?.toString() ?? '';

    if (sender != widget.userId) {
      return false;
    }

    final rawReadBy = data['readBy'];

    if (rawReadBy is! List) {
      return false;
    }

    return rawReadBy.contains(_otherUserId);
  }

  // =====================================================
  // 清除所有訊息
  // =====================================================

  Future<void> _clearAllMessages() async {
    _onUserActivity();

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('清除所有對話'),
          content: const Text(
            '確定要刪除所有聊天訊息嗎？\n'
            '刪除後所有使用者都會看不到這些訊息。',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('清除', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    _onUserActivity();

    if (shouldDelete != true) {
      return;
    }

    final snapshot = await messagesRef.get();

    final batch = FirebaseFirestore.instance.batch();

    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();

    _messageKeys.clear();

    _onUserActivity();
  }

  // =====================================================
  // 時間
  // =====================================================

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) {
      return '';
    }

    final date = timestamp.toDate();

    final hour = date.hour.toString().padLeft(2, '0');

    final minute = date.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  // =====================================================
  // 頭像
  // =====================================================

  Widget _buildAvatar(String sender) {
    final bool isUser1 = sender == 'user1';

    return CircleAvatar(
      radius: 20,
      backgroundColor: isUser1 ? Colors.blue : Colors.pink,
      child: Icon(
        isUser1 ? Icons.man : Icons.woman,
        color: Colors.white,
        size: 26,
      ),
    );
  }

  // =====================================================
  // 判斷對方在線
  // =====================================================

  bool _checkOnline(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    if (!snapshot.exists) {
      return false;
    }

    final data = snapshot.data();

    if (data == null) {
      return false;
    }

    final rawUpdatedAt = data['updatedAt'];

    if (rawUpdatedAt is! Timestamp) {
      return false;
    }

    final difference = DateTime.now().difference(rawUpdatedAt.toDate());

    // ⭐ 30 秒內有心跳才算在線
    return difference.inSeconds <= 30;
  }

  // =====================================================
  // 聊天室
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) {
        _onUserActivity();
      },
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) {
            _leaveChat();
          }
        },
        child: Scaffold(
          // ⭐ 聊天室黑色背景
          backgroundColor: Colors.black,

          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,

            title: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: onlineUsersRef.doc(_otherUserId).snapshots(),

              builder: (context, snapshot) {
                final bool isOnline = _checkOnline(
                  snapshot.data ??
                      FirebaseFirestore.instance
                              .collection('online_users')
                              .doc(_otherUserId)
                              .get()
                          as dynamic,
                );

                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildAvatar(_otherUserId),

                    const SizedBox(width: 10),

                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _otherUserName,
                          style: const TextStyle(
                            fontSize: 17,
                            color: Colors.white,
                          ),
                        ),

                        Row(
                          children: [
                            Icon(
                              Icons.circle,
                              size: 9,
                              color: isOnline ? Colors.green : Colors.grey,
                            ),

                            const SizedBox(width: 4),

                            Text(
                              isOnline ? '在線' : '不在線',
                              style: TextStyle(
                                fontSize: 11,
                                color: isOnline ? Colors.green : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),

            centerTitle: true,

            actions: [
              IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: '清除所有對話',
                onPressed: _clearAllMessages,
              ),
            ],
          ),

          body: Column(
            children: [
              // =================================================
              // ⭐ 5 分鐘倒數
              // =================================================
              StreamBuilder<int>(
                stream: Stream.periodic(
                  const Duration(seconds: 1),
                  (_) => DateTime.now().millisecondsSinceEpoch,
                ),
                builder: (context, snapshot) {
                  final remaining = _inactivityTimer?.tick ?? 0;

                  final totalSeconds = inactivityDuration.inSeconds;

                  int secondsLeft = totalSeconds - remaining;

                  if (secondsLeft < 0) {
                    secondsLeft = 0;
                  }

                  final minutes = secondsLeft ~/ 60;

                  final seconds = secondsLeft % 60;

                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    color: Colors.grey.shade900,
                    child: Text(
                      '閒置時間剩餘 '
                      '${minutes.toString().padLeft(2, '0')}:'
                      '${seconds.toString().padLeft(2, '0')}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  );
                },
              ),

              // =================================================
              // 訊息
              // =================================================
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: messagesRef.orderBy('createdAt').snapshots(),

                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(
                        child: Text(
                          '讀取訊息失敗',
                          style: TextStyle(color: Colors.white),
                        ),
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final messages = snapshot.data!.docs;

                    if (messages.isEmpty) {
                      return const Center(
                        child: Text(
                          '還沒有訊息',
                          style: TextStyle(color: Colors.white70),
                        ),
                      );
                    }

                    final currentIds = messages.map((doc) => doc.id).toSet();

                    _messageKeys.removeWhere(
                      (id, key) => !currentIds.contains(id),
                    );

                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted && !_leaving) {
                        _markVisibleMessagesAsRead();
                      }
                    });

                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(12),
                      itemCount: messages.length,

                      itemBuilder: (context, index) {
                        final doc = messages[index];

                        final data = doc.data();

                        final String text = data['text']?.toString() ?? '';

                        final String sender = data['sender']?.toString() ?? '';

                        final bool isMe = sender == widget.userId;

                        final Timestamp? createdAt =
                            data['createdAt'] as Timestamp?;

                        final String time = _formatTime(createdAt);

                        final bool isRead = _isMessageRead(data);

                        final GlobalKey messageKey = _getMessageKey(doc.id);

                        return Container(
                          key: messageKey,

                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),

                            child: Row(
                              mainAxisAlignment: isMe
                                  ? MainAxisAlignment.end
                                  : MainAxisAlignment.start,

                              crossAxisAlignment: CrossAxisAlignment.end,

                              children: [
                                if (!isMe) ...[
                                  _buildAvatar(sender),
                                  const SizedBox(width: 8),
                                ],

                                Flexible(
                                  child: Column(
                                    crossAxisAlignment: isMe
                                        ? CrossAxisAlignment.end
                                        : CrossAxisAlignment.start,

                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 9,
                                        ),

                                        decoration: BoxDecoration(
                                          color: isMe
                                              ? Colors.blue
                                              : Colors.grey.shade800,
                                          borderRadius: BorderRadius.circular(
                                            18,
                                          ),
                                        ),

                                        child: Column(
                                          crossAxisAlignment: isMe
                                              ? CrossAxisAlignment.end
                                              : CrossAxisAlignment.start,

                                          children: [
                                            Text(
                                              text,
                                              style: TextStyle(
                                                color: isMe
                                                    ? Colors.white
                                                    : Colors.white,
                                                fontSize: 16,
                                              ),
                                            ),

                                            if (time.isNotEmpty) ...[
                                              const SizedBox(height: 3),

                                              Text(
                                                time,
                                                style: TextStyle(
                                                  color: isMe
                                                      ? Colors.white70
                                                      : Colors.white54,
                                                  fontSize: 10,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),

                                      // =================================================
                                      // 已讀
                                      // =================================================
                                      if (isMe && isRead)
                                        const Padding(
                                          padding: EdgeInsets.only(
                                            top: 2,
                                            right: 4,
                                          ),
                                          child: Text(
                                            '已讀',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),

                                if (isMe) ...[
                                  const SizedBox(width: 8),
                                  _buildAvatar(sender),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              // =================================================
              // 輸入框
              // =================================================
              Container(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),

                color: Colors.grey.shade900,

                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,

                        style: const TextStyle(color: Colors.white),

                        decoration: InputDecoration(
                          hintText: '輸入訊息...',
                          hintStyle: const TextStyle(color: Colors.white54),

                          filled: true,
                          fillColor: Colors.grey.shade800,

                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide.none,
                          ),

                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                        ),

                        onChanged: (_) {
                          _onUserActivity();
                        },

                        onSubmitted: (_) {
                          _sendMessage();
                        },
                      ),
                    ),

                    const SizedBox(width: 8),

                    CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.blue,

                      child: IconButton(
                        onPressed: _sendMessage,

                        icon: const Icon(Icons.send, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
