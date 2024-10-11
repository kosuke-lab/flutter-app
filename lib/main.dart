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
  List<Widget> _images = [];

  // アニメーション用の変数
  double _imgLeftPosition = 0;
  bool _moveRight = true;

  final Random _random = Random();

  // 一定時間ごとに要素を削除するためのタイマー
  Timer? _removalTimer;

  // カウンター用の変数
  int _counter = 0;

  @override
  void initState() {
    super.initState();
    // タイマーを使ってアニメーションを開始
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        // 画像が左右に動くアニメーション
        if (_moveRight) {
          _imgLeftPosition += 20;
          if (_imgLeftPosition > 100) {
            _moveRight = false;
          }
        } else {
          _imgLeftPosition -= 20;
          if (_imgLeftPosition < 0) {
            _moveRight = true;
          }
        }
      });
    });
    // 一定時間ごとにリストの先頭から要素を削除するタイマー
    _removalTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      setState(() {
        if (_images.isNotEmpty) {
          _images.removeAt(0); // リストの先頭の要素を削除
        }
      });
    });
  }

  // ボタン 1 を押した時の動作
  void _addFirstImage() {
    setState(() {
      _counter++;
      final screenHeight = MediaQuery.of(context).size.height;
      final screenWidth = MediaQuery.of(context).size.width;

      // 画像を画面の下の方に配置するため、top の最小値を画面の高さの55%に設定
      double randomTop = (screenHeight * 0.55) +
          _random.nextDouble() * (screenHeight * 0.3 - 50);
      double randomLeft = _random.nextDouble() * (screenWidth - 50);

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
    });
  }

  // ボタン 2 を押した時の動作
  void _addSecondImage() {
    setState(() {
      _counter++;
      final screenHeight = MediaQuery.of(context).size.height;
      final screenWidth = MediaQuery.of(context).size.width;

      // 画像を画面の下の方に配置するため、top の最小値を画面の高さの55%に設定
      double randomTop = (screenHeight * 0.55) +
          _random.nextDouble() * (screenHeight * 0.3 - 50);
      double randomLeft = _random.nextDouble() * (screenWidth - 50);

      // 画像をリストに追加（画像2）
      _images.add(
        Positioned(
          top: randomTop, // 画像を縦にずらして配置
          left: randomLeft, // 画像を横にずらして配置
          child: Image.asset(
            'assets/flower.png', // 追加する画像のパス（別の画像を指定）
            width: 50,
            height: 50,
          ),
        ),
      );
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
          AnimatedPositioned(
            duration: const Duration(milliseconds: 500), // アニメーションの時間を指定
            curve: Curves.easeInOut, // アニメーションのカーブを指定
            bottom: 0,
            left: _imgLeftPosition,
            right: 0,
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
                  // icon: const Icon(Icons.nature), // アイコンを指定
                  label: const Text('怒り'), // テキストを表示
                ),
                const SizedBox(width: 20), // ボタン間のスペースを設定
                // ボタン 2：花を追加する
                ElevatedButton.icon(
                  onPressed: _addSecondImage,
                  // icon: const Icon(Icons.local_florist), // アイコンを指定
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
