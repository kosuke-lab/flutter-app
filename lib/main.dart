import 'dart:html' as html;
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
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
      home: const MyHomePage(title: ''),
      debugShowCheckedModeBanner: true,
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
  double _titleImageOpacity = 1.0; // 初期値を1.0に設定（表示状態）

  // img.pngのアニメーション用の変数
  double _imgLeftPosition = 0;
  double _imgTopPosition = 0;
  final Random _random = Random();

  Timer? _removalTimer;
  Timer? _timeCheckTimer; // 15時になったら変更するためのタイマー

  bool _isImageCentered = true; // 初期状態では画像が中央にある
  bool _isInitialPositionSet = false;

  // 許可されたUUIDをリストで定義
  static const List<String> authorizedUuids = [
    "961c178b-a298-4d6f-aff4-7c4c945d470a", // local用
    "c8ba7cf1-b0f6-4753-9039-9694e02946c9", // local用
    "68fc11a3-9a3f-4092-9fb3-15dcf3e65945" // iPhone用 MK
  ];

// メッセージ候補リスト
  final List<String> messages = [
    '無理しないでね​',
    '大変そうだね​',
    '僕は青じそドレッシングが好きだよ​',
    '僕はクォッカ、コアラには負けない！​',
    'まだまだ食べるよ！​',
    '僕たちクォッカは "世界一幸せな動物" って呼ばれてるんだよ！',
    '美味しいものでも食べて元気出そう！​',
    '少し休んでもいいんだよ​',
    'いつでも話を聞くよ​',
    'いつも頑張りを見てるよ、偉いね​',
    '今日は早く帰ろうね​',
    '焦らずゆっくりで大丈夫だよ​',
    '話してくれてありがとう！​',
    '（たまには焼肉も食べたい）​',
    '不機嫌おいしい〜​',
    '会社来てるだけで君はなんて偉いんだ​',
    'チョコでも食べたら？​',
    '桃の香りでリラックスできるらしいよ〜​',
    'ちょっと窓から外を見てみよう！​',
    '不機嫌の草は0カロリーだ!',
    '君がいてくれるだけで安心するよ​',
    'もぐもぐむしゃむしゃ​',
    'ニガっ！！！​',
    'おかわり欲しいな〜​',
    'はぁ〜美味しかった!',
  ];

  // メッセージを1回だけ表示するためのフラグ
  bool _showMessageOnce = true;

  // 現在のメッセージを保持する変数
  String? _currentMessage;

  // UUIDが一致する場合にtrueになるフラグ
  bool _isAdmin = false;

