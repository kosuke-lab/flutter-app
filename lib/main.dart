import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
  int _removedImageCount = 0; // 草を食べた回数をカウントする変数

  // img.pngのアニメーション用の変数
  double _imgLeftPosition = 0;
  double _imgTopPosition = 0;
  final Random _random = Random();

  Timer? _removalTimer;

  bool _isImageCentered = true; // 初期状態では画像が中央にある
  bool _isInitialPositionSet = false;

  // 各状態ごとの歩行アニメーション画像リスト
  final List<String> _normalImages = [
    'assets/normal_1.png',
    'assets/normal_2.png',
    'assets/normal_3.png',
    'assets/normal_4.png',
    'assets/normal_5.png',
  ];
  final List<String> _slightlyFatImages = [
    'assets/fat_1_1.png',
    'assets/fat_1_2.png',
    'assets/fat_1_3.png',
  ];
  final List<String> _moreFatImages = [
    'assets/fat_2_1.png',
    'assets/fat_2_2.png',
    'assets/fat_2_3.png',
  ];
  final List<String> _veryFatImages = [
    'assets/fat_3_1.png',
    'assets/fat_3_2.png',
  ];

  List<String> _walkingImages = []; // 現在の状態に応じた画像リスト
  int _currentWalkingImageIndex = 0;
  Timer? _walkingAnimationTimer;

  @override
  void initState() {
    super.initState();

    // 初期位置設定
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setInitialCenterPosition();
    });

    // 草や花を削除してキャラクターを移動させるタイマー
    _removalTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_grassPositions.isNotEmpty) {
        setState(() {
          _images.removeAt(0);
          _grassPositions.removeAt(0);
          _removedImageCount++;
        });
        _updateWalkingImages(); // _removedImageCount に基づいて歩行画像を更新
        if (_grassPositions.isNotEmpty) {
          _moveImageToNextGrass();
        }
      }
    });

    // 歩行アニメーションの開始
    _startWalkingAnimation();
  }

  // キャラクターの初期位置を中央に設定
  void _setInitialCenterPosition() {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    setState(() {
      _imgLeftPosition = (screenWidth - 100) / 2;
      _imgTopPosition = (screenHeight - 100) / 2;
      _isInitialPositionSet = true;
    });
  }

  // _removedImageCount に基づいて _walkingImages を更新
  void _updateWalkingImages() {
    setState(() {
      if (_removedImageCount < 3) {
        _walkingImages = _normalImages;
      } else if (_removedImageCount < 10) {
        _walkingImages = _slightlyFatImages;
      } else if (_removedImageCount < 20) {
        _walkingImages = _moreFatImages;
      } else {
        _walkingImages = _veryFatImages;
      }
      _currentWalkingImageIndex = 0; // 範囲外エラーを避けるためにインデックスをリセット
    });
  }

  // 次の草の位置に移動する
  void _moveImageToNextGrass() {
    setState(() {
      if (_grassPositions.isNotEmpty) {
        Offset nextGrassPosition = _grassPositions[0];
        _imgLeftPosition = nextGrassPosition.dx;
        _imgTopPosition = nextGrassPosition.dy;
        _isImageCentered = false;
      }
    });
  }

  // Firestoreにカウントを保存
  Future<void> _incrementCounterInFirestore(
      String collectionName, String documentId) async {
    try {
      final docRef =
          FirebaseFirestore.instance.collection(collectionName).doc(documentId);
      await docRef.set(
        {'value': FieldValue.increment(1)},
        SetOptions(merge: true),
      );
      print("$documentId のカウントが増加しました");
    } catch (e) {
      print("Firestoreエラー: $e");
    }
  }

  // カウントを表示するウィジェット
  Widget _buildCounterDisplay(String documentId) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('counter')
          .doc(documentId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Text("0");
        }
        var data = snapshot.data!.data() as Map<String, dynamic>;
        return Text(
          "${data['value'] ?? 0}",
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        );
      },
    );
  }

  // 歩行アニメーションを開始する
  void _startWalkingAnimation() {
    _updateWalkingImages(); // 正しい初期状態を確認
    _walkingAnimationTimer =
        Timer.periodic(const Duration(milliseconds: 200), (timer) {
      setState(() {
        _currentWalkingImageIndex =
            (_currentWalkingImageIndex + 1) % _walkingImages.length;
      });
    });
  }

  @override
  void dispose() {
    _removalTimer?.cancel();
    _walkingAnimationTimer?.cancel();
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

          // 各カウンターを表示する行
          Positioned(
            top: 300,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    _buildCounterDisplay('punpun'),
                    const Text('プンプン'),
                  ],
                ),
                Column(
                  children: [
                    _buildCounterDisplay('moyamoya'),
                    const Text('モヤモヤ'),
                  ],
                ),
                Column(
                  children: [
                    _buildCounterDisplay('zawazawa'),
                    const Text('ザワザワ'),
                  ],
                ),
                Column(
                  children: [
                    _buildCounterDisplay('mesomeso'),
                    const Text('メソメソ'),
                  ],
                ),
                Column(
                  children: [
                    _buildCounterDisplay('awaawa'),
                    const Text('アワアワ'),
                  ],
                ),
              ],
            ),
          ),

          // 削除された画像の数を表示するテキスト
          Positioned(
            top: 80,
            left: 0,
            right: 0,
            child: Text(
              '食べた草の数: $_removedImageCount',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),

          // 動的に追加された草と花の画像を表示
          ..._images,

          // アニメーション付きのimg.png
          if (_isInitialPositionSet)
            AnimatedPositioned(
              duration: const Duration(seconds: 2),
              curve: Curves.easeInOut,
              top: _imgTopPosition,
              left: _imgLeftPosition,
              child: Image.asset(
                _walkingImages[_currentWalkingImageIndex],
                width: 100,
              ),
            ),

          // 画像が追加されていないときのメッセージ
          if (_images.isEmpty)
            const Positioned(
              top: 150,
              left: 0,
              right: 0,
              child: Text(
                'いつも頑張って偉いね〜',
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
            top: 20,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                InkWell(
                  onTap: () {
                    _addPunPunImage();
                    _incrementCounterInFirestore('counter', 'punpun');
                  },
                  child: Image.asset(
                    'assets/punpun.png',
                    width: 50,
                    height: 50,
                  ),
                ),
                InkWell(
                  onTap: () {
                    _addMoyaMoyaImage();
                    _incrementCounterInFirestore('counter', 'moyamoya');
                  },
                  child: Image.asset(
                    'assets/moyaamoyaa.png',
                    width: 50,
                    height: 50,
                  ),
                ),
                InkWell(
                  onTap: () {
                    _addZawaZawaImage();
                    _incrementCounterInFirestore('counter', 'zawazawa');
                  },
                  child: Image.asset(
                    'assets/zawazawa.png',
                    width: 50,
                    height: 50,
                  ),
                ),
                InkWell(
                  onTap: () {
                    _addMesomesoImage();
                    _incrementCounterInFirestore('counter', 'mesomeso');
                  },
                  child: Image.asset(
                    'assets/mesomeso.png',
                    width: 50,
                    height: 50,
                  ),
                ),
                InkWell(
                  onTap: () {
                    _addAwaawaImage();
                    _incrementCounterInFirestore('counter', 'awaawa');
                  },
                  child: Image.asset(
                    'assets/awaawa.png',
                    width: 50,
                    height: 50,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 各花や草の画像を追加する関数
  void _addPunPunImage() {
    _addImage('assets/pun-kusa.png', 'punpun');
  }

  void _addMoyaMoyaImage() {
    _addImage('assets/moya-kusa.png', 'moyamoya');
  }

  void _addZawaZawaImage() {
    _addImage('assets/zawa-kusa.png', 'zawazawa');
  }

  void _addMesomesoImage() {
    _addImage('assets/meso-kusa.png', 'mesomeso');
  }

  void _addAwaawaImage() {
    _addImage('assets/awa-kusa.png', 'awaawa');
  }

  // 画像を追加して位置を設定する共通メソッド
  void _addImage(String assetPath, String documentId) {
    setState(() {
      final screenHeight = MediaQuery.of(context).size.height;
      final screenWidth = MediaQuery.of(context).size.width;

      double randomTop = (screenHeight * 0.55) +
          _random.nextDouble() * (screenHeight * 0.3 - 50);
      double randomLeft = _random.nextDouble() * (screenWidth - 50);

      Offset newGrassPosition = Offset(randomLeft, randomTop);
      _grassPositions.add(newGrassPosition);

      _images.add(
        Positioned(
          top: randomTop,
          left: randomLeft,
          child: Image.asset(
            assetPath,
            width: 50,
            height: 50,
          ),
        ),
      );

      if (_grassPositions.length == 1) {
        Future.delayed(const Duration(milliseconds: 200), () {
          _moveImageToNextGrass();
        });
      }
    });
  }
}
