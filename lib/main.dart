import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const ChatApp());
}

class ChatApp extends StatefulWidget {
  const ChatApp({super.key});

  @override
  State<ChatApp> createState() => _ChatAppState();
}

class _ChatAppState extends State<ChatApp> with WidgetsBindingObserver {
  bool _isInChat = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

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
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      if (_isInChat) {
        setState(() {
          _isInChat = false;
        });
      }
    }
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
          ? UserSelectPage(onEnterChat: enterChat, onLeaveChat: leaveChat)
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

  // 聊天室密碼
  final String secretCode = '7766';

  // 專門記錄按鍵，用來判斷 7766
  String _keySequence = '';

  void _inputNumber(String number) {
    setState(() {
      // 記錄使用者按下的數字
      _keySequence += number;

      // 只保留最後 4 個數字
      if (_keySequence.length > 4) {
        _keySequence = _keySequence.substring(_keySequence.length - 4);
      }

      // 偵測 7766
      if (_keySequence == secretCode) {
        _openChat();
        return;
      }

      // 正常計算機功能
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
    // 清除計算機畫面
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
  final VoidCallback onEnterChat;
  final VoidCallback onLeaveChat;

  const UserSelectPage({
    super.key,
    required this.onEnterChat,
    required this.onLeaveChat,
  });

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
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '你是誰？',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: 250,
                height: 70,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatPage(
                          userId: 'user1',
                          userName: '使用者 1',
                          onLeaveChat: onLeaveChat,
                        ),
                      ),
                    );
                  },
                  icon: const CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.blue,
                    child: Icon(Icons.man, color: Colors.white, size: 28),
                  ),
                  label: const Text('我是使用者 1', style: TextStyle(fontSize: 18)),
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: 250,
                height: 70,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatPage(
                          userId: 'user2',
                          userName: '使用者 2',
                          onLeaveChat: onLeaveChat,
                        ),
                      ),
                    );
                  },
                  icon: const CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.pink,
                    child: Icon(Icons.woman, color: Colors.white, size: 28),
                  ),
                  label: const Text('我是使用者 2', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
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

  final CollectionReference messagesRef = FirebaseFirestore.instance.collection(
    'messages',
  );

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
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          widget.onLeaveChat();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAvatar(widget.userId),
              const SizedBox(width: 10),
              Text(widget.userName),
            ],
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
              child: StreamBuilder<QuerySnapshot>(
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
                      final data =
                          messages[index].data() as Map<String, dynamic>;

                      final String text = data['text'] ?? '';

                      final String sender = data['sender'] ?? '';

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