// ランダムにメッセージを選ぶ
  String getRandomMessage() {
    final random = Random();
    _showMessageOnce = false; // メッセージを表示した後にフラグをオフにする
    return messages[random.nextInt(messages.length)];
  }

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
  final List<String> _dietImages = [
    'assets/jump_1.png',
    'assets/jump_2.png',
  ];
  // 下記から食べてる時の画像
  final List<String> _nomalEatImages = [
    'assets/eat_1.png',
    'assets/eat_2.png',
  ];
  final List<String> _slightlyFatEatImages = [
    'assets/fat_1_4.png',
  ];
  final List<String> _moreFatEatImages = [
    'assets/fat_2_4.png',
    'assets/fat_2_5.png',
  ];
  // final List<String> _veryFatEatImages = [
  //   'assets/fat_3_1.png',
  //   'assets/fat_3_2.png',
  // ];

  // ハードコードされたUUIDとの一致を確認し、メッセージを表示
  Future<void> checkAndShowMessage() async {
    String uuid = await getOrCreateUuid();
    if (authorizedUuids.contains(uuid)) {
      // UUIDが一致する場合のみメッセージを表示
      setState(() {
        _isAdmin = true;
      });
    }
  }

  // 初回アクセス時にUUIDを生成し、localStorageとFirestoreに保存
  Future<String> getOrCreateUuid() async {
    const uuidKey = 'flutter_web_unique_id';
    var storedUuid = html.window.localStorage[uuidKey];

    if (storedUuid == null) {
      // UUIDを生成し、localStorageとFirestoreに保存
      storedUuid = Uuid().v4();
      html.window.localStorage[uuidKey] = storedUuid;
      await FirebaseFirestore.instance
          .collection('userUuids')
          .doc(storedUuid)
          .set({
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    return storedUuid;
  }

  List<String> _walkingImages = []; // 現在の状態に応じた画像リスト
  int _currentWalkingImageIndex = 0;
  Timer? _walkingAnimationTimer;

  @override
  void initState() {
    super.initState();
    checkAndShowMessage(); // UUIDをチェックしてメッセージ表示を確認

    // 2秒後にフェードアウトするようにタイマーを設定
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _titleImageOpacity = 0.0;
      });
    });

    // 初期位置設定
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setInitialCenterPosition();
    });

    // 草や花を削除してキャラクターを移動させるタイマー
    _startRemovalTimer();

    // 歩行アニメーションの開始
    _startWalkingAnimation();

    // 毎分時間をチェックして15時になったら画像を変更するタイマー
    _startTimeCheckTimer();
  }

  // キャラクターの初期位置を中央に設定
  void _setInitialCenterPosition() {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    setState(() {
      _imgLeftPosition = (screenWidth - 100) / 2;
      _imgTopPosition = (screenHeight - 100) / 1.5;
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
        _imgLeftPosition = nextGrassPosition.dx - 12; // 草の中央に合わせて調整
        _imgTopPosition = nextGrassPosition.dy - 18; // 草の高さに合わせて調整
        _isImageCentered = false;
      }
    });

    // キャラクターが到達後に一時的に食べてる画像に変更
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        if (_removedImageCount < 3) {
          _walkingImages = _nomalEatImages;
        } else if (_removedImageCount < 10) {
          _walkingImages = _slightlyFatEatImages;
        } else if (_removedImageCount < 20) {
          _walkingImages = _moreFatEatImages;
        }
        _currentWalkingImageIndex = 0;
      });

      // 1秒後に通常の歩行アニメーションに戻す
      Future.delayed(const Duration(seconds: 1), () {
        setState(() {
          _updateWalkingImages(); // `_removedImageCount`に基づいてリストを更新
        });
      });
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
  // Widget _buildCounterDisplay(String documentId) {
  //   return StreamBuilder<DocumentSnapshot>(
  //     stream: FirebaseFirestore.instance
  //         .collection('counter')
  //         .doc(documentId)
  //         .snapshots(),
  //     builder: (context, snapshot) {
  //       if (!snapshot.hasData || !snapshot.data!.exists) {
  //         return const Text("0");
  //       }
  //       var data = snapshot.data!.data() as Map<String, dynamic>;
  //       return Text(
  //         "${data['value'] ?? 0}",
  //         style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
  //       );
  //     },
  //   );
  // }

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

  // 毎分時間をチェックして15時になったら画像を変更するタイマー
  void _startTimeCheckTimer() {
    _timeCheckTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      final currentTime = DateTime.now();
      if (currentTime.hour == 15 && currentTime.minute == 00) {
        setState(() {
          _walkingImages = _dietImages;
          _currentWalkingImageIndex = 0; // インデックスをリセット
        });

        _backupAndDeleteCollection(); // バックアップを作成し、元のコレクションを削除
      }
    });
  }

  // 15時時点のデータをバックアップして元のコレクションを削除
  void _backupAndDeleteCollection() {
    final newCollectionName = '${DateTime.now().toString()}';
    FirebaseFirestore.instance
        .collection('counter')
        .get()
        .then((snapshot) async {
      for (DocumentSnapshot doc in snapshot.docs) {
        // 新しいコレクションに同じデータを追加
        await FirebaseFirestore.instance
            .collection(newCollectionName)
            .doc(doc.id) // 同じIDで保存
            .set(doc.data() as Map<String, dynamic>);
        // 元のコレクションから削除
        await doc.reference.delete();
      }
      print('バックアップを作成し、元のコレクションを削除しました');
    }).catchError((error) {
      print('バックアップ作成中または削除中にエラーが発生しました: $error');
    });
  }

  // 草や花を削除してキャラクターを移動させるタイマー
  void _startRemovalTimer() {
    _removalTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_grassPositions.isNotEmpty) {
        setState(() {
          _images.removeAt(0);
          _grassPositions.removeAt(0);
          _removedImageCount++;

          //  草を食べた後にメッセージを表示
          if (_removedImageCount > 19) {
            // 20回以上食べたらメッセージを固定
            _currentMessage = '15時くらい運動しようかな〜';
            _showMessageOnce = true;
          } else {
            _currentMessage = getRandomMessage();
            _showMessageOnce = true;
          }
        });
        _updateWalkingImages();
        if (_grassPositions.isNotEmpty) {
          _moveImageToNextGrass();
        }
      }
    });
  }

  @override
  void dispose() {
    _removalTimer?.cancel();
    _walkingAnimationTimer?.cancel();
    _timeCheckTimer?.cancel(); // タイムチェックタイマーをキャンセル
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // PC と SP で画像のサイズを分ける
    final titleImageSize =
        screenWidth > 600 ? 700.0 : 500.0; // 600以上ならPC、以下ならSP

    return Scaffold(
      body: Stack(
        children: [
          // 背景画像
          Positioned.fill(
            child: Image.asset('assets/haikei.png', fit: BoxFit.cover),
          ),

          Align(
            alignment: Alignment.topCenter,
            child: AnimatedOpacity(
              opacity: _titleImageOpacity,
              duration: const Duration(seconds: 1), // フェードアウトの長さ
              child: Image.asset(
                'assets/title.png',
                height: 500,
                width: titleImageSize,
                fit: BoxFit.contain,
              ),
            ),
          ),

          // 各カウンターを表示する行
          Positioned(
            top: 300,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _isAdmin
                  ? [
                      const Text('管理者専用のメッセージ'),
                    ]
                  : [],
              // children: [
              //   Column(
              //     children: [
              //       _buildCounterDisplay('punpun'),
              //       const Text('プンプン'),
              //     ],
              //   ),
              //   Column(
              //     children: [
              //       _buildCounterDisplay('moyamoya'),
              //       const Text('モヤモヤ'),
              //     ],
              //   ),
              //   Column(
              //     children: [
              //       _buildCounterDisplay('zawazawa'),
              //       const Text('ザワザワ'),
              //     ],
              //   ),
              //   Column(
              //     children: [
              //       _buildCounterDisplay('mesomeso'),
              //       const Text('メソメソ'),
              //     ],
              //   ),
              //   Column(
              //     children: [
              //       _buildCounterDisplay('awaawa'),
              //       const Text('アワアワ'),
              //     ],
              //   ),
              // ],
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
                  color: Colors.white),
            ),
          ),

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

          // 動的に追加された草と花の画像を表示
          Stack(
            children: _images,
          ),

          // クリックされたときに表示されるメッセージ
          if (_showMessageOnce && _currentMessage != null)
            Positioned(
              top: 150,
              left: 0,
              right: 0,
              child: Text(
                _currentMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),

          // 草や花を追加するためのボタン
          Positioned(
            bottom: 30,
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
                    width: 80, // サイズを100ピクセルに拡大
                    height: 75,
                  ),
                ),
                InkWell(
                  onTap: () {
                    _addMoyaMoyaImage();
                    _incrementCounterInFirestore('counter', 'moyamoya');
                  },
                  child: Image.asset(
                    'assets/moyamoya.png',
                    width: 80, // サイズを100ピクセルに拡大
                    height: 75,
                  ),
                ),
                InkWell(
                  onTap: () {
                    _addZawaZawaImage();
                    _incrementCounterInFirestore('counter', 'zawazawa');
                  },
                  child: Image.asset(
                    'assets/zawazawa.png',
                    width: 80, // サイズを100ピクセルに拡大
                    height: 75,
                  ),
                ),
                InkWell(
                  onTap: () {
                    _addMesomesoImage();
                    _incrementCounterInFirestore('counter', 'mesomeso');
                  },
                  child: Image.asset(
                    'assets/mesomeso.png',
                    width: 80, // サイズを100ピクセルに拡大
                    height: 75,
                  ),
                ),
                InkWell(
                  onTap: () {
                    _addAwaawaImage();
                    _incrementCounterInFirestore('counter', 'awaawa');
                  },
                  child: Image.asset(
                    'assets/awaawa.png',
                    width: 80, // サイズを100ピクセルに拡大
                    height: 75,
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
