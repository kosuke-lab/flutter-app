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
  Timer? _hourlyDataFetchTimer;
  // Firestoreから取得したカウントを保持する変数
  int punpunCount = 0;
  int moyamoyaCount = 0;
  int zawazawaCount = 0;
  int mesomesoCount = 0;
  int awaawaCount = 0;

  List<Offset> _grassPositions = []; // 草の位置を保存するリスト
  List<Widget> _images = [];
  int _removedImageCount = 0; // 草を食べた回数をカウントする変数
  double _titleImageOpacity = 1.0; // 初期値を1.0に設定（表示状態）
  String? _showTimeMessage; // 15時になったら表示するメッセージ

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
    "bb4a5169-9a03-4445-9c65-aa205fce8e34", // Prod松井
    "8f35bdd9-3ac0-430c-90a7-67918d8b3413", // local松井
    "580ddbbe-06db-4543-b5ba-f6bbff75b231",
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

  // ハードコードされたUUIDとの一致を確認し、メッセージを表示
  Future<void> checkAndShowMessage() async {
    String uuid = await getOrCreateUuid();
    setState(() {
      _isAdmin = authorizedUuids.contains(uuid);
    });
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

    // 初回データ取得
    _fetchDataFromFirestore();

    // 初期位置設定
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setInitialCenterPosition();
    });

    // 草や花を削除してキャラクターを移動させるタイマー
    _startRemovalTimer();

    // 歩行アニメーションの開始
    _startWalkingAnimation();

    // ローカルストレージから15時メッセージの表示状況をチェック
    _checkLocalTimeAndSetMessage();

    // 1時間ごとにデータを取得するタイマーを開始
    _startHourlyDataFetchTimer();
  }

  // 1時間ごとにFirestoreの値を取得
  void _startHourlyDataFetchTimer() {
    _hourlyDataFetchTimer = Timer.periodic(const Duration(hours: 1), (timer) {
      _fetchDataFromFirestore();
    });
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
        {
          'value': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      print("$documentId のカウントが増加しました");
    } catch (e) {
      print("Firestoreエラー: $e");
    }
  }

// Firestoreからデータを取得するメソッド
  Future<void> _fetchDataFromFirestore() async {
    final now = DateTime.now();
    final isAfterThreePM = now.hour >= 15;

    // 使用するコレクション名を条件に基づいて決定
    final collectionName = isAfterThreePM
        ? '${now.year}-${now.month}-${now.day}-15:00:00'
        : 'counter';

    try {
      // 各ドキュメントからカウントを取得し、それぞれの状態変数に保存
      final punpunSnapshot = await FirebaseFirestore.instance
          .collection(collectionName)
          .doc('punpun')
          .get();
      final moyamoyaSnapshot = await FirebaseFirestore.instance
          .collection(collectionName)
          .doc('moyamoya')
          .get();
      final zawazawaSnapshot = await FirebaseFirestore.instance
          .collection(collectionName)
          .doc('zawazawa')
          .get();
      final mesomesoSnapshot = await FirebaseFirestore.instance
          .collection(collectionName)
          .doc('mesomeso')
          .get();
      final awaawaSnapshot = await FirebaseFirestore.instance
          .collection(collectionName)
          .doc('awaawa')
          .get();

      setState(() {
        punpunCount = punpunSnapshot.data()?['value'] ?? 0;
        moyamoyaCount = moyamoyaSnapshot.data()?['value'] ?? 0;
        zawazawaCount = zawazawaSnapshot.data()?['value'] ?? 0;
        mesomesoCount = mesomesoSnapshot.data()?['value'] ?? 0;
        awaawaCount = awaawaSnapshot.data()?['value'] ?? 0;
      });
    } catch (e) {
      print("Firestore error: $e");
    }
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

  // ユーザーそれぞれで15時になったらメッセージを表示するための処理
  // SharedPreferencesで日付を確認し、今日15時以降ならメッセージを表示
  Future<void> _checkLocalTimeAndSetMessage() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // localStorageから最後に表示した日付を取得
    String? lastShownDateStr = html.window.localStorage['lastShownDate'];

    if (lastShownDateStr != null) {
      // 表示日が記録されている場合
      final lastShownDate = DateTime.parse(lastShownDateStr);
      final lastShownDay =
          DateTime(lastShownDate.year, lastShownDate.month, lastShownDate.day);

      if (lastShownDay != today && now.hour >= 15) {
        // 今日まだ表示されていない場合にメッセージを表示
        setState(() {
          _showTimeMessage = "＼ リセット！リセット ／";
          _walkingImages = _dietImages;
          _currentWalkingImageIndex = 0; // インデックスをリセット
        });

        // 今日の日付を保存
        html.window.localStorage['lastShownDate'] = today.toIso8601String();

        // バックアップと削除の処理をここで実行
        _backupAndDeleteCollection();

        // 45秒後に元の画像リストに戻す
        Future.delayed(const Duration(seconds: 45), () {
          setState(() {
            _updateWalkingImages(); // ここで通常の画像リストに戻す
          });
        });
      }
    } else {
      // 初回アクセスの場合
      if (now.hour >= 15) {
        setState(() {
          _showTimeMessage = "＼ リセット！リセット ／";
          _walkingImages = _dietImages;
          _currentWalkingImageIndex = 0; // インデックスをリセット
        });

        // 今日の日付を保存
        html.window.localStorage['lastShownDate'] = today.toIso8601String();

        // バックアップと削除の処理をここで実行
        _backupAndDeleteCollection();

        // 45秒後に元の画像リストに戻す
        Future.delayed(const Duration(seconds: 45), () {
          setState(() {
            _updateWalkingImages(); // ここで通常の画像リストに戻す
          });
        });
      }
    }
  }

  // 15時時点のデータをバックアップして元のコレクションを削除
  void _backupAndDeleteCollection() async {
    // バックアップコレクション名を当日の15時に固定
    final backupTimestamp = DateTime.now();
    final backupCollectionName =
        '${backupTimestamp.year}-${backupTimestamp.month}-${backupTimestamp.day}-15:00:00';

    // コレクションがすでに存在するかチェック
    final backupCollectionSnapshot = await FirebaseFirestore.instance
        .collection(backupCollectionName)
        .limit(1)
        .get();

    if (backupCollectionSnapshot.docs.isNotEmpty) {
      print('バックアップはすでに存在します。処理を終了します。');
      return;
    }

    FirebaseFirestore.instance
        .collection('counter')
        .where('updatedAt',
            isLessThanOrEqualTo:
                Timestamp.fromDate(DateTime.now())) // 15時以前のデータのみ
        .get()
        .then((snapshot) async {
      for (DocumentSnapshot doc in snapshot.docs) {
        // 新しいコレクションにデータとバックアップタイムスタンプを追加
        await FirebaseFirestore.instance
            .collection(backupCollectionName)
            .doc(doc.id)
            .set({
          'value': doc['value'],
          'updatedAt': doc['updatedAt'],
          'backupTimestamp':
              FieldValue.serverTimestamp(), // バックアップ実行時のタイムスタンプを保存
        });
        // 元のコレクションから削除
        await doc.reference.delete();
      }
      print('15時以前のデータをバックアップし、元のコレクションから削除しました');
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

          // 草を食べた後にメッセージを表示
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
    _hourlyDataFetchTimer?.cancel(); // タイマーを停止
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
            bottom: 110,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _isAdmin
                  ? [
                      Column(
                        children: [
                          Text('$punpunCount',
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold)),
                          const Text('プンプン'),
                        ],
                      ),
                      Column(
                        children: [
                          Text('$moyamoyaCount',
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold)),
                          const Text('モヤモヤ'),
                        ],
                      ),
                      Column(
                        children: [
                          Text('$zawazawaCount',
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold)),
                          const Text('ザワザワ'),
                        ],
                      ),
                      Column(
                        children: [
                          Text('$mesomesoCount',
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold)),
                          const Text('メソメソ'),
                        ],
                      ),
                      Column(
                        children: [
                          Text('$awaawaCount',
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold)),
                          const Text('アワアワ'),
                        ],
                      ),
                    ]
                  : [],
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

          //  15時になったら表示するメッセージ
          if (_showTimeMessage != null)
            Positioned(
              top: 150,
              left: 0,
              right: 0,
              child: Text(
                _showTimeMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
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
                    width: 75, // サイズを100ピクセルに拡大
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
                    width: 75, // サイズを100ピクセルに拡大
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
                    width: 75, // サイズを100ピクセルに拡大
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
                    width: 75, // サイズを100ピクセルに拡大
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
                    width: 75, // サイズを100ピクセルに拡大
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
