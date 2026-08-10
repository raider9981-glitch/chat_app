import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const ChatApp());
}

// =====================================================
// App
// =====================================================

class ChatApp extends StatefulWidget {
  const ChatApp({super.key});

  @override
  State<ChatApp> createState() => _ChatAppState();
}

class _ChatAppState extends State<ChatApp> {
  bool _isInChat = false;

  void enterChat() {
    setState(() {
      _isInChat = true;
    });
  }

  void leaveChat() {
    setState(() {
      _isInChat = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '計算機',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: _isInChat
          ? UserSelectPage(onLeaveChat: leaveChat)
          : CalculatorPage(onEnterChat: enterChat),
    );
  }
}

// =====================================================
// 計算機
// =====================================================

class CalculatorPage extends StatefulWidget {
  final VoidCallback onEnterChat;

  const CalculatorPage({super.key, required this.onEnterChat});

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  String display = '0';
  String firstNumber = '';
  String operator = '';
  bool shouldResetDisplay = false;

  final String secretCode = '7766';

  String _keySequence = '';

  void _inputNumber(String number) {
    setState(() {
      _keySequence += number;

      if (_keySequence.length > 4) {
        _keySequence = _keySequence.substring(_keySequence.length - 4);
      }

      if (_keySequence == secretCode) {
        _openChat();
        return;
      }

      if (display == '0' || shouldResetDisplay) {
        display = number;
        shouldResetDisplay = false;
      } else {
        display += number;
      }
    });
  }

  void _inputDecimal() {
    setState(() {
      _keySequence = '';

      if (shouldResetDisplay) {
        display = '0.';
        shouldResetDisplay = false;
        return;
      }

      if (!display.contains('.')) {
        display += '.';
      }
    });
  }

  void _selectOperator(String selectedOperator) {
    setState(() {
      _keySequence = '';
      firstNumber = display;
      operator = selectedOperator;
      shouldResetDisplay = true;
    });
  }

  void _calculate() {
    if (firstNumber.isEmpty || operator.isEmpty) {
      return;
    }

    final double number1 = double.tryParse(firstNumber) ?? 0;

    final double number2 = double.tryParse(display) ?? 0;

    double result = 0;

    switch (operator) {
      case '+':
        result = number1 + number2;
        break;

      case '-':
        result = number1 - number2;
        break;

      case '×':
        result = number1 * number2;
        break;

      case '÷':
        if (number2 == 0) {
          setState(() {
            display = '錯誤';
            _keySequence = '';
          });
          return;
        }

        result = number1 / number2;
        break;
    }

    setState(() {
      display = _formatNumber(result);
      firstNumber = '';
      operator = '';
      shouldResetDisplay = true;
      _keySequence = '';
    });
  }

  void _clear() {
    setState(() {
      display = '0';
      firstNumber = '';
      operator = '';
      shouldResetDisplay = false;
      _keySequence = '';
    });
  }

  void _percent() {
    final double number = double.tryParse(display) ?? 0;

    setState(() {
      display = _formatNumber(number / 100);
      _keySequence = '';
    });
  }

  String _formatNumber(double number) {
    if (number == number.roundToDouble()) {
      return number.toInt().toString();
    }

    return number.toString();
  }

  void _openChat() {
    display = '0';
    firstNumber = '';
    operator = '';
    shouldResetDisplay = false;
    _keySequence = '';

    widget.onEnterChat();
  }

