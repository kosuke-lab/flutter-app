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
  // 画像を管理するリスト
  List<Offset> _grassPositions = []; // Store positions of the grass
  List<Widget> _images = [];

  // アニメーション用の変数
  double _imgLeftPosition = 0;
  double _imgTopPosition = 0;
  final Random _random = Random();

  // 一定時間ごとに要素を削除するためのタイマー
  Timer? _removalTimer;

  // フラグでimg.pngが中央にいるかどうかを管理
  bool _isImageCentered = true; // Initially, the image is centered
  bool _isInitialPositionSet = false; // Ensure initial position is set

  @override
  void initState() {
    super.initState();

    // Set the initial center position when the widget tree is fully ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setInitialCenterPosition();
    });

    // タイマーで草の削除と画像移動を制御
    _removalTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_grassPositions.isNotEmpty) {
        setState(() {
          _images.removeAt(0); // Remove the grass image
          _grassPositions.removeAt(0); // Remove the grass position
        });
        if (_grassPositions.isNotEmpty) {
          _moveImageToNextGrass(); // Move to the next grass if any remains
        }
      }
    });
  }

  // 初期位置を中央に設定する関数
  void _setInitialCenterPosition() {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // 初期位置を画面の中央に設定
    setState(() {
      _imgLeftPosition = (screenWidth - 100) / 2; // 画像の幅100を考慮して中央に配置
      _imgTopPosition = (screenHeight - 100) / 2; // 画像の高さ100を考慮して中央に配置
      _isInitialPositionSet = true; // Mark initial position as set
    });
  }

  // 草の位置へ画像を移動
  void _moveImageToNextGrass() {
    setState(() {
      if (_grassPositions.isNotEmpty) {
        Offset nextGrassPosition = _grassPositions[0];
        _imgLeftPosition = nextGrassPosition.dx;
        _imgTopPosition = nextGrassPosition.dy;
        _isImageCentered =
            false; // Once the image moves, it's no longer centered
      }
    });
  }

  // ボタン 1 を押した時の動作
  void _addFirstImage() {
    setState(() {
      final screenHeight = MediaQuery.of(context).size.height;
      final screenWidth = MediaQuery.of(context).size.width;

      // 画像を画面の下の方に配置するため、top の最小値を画面の高さの55%に設定
      double randomTop = (screenHeight * 0.55) +
          _random.nextDouble() * (screenHeight * 0.3 - 50);
      double randomLeft = _random.nextDouble() * (screenWidth - 50);

      // 保存する位置情報を更新
      Offset newGrassPosition = Offset(randomLeft, randomTop);
      _grassPositions.add(newGrassPosition);

      // 画像をリストに追加（画像1）
      _images.add(
        Positioned(
          top: randomTop, // 画像を縦にずらして配置
          left: randomLeft, // 画像を横にずらして配置
          child: Image.asset(
            'assets/grass.png', // 追加する画像のパス
            width: 50,
            height: 50,
          ),
        ),
      );

      // もし最初の草なら画像をその位置に移動
      if (_grassPositions.length == 1 && _isImageCentered) {
        _moveImageToNextGrass(); // Move to the position of the first grass
      }
    });
  }

  // ボタン 2 を押した時の動作
  void _addSecondImage() {
    setState(() {
      final screenHeight = MediaQuery.of(context).size.height;
      final screenWidth = MediaQuery.of(context).size.width;

      // 画像を画面の下の方に配置するため、top の最小値を画面の高さの55%に設定
      double randomTop = (screenHeight * 0.55) +
          _random.nextDouble() * (screenHeight * 0.3 - 50);
      double randomLeft = _random.nextDouble() * (screenWidth - 50);

      // 保存する位置情報を更新
      Offset newGrassPosition = Offset(randomLeft, randomTop);
      _grassPositions.add(newGrassPosition);

      // 画像をリストに追加（画像2）
      _images.add(
        Positioned(
          top: randomTop, // 画像を縦にずらして配置
          left: randomLeft, // 画像を横にずらして配置
          child: Image.asset(
            'assets/flower.png', // 追加する画像のパス
            width: 50,
            height: 50,
          ),
        ),
      );

      // もし最初の草なら画像をその位置に移動
      if (_grassPositions.length == 1 && _isImageCentered) {
        _moveImageToNextGrass(); // Move to the position of the first grass
      }
    });
  }

  @override
  void dispose() {
    // タイマーを破棄してメモリリークを防ぐ
    _removalTimer?.cancel();
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
          // 追加された画像を表示
          ..._images, // 動的に管理されている画像を追加

          // アニメーション付きの画像
          if (_isInitialPositionSet)
            AnimatedPositioned(
              duration: const Duration(seconds: 2), // アニメーションの時間を指定 (2秒に設定)
              curve: Curves.easeInOut, // アニメーションのカーブを指定
              top: _imgTopPosition,
              left: _imgLeftPosition,
              child: Image.asset(
                'assets/img.png',
                width: 100,
              ),
            ),

          // 2 つのボタンを上部中央に配置する
          Positioned(
            top: 20, // 上からの距離を指定
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center, // ボタンを中央揃え
              children: [
                // ボタン 1：草を追加する
                ElevatedButton.icon(
                  onPressed: _addFirstImage,
                  label: const Text('怒り'), // テキストを表示
                ),
                const SizedBox(width: 20), // ボタン間のスペースを設定
                // ボタン 2：花を追加する
                ElevatedButton.icon(
                  onPressed: _addSecondImage,
                  label: const Text('悲しみ'), // テキストを表示
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
