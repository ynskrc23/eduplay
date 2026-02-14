import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io';

class AdMobService {
  static final AdMobService _instance = AdMobService._internal();
  factory AdMobService() => _instance;
  AdMobService._internal();

  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdReady = false;
  int _gameCompletionCount = 0;
  static const int _showAdAfterGames = 3; // Her 3 oyunda bir reklam göster

  // AdMob App ID ve Ad Unit ID'leri (Platform bazlı)
  // Android
  static const String _androidAppId = 'ca-app-pub-9933328519370940~7383967585';
  static const String _androidInterstitialAdUnitId = 'ca-app-pub-9933328519370940/2107590173';
  
  // iOS
  static const String _iosAppId = 'ca-app-pub-9933328519370940~9948318108';
  static const String _iosInterstitialAdUnitId = 'ca-app-pub-9933328519370940/5796495691';

  // Test modunda mı kontrol et (geliştirme sırasında test ID'leri kullan)
  static bool get _isTestMode => false; // Production'da false yapın

  static String get appId {
    return Platform.isAndroid ? _androidAppId : _iosAppId;
  }

  static String get interstitialAdUnitId {
    if (_isTestMode) {
      // Test Ad Unit ID'leri
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/1033173712' // Android test ID
          : 'ca-app-pub-3940256099942544/4411468910'; // iOS test ID
    }
    // Production Ad Unit ID'leri
    return Platform.isAndroid 
        ? _androidInterstitialAdUnitId 
        : _iosInterstitialAdUnitId;
  }

  /// AdMob SDK'yı başlat
  Future<void> initialize() async {
    await MobileAds.instance.initialize();
    _loadInterstitialAd();
  }

  /// Interstitial reklam yükle
  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialAdReady = true;

          // Reklam kapatıldığında yeni reklam yükle
          _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _isInterstitialAdReady = false;
              _loadInterstitialAd(); // Yeni reklam yükle
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _isInterstitialAdReady = false;
              _loadInterstitialAd(); // Yeni reklam yükle
            },
          );
        },
        onAdFailedToLoad: (error) {
          print('Interstitial ad failed to load: $error');
          _isInterstitialAdReady = false;
          // 30 saniye sonra tekrar dene
          Future.delayed(const Duration(seconds: 30), _loadInterstitialAd);
        },
      ),
    );
  }

  /// Oyun tamamlandığında çağrılır - her 3 oyunda bir reklam gösterir
  void onGameCompleted() {
    _gameCompletionCount++;
    
    if (_gameCompletionCount >= _showAdAfterGames) {
      showInterstitialAd();
      _gameCompletionCount = 0; // Sayacı sıfırla
    }
  }

  /// Interstitial reklamı göster
  void showInterstitialAd() {
    if (_isInterstitialAdReady && _interstitialAd != null) {
      _interstitialAd!.show();
      _isInterstitialAdReady = false;
    } else {
      print('Interstitial ad not ready yet.');
      _loadInterstitialAd(); // Hazır değilse yükle
    }
  }

  /// Kaynakları temizle
  void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isInterstitialAdReady = false;
  }
}