  Widget _button(
    String text, {
    VoidCallback? onPressed,
    bool operatorButton = false,
    bool equalButton = false,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: SizedBox(
          height: 72,
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: equalButton
                  ? Colors.blue
                  : operatorButton
                  ? Colors.orange
                  : Colors.grey.shade200,
              foregroundColor: equalButton || operatorButton
                  ? Colors.white
                  : Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              text,
              style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(title: const Text('計算機'), centerTitle: true),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 2,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                alignment: Alignment.bottomRight,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    display,
                    style: const TextStyle(
                      fontSize: 60,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 5,
              child: Column(
                children: [
                  Row(
                    children: [
                      _button('AC', onPressed: _clear),
                      _button('%', onPressed: _percent),
                      _button(
                        '÷',
                        operatorButton: true,
                        onPressed: () => _selectOperator('÷'),
                      ),
                      _button(
                        '×',
                        operatorButton: true,
                        onPressed: () => _selectOperator('×'),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _button('7', onPressed: () => _inputNumber('7')),
                      _button('8', onPressed: () => _inputNumber('8')),
                      _button('9', onPressed: () => _inputNumber('9')),
                      _button(
                        '−',
                        operatorButton: true,
                        onPressed: () => _selectOperator('-'),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _button('4', onPressed: () => _inputNumber('4')),
                      _button('5', onPressed: () => _inputNumber('5')),
                      _button('6', onPressed: () => _inputNumber('6')),
                      _button(
                        '+',
                        operatorButton: true,
                        onPressed: () => _selectOperator('+'),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _button('1', onPressed: () => _inputNumber('1')),
                      _button('2', onPressed: () => _inputNumber('2')),
                      _button('3', onPressed: () => _inputNumber('3')),
                      _button('=', equalButton: true, onPressed: _calculate),
                    ],
                  ),
                  Row(
                    children: [
                      _button('0', onPressed: () => _inputNumber('0')),
                      _button('.', onPressed: _inputDecimal),
                      _button('清除', onPressed: _clear),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================
// 使用者選擇
// =====================================================

class UserSelectPage extends StatelessWidget {
  final VoidCallback onLeaveChat;

  UserSelectPage({super.key, required this.onLeaveChat});

  final CollectionReference<Map<String, dynamic>> _onlineUsers =
      FirebaseFirestore.instance.collection('online_users');

  Future<void> _selectUser(BuildContext context, String userId) async {
    final doc = _onlineUsers.doc(userId);

    final existing = await doc.get();

    if (existing.exists) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('這個使用者已經有人使用')));
      }
      return;
    }

    await doc.set({
      'userId': userId,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (!context.mounted) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatPage(
          userId: userId,
          userName: userId == 'user1' ? '使用者 1' : '使用者 2',
          onLeaveChat: onLeaveChat,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          onLeaveChat();
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('選擇使用者'), centerTitle: true),
        body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _onlineUsers.snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(child: Text('讀取使用者狀態失敗'));
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final onlineIds = snapshot.data!.docs.map((doc) => doc.id).toSet();

            final bool user1Online = onlineIds.contains('user1');

            final bool user2Online = onlineIds.contains('user2');

            if (user1Online && user2Online) {
              return const Center(
                child: Text('目前沒有可用使用者', style: TextStyle(fontSize: 20)),
              );
            }

            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '你是誰？',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 30),

                  if (!user1Online)
                    _userButton(
                      context,
                      userId: 'user1',
                      name: '我是使用者 1',
                      color: Colors.blue,
                      icon: Icons.man,
                    ),

                  if (!user1Online && !user2Online) const SizedBox(height: 20),

                  if (!user2Online)
                    _userButton(
                      context,
                      userId: 'user2',
                      name: '我是使用者 2',
                      color: Colors.pink,
                      icon: Icons.woman,
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _userButton(
    BuildContext context, {
    required String userId,
    required String name,
    required Color color,
    required IconData icon,
  }) {
    return SizedBox(
      width: 250,
      height: 70,
      child: ElevatedButton.icon(
        onPressed: () => _selectUser(context, userId),
        icon: CircleAvatar(
          radius: 20,
          backgroundColor: color,
          child: Icon(icon, color: Colors.white, size: 28),
        ),
        label: Text(name, style: const TextStyle(fontSize: 18)),
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
  final VoidCallback onLeaveChat;

  const ChatPage({
    super.key,
    required this.userId,
    required this.userName,
    required this.onLeaveChat,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();

  final CollectionReference<Map<String, dynamic>> messagesRef =
      FirebaseFirestore.instance.collection('messages');

  final CollectionReference<Map<String, dynamic>> onlineUsersRef =
      FirebaseFirestore.instance.collection('online_users');

  bool _leaving = false;

  String get _otherUserId => widget.userId == 'user1' ? 'user2' : 'user1';

  String get _otherUserName => widget.userId == 'user1' ? '使用者 2' : '使用者 1';

  @override
  void dispose() {
    _releaseUser();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _releaseUser() async {
    if (_leaving) {
      return;
    }

    _leaving = true;

    try {
      await onlineUsersRef.doc(widget.userId).delete();
    } catch (_) {}
  }

  Future<void> _leaveChat() async {
    await _releaseUser();

    if (!mounted) {
      return;
    }

    widget.onLeaveChat();

    Navigator.of(context).pop();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();

    if (text.isEmpty) {
      return;
    }

    await messagesRef.add({
      'text': text,
      'sender': widget.userId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    _messageController.clear();
  }

  Future<void> _clearAllMessages() async {
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
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('清除', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    final snapshot = await messagesRef.get();

    final batch = FirebaseFirestore.instance.batch();

    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) {
      return '';
    }

    final date = timestamp.toDate();

    final hour = date.hour.toString().padLeft(2, '0');

    final minute = date.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _leaveChat();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: onlineUsersRef.doc(_otherUserId).snapshots(),
            builder: (context, snapshot) {
              final bool isOnline = snapshot.data?.exists ?? false;

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
                        style: const TextStyle(fontSize: 17),
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
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: messagesRef.orderBy('createdAt').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text('讀取訊息失敗'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final messages = snapshot.data!.docs;

                  if (messages.isEmpty) {
                    return const Center(child: Text('還沒有訊息'));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final data = messages[index].data();

                      final String text = data['text']?.toString() ?? '';

                      final String sender = data['sender']?.toString() ?? '';

                      final bool isMe = sender == widget.userId;

                      final Timestamp? createdAt =
                          data['createdAt'] as Timestamp?;

                      final String time = _formatTime(createdAt);

                      return Padding(
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
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 9,
                                ),
                                decoration: BoxDecoration(
                                  color: isMe
                                      ? Colors.blue
                                      : Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(18),
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
                                            : Colors.black,
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
                                              : Colors.black54,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            if (isMe) ...[
                              const SizedBox(width: 8),
                              _buildAvatar(sender),
                            ],
                          ],
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
              decoration: const BoxDecoration(color: Colors.white),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: '輸入訊息...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
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
    );
  }
}
