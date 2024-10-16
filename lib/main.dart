import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Image Test',
      home: const MyHomePage(title: 'Image Add on Click Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Offset> _grassPositions = []; // 草の位置を保存するリスト
  List<Widget> _images = [];

  // img.pngのアニメーション用の変数
  double _imgLeftPosition = 0;
  double _imgTopPosition = 0;
  final Random _random = Random();

  Timer? _removalTimer;

  bool _isImageCentered = true; // 初期状態では画像が中央にある
  bool _isInitialPositionSet = false;

  @override
  void initState() {
    super.initState();

    // ウィジェットツリーが準備できたら、img.pngの初期位置を設定する
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setInitialCenterPosition();
    });

    // 一定時間ごとに草や花の画像を削除し、img.pngを次の位置に移動させる
    _removalTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_grassPositions.isNotEmpty) {
        setState(() {
          _images.removeAt(0); // 草の画像を削除
          _grassPositions.removeAt(0); // 草の位置を削除
        });
        if (_grassPositions.isNotEmpty) {
          _moveImageToNextGrass(); // 次の草があれば、その位置に移動する
        }
      }
    });
  }

  // img.pngの初期位置を中央に設定する関数
  void _setInitialCenterPosition() {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    setState(() {
      _imgLeftPosition = (screenWidth - 100) / 2; // 横方向で中央に配置
      _imgTopPosition = (screenHeight - 100) / 2; // 縦方向で中央に配置
      _isInitialPositionSet = true;
    });
  }

  // img.pngを次の草の位置にアニメーションで移動させる関数
  void _moveImageToNextGrass() {
    setState(() {
      if (_grassPositions.isNotEmpty) {
        Offset nextGrassPosition = _grassPositions[0];
        _imgLeftPosition = nextGrassPosition.dx;
        _imgTopPosition = nextGrassPosition.dy;
        _isImageCentered = false; // 画像が中央から移動した状態
      }
    });
  }

  // 草の画像を追加し、最初の草の位置に移動するトリガーを実行
  void _addFirstImage() {
    setState(() {
      final screenHeight = MediaQuery.of(context).size.height;
      final screenWidth = MediaQuery.of(context).size.width;

      // 草の画像を画面上にランダムに配置
      double randomTop = (screenHeight * 0.55) +
          _random.nextDouble() * (screenHeight * 0.3 - 50);
      double randomLeft = _random.nextDouble() * (screenWidth - 50);

      Offset newGrassPosition = Offset(randomLeft, randomTop);
      _grassPositions.add(newGrassPosition);

      // 草の画像をリストに追加
      _images.add(
        Positioned(
          top: randomTop,
          left: randomLeft,
          child: Image.asset(
            'assets/grass.png',
            width: 50,
            height: 50,
          ),
        ),
      );

      // 初めての草が追加された場合、すぐに画像をその位置に移動させる
      if (_grassPositions.length == 1) {
        Future.delayed(const Duration(milliseconds: 200), () {
          _moveImageToNextGrass(); // 最初の草の位置に移動する
        });
      }
    });
  }

  // 花の画像を追加し、最初の花の位置に移動するトリガーを実行
  void _addSecondImage() {
    setState(() {
      final screenHeight = MediaQuery.of(context).size.height;
      final screenWidth = MediaQuery.of(context).size.width;

      // 花の画像を画面上にランダムに配置
      double randomTop = (screenHeight * 0.55) +
          _random.nextDouble() * (screenHeight * 0.3 - 50);
      double randomLeft = _random.nextDouble() * (screenWidth - 50);

      Offset newGrassPosition = Offset(randomLeft, randomTop);
      _grassPositions.add(newGrassPosition);

      // 花の画像をリストに追加
      _images.add(
        Positioned(
          top: randomTop,
          left: randomLeft,
          child: Image.asset(
            'assets/flower.png',
            width: 50,
            height: 50,
          ),
        ),
      );

      // 初めての花が追加された場合、すぐに画像をその位置に移動させる
      if (_grassPositions.length == 1) {
        Future.delayed(const Duration(milliseconds: 200), () {
          _moveImageToNextGrass(); // 最初の花の位置に移動する
        });
      }
    });
  }

  @override
  void dispose() {
    _removalTimer?.cancel(); // メモリリークを防ぐためにタイマーをキャンセル
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Stack(
        children: [
          // 背景画像
          Positioned.fill(
            child: Image.asset('assets/background.jpg', fit: BoxFit.cover),
          ),
          // 動的に追加された草と花の画像を表示
          ..._images,

          // アニメーション付きのimg.png
          if (_isInitialPositionSet)
            AnimatedPositioned(
              duration: const Duration(seconds: 2), // アニメーションの時間を指定
              curve: Curves.easeInOut, // アニメーションのカーブを指定
              top: _imgTopPosition,
              left: _imgLeftPosition,
              child: Image.asset(
                'assets/img.png',
                width: 100,
              ),
            ),
          // 画像が追加されていないときのメッセージ
          if (_images.isEmpty)
            const Positioned(
              top: 150, // テキストの位置を指定
              left: 0,
              right: 0,
              child: Text(
                'いつも頑張って偉いね〜', // コメントの内容
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),

          // 草や花を追加するためのボタン
          Positioned(
            top: 20, // 上からの距離
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _addFirstImage,
                  label: const Text('怒り'),
                ),
                const SizedBox(width: 20),
                ElevatedButton.icon(
                  onPressed: _addSecondImage,
                  label: const Text('悲しみ'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
