import 'package:flutter/material.dart';
import 'package:chess/chess.dart' as chess;
import 'dart:math';

void main() {
  runApp(const ChessApp());
}

enum GameMode { vsFriend, vsComputer }

class ChessApp extends StatelessWidget {
  const ChessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'لعبة الشطرنج المخصصة',
      theme: ThemeData.dark(),
      home: const WelcomePage(),
    );
  }
}

// 1. شاشة الواجهة الترحيبية المحدثة مع صورتك الشخصية واختيار طور اللعب
class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  GameMode _selectedMode = GameMode.vsFriend; 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'مرحباً بك في لعبتي',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 20),
              // صورتك الشخصية مدمجة برمجياً هنا للواجهة الترحيبية
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  image: const DecorationImage(
                    image: NetworkImage('https://ibb.co'), // تم إدراج صورتك هنا
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter, // لضبط ظهور الوجه بشكل ممتاز
                  ),
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                'اختر نمط اللعب:',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const SizedBox(height: 10),
              ListTile(
                title: const Text('اللعب مع صديق (نفس الهاتف)', style: TextStyle(color: Colors.white)),
                leading: Radio<GameMode>(
                  value: GameMode.vsFriend,
                  groupValue: _selectedMode,
                  onChanged: (GameMode? value) {
                    setState(() { _selectedMode = value!; });
                  },
                ),
              ),
              ListTile(
                title: const Text('اللعب ضد الكمبيوتر', style: TextStyle(color: Colors.white)),
                leading: Radio<GameMode>(
                  value: GameMode.vsComputer,
                  groupValue: _selectedMode,
                  onChanged: (GameMode? value) {
                    setState(() { _selectedMode = value!; });
                  },
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChessBoardPage(mode: _selectedMode),
                    ),
                  );
                },
                child: const Text('دخول اللعبة'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChessBoardPage extends StatefulWidget {
  final GameMode mode;
  const ChessBoardPage({super.key, required this.mode});

  @override
  State<ChessBoardPage> createState() => _ChessBoardPageState();
}

class _ChessBoardPageState extends State<ChessBoardPage> 
  late chess.Chess game;
  int? selectedSquare;
  bool isComputerThinking = false;

  @override
  void initState() {
    super.initState();
    _resetGame();
  }

  void _resetGame() {
    setState(() {
      game = chess.Chess();
      selectedSquare = null;
      isComputerThinking = false;
    });
  }

  String _getPieceSymbol(chess.Piece? piece) {
    if (piece == null) return '';
    if (piece.color == chess.Color.WHITE) {
      switch (piece.type) {
        case chess.PieceType.PAWN: return '♙';
        case chess.PieceType.KNIGHT: return '♘';
        case chess.PieceType.BISHOP: return '♗';
        case chess.PieceType.ROOK: return '♖';
        case chess.PieceType.QUEEN: return '♕';
        case chess.PieceType.KING: return '♔';
      }
    } else {
      switch (piece.type) {
        case chess.PieceType.PAWN: return '♟';
        case chess.PieceType.KNIGHT: return '♞';
        case chess.PieceType.BISHOP: return '♝';
        case chess.PieceType.ROOK: return '♜';
        case chess.PieceType.QUEEN: return '♛';
        case chess.PieceType.KING: return '♚';
      }
    }
    return '';
  }

  void _makeComputerMove() {
    if (game.game_over()) return;

    setState(() { isComputerThinking = true; });

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      
      List<dynamic> moves = game.moves();
      if (moves.isNotEmpty) {
        final randomMove = moves[Random().nextInt(moves.length)];
        game.move(randomMove);
      }

      setState(() {
        isComputerThinking = false;
      });

      _checkGameStatus();
    });
  }

  void _onSquareTap(int index) {
    if (isComputerThinking) return; 
    
    String squareName = chess.Chess.SQUARES[index];
    if (selectedSquare == null) {
      var piece = game.get(squareName);
      if (piece != null && piece.color == game.turn) {
        setState(() { selectedSquare = index; });
      }
    } else {
      String fromSquare = chess.Chess.SQUARES[selectedSquare!];
      String toSquare = squareName;

      bool moveSuccessful = game.move({
        'from': fromSquare,
        'to': toSquare,
        'promotion': 'q'
      });

      setState(() { selectedSquare = null; });

      if (!moveSuccessful) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('نقلة غير قانونية!'), duration: Duration(milliseconds: 300)),
        );
      } else {
        _checkGameStatus();
        if (widget.mode == GameMode.vsComputer && game.turn == chess.Color.BLACK) {
          _makeComputerMove();
        }
      }
    }
  }

  void _checkGameStatus() {
    if (game.in_checkmate) {
      _showGameOverDialog('كش ملك! انتهت اللعبة.');
    } else if (game.in_draw || game.in_stalemate) {
      _showGameOverDialog('تعادل المباراة!');
    }
  }

  void _showGameOverDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('نهاية المباراة'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetGame();
            },
            child: const Text('لعب مجدداً'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) 
    return Scaffold
      appBar: AppBar(
        title: Text(widget.mode == GameMode.vsComputer ? 'تحدي الكمبيوتر' : 'اللعب ضد صديق'),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _resetGame)
        ],
      ),
      // صورتك مدمجة برمجياً هنا كخلفية لطاولة الشطرنج خلف الرقعة
      body: Container
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: NetworkImage('https://ibb.co'), // تم إدراج صورتك هنا أيضاً كطاولة خلفية
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.black54, BlendMode.darken), // تعتيم بسيط لبروز الرقعة
          ),
        ),
        child: Column
          mainAxisAlignment: MainAxisAlignment.center,
          children: 
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(color: Colors.black80, borderRadius: BorderRadius.circular(10)),
              child: Text(
                isComputerThinking 
                    ? 'الكمبيوتر يفكر الآن...' 
                    : (game.turn == chess.Color.WHITE ? 'دورك (الأبيض)' : 'دور الخصم (الأسود)'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
            // رقعة الشطرنج الاحترافية (أبيض وأسود كلاسيك)
            Container
              margin: const EdgeInsets.all(8.0),
              decoration: Border.all(color: Colors.white, width: 3),
              child: GridView.builder
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 8),
                itemCount: 64,
                itemBuilder: (context, index) 
                  int row = index ~/ 8;
                  int col = index % 8;
                  bool isDarkSquare = (row + col) % 2 != 0;

                  Color squareColor = isDarkSquare ? const Color(0xFF262626) : const Color(0xFFF0F0F0);
                  if (selectedSquare == index) {
                    squareColor = Colors.blue.withOpacity(0.6);
                  }

                  String squareName = chess.Chess.SQUARES[index];
                  var piece = game.get(squareName);

                  return GestureDetector