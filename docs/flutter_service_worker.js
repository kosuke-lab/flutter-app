'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"flutter_bootstrap.js": "2b53f92a87ee60c67643831d7f13f02c",
"version.json": "15235b5108d6a877ef74fe3317a96bf7",
"index.html": "aaa225bbb48d4817267a55f77309de40",
"/": "aaa225bbb48d4817267a55f77309de40",
"main.dart.js": "1619935dbd5083a3f4f1de5ac340dd00",
"flutter.js": "f393d3c16b631f36852323de8e583132",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"manifest.json": "fd091ea5bc8f3ccc10f74bd67179fb6a",
"assets/AssetManifest.json": "2bc1136c82334a900fda1362ccb192e6",
"assets/NOTICES": "585a017268b53db615ea339c33f53081",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/AssetManifest.bin.json": "6cf763c6b67c4cb313791e46c7d533da",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "e986ebe42ef785b27164c36a9abc7818",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/AssetManifest.bin": "0a49f60ae9c9609e948deadc31476ebc",
"assets/fonts/MaterialIcons-Regular.otf": "0db35ae7a415370b89e807027510caf0",
"assets/assets/zawa-kusa.png": "486a8005f61f882a04e72ab6debdcccb",
"assets/assets/punpun.png": "215c7e6aff878228136eef5ace84dab1",
"assets/assets/zawazawa.png": "78a49c028768e598d04d2b59e9f9aab3",
"assets/assets/meso-kusa.png": "baae5412529f91bd1c339fcb39aa8545",
"assets/assets/img.png": "4ed0a04425b824036a9cc2e45edc5dbc",
"assets/assets/background.jpg": "a903f341a13ea08e7a8a86a8ba4ecf60",
"assets/assets/fat_1_1.png": "cb9850858288cf743211d6986e2603aa",
"assets/assets/normal_2.png": "608edf3124f2becc42900846d64af8d2",
"assets/assets/normal_3.png": "0ba57ddd656c6a4aeec41e5b7d5b6867",
"assets/assets/grass.png": "a4c248be47c1bb1fb1f8162fd1850e9a",
"assets/assets/fat_3_2.png": "737de915105ff54d8e3be269d0730784",
"assets/assets/fat_1_2.png": "475452e7eabb1c9759009d9738fe11ea",
"assets/assets/normal_1.png": "063360dd84ea82f597044d478e0b12e1",
"assets/assets/fat_1_3.png": "ccf246303ced44f1c0c05d9a2762dacc",
"assets/assets/awaawa.png": "646c7b7dfa1e28690da260634b633c10",
"assets/assets/fat_3_1.png": "6b80919fef83a23483b05ec6d410d6c5",
"assets/assets/normal_4.png": "2b144218ec7a293954b1f8a83b653d58",
"assets/assets/normal_5.png": "6d5d93515ac52a1de3bb36ab9b229c2a",
"assets/assets/sample.jpg": "45eacfbb5dc0a68f1184e5272aef2f6f",
"assets/assets/fat_1_4.png": "b8a53110814f507e53bf83c557612fa9",
"assets/assets/moya-kusa.png": "adb9245cf995310f08037d788b317836",
"assets/assets/flower.png": "7a7342bf017952a0419df3a50121e9f7",
"assets/assets/mesomeso.png": "e7964a4e21ec5e04627d7f535706f2ad",
"assets/assets/fat_2_1.png": "147c9641eace3b8f5d78a451d51c2a36",
"assets/assets/fat_2_3.png": "a3406532fafb501989ebf00b90a3ae90",
"assets/assets/fat_2_2.png": "d83dd6a845dd492a619615c0ac480117",
"assets/assets/moyaamoyaa.png": "67f38ffafdbaf62f747798fd1a19c1e9",
"assets/assets/pun-kusa.png": "aca8411cea3b5ba23f8c5af38fec3224",
"assets/assets/awa-kusa.png": "166ee43cef4c9a1092d9370d187fd498",
"canvaskit/skwasm.js": "694fda5704053957c2594de355805228",
"canvaskit/skwasm.js.symbols": "262f4827a1317abb59d71d6c587a93e2",
"canvaskit/canvaskit.js.symbols": "48c83a2ce573d9692e8d970e288d75f7",
"canvaskit/skwasm.wasm": "9f0c0c02b82a910d12ce0543ec130e60",
"canvaskit/chromium/canvaskit.js.symbols": "a012ed99ccba193cf96bb2643003f6fc",
"canvaskit/chromium/canvaskit.js": "671c6b4f8fcc199dcc551c7bb125f239",
"canvaskit/chromium/canvaskit.wasm": "b1ac05b29c127d86df4bcfbf50dd902a",
"canvaskit/canvaskit.js": "66177750aff65a66cb07bb44b8c6422b",
"canvaskit/canvaskit.wasm": "1f237a213d7370cf95f443d896176460",
"canvaskit/skwasm.worker.js": "89990e8c92bcb123999aa81f7e203b1c"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
