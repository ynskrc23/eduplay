import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io';

class AdMobService {
  static final AdMobService _instance = AdMobService._internal();
  factory AdMobService() => _instance;
  AdMobService._internal();

  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdReady = false;

  RewardedAd? _rewardedAd;
  bool _isRewardedAdReady = false;

  // Eski oyunda bir sayaç mantığı kaldırıldı, artık her oyun reklam tetikleyecek
  // Süre kontrolü (Cooldown) eklendi
  DateTime? _lastAdShowTime;
  static const int _minSecondsBetweenAds =
      180; // İki reklam arasında en az kaç saniye olması gerektiği (3 dk)

  // AdMob App ID ve Ad Unit ID'leri (Platform bazlı)
  // Android
  static const String _androidAppId = 'ca-app-pub-9933328519370940~7383967585';
  static const String _androidInterstitialAdUnitId =
      'ca-app-pub-9933328519370940/2107590173';

  // iOS
  static const String _iosAppId = 'ca-app-pub-9933328519370940~9948318108';
  static const String _iosInterstitialAdUnitId =
      'ca-app-pub-9933328519370940/5796495691';

  // Lütfen AdMob'dan "Ödüllü Reklam" birimi oluşturup gerçek ID'leri buraya giriniz. Şu an test ID'leri var.
  static const String _androidRewardedAdUnitId =
      'ca-app-pub-9933328519370940/5866881525';
  static const String _iosRewardedAdUnitId =
      'ca-app-pub-9933328519370940/3082268642';

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

  static String get rewardedAdUnitId {
    if (_isTestMode) {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/5224354917'
          : 'ca-app-pub-3940256099942544/1712485313';
    }
    return Platform.isAndroid ? _androidRewardedAdUnitId : _iosRewardedAdUnitId;
  }

  /// AdMob SDK'yı başlat
  Future<void> initialize() async {
    await MobileAds.instance.initialize();

    // Aile Politikası (Family Policy) için reklamları çocuklara yönelik olarak yapılandır
    RequestConfiguration requestConfiguration = RequestConfiguration(
      tagForChildDirectedTreatment: TagForChildDirectedTreatment.yes,
      maxAdContentRating: MaxAdContentRating.g,
    );
    MobileAds.instance.updateRequestConfiguration(requestConfiguration);

    _loadInterstitialAd();
    _loadRewardedAd();
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
          _interstitialAd!.fullScreenContentCallback =
              FullScreenContentCallback(
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

  /// Oyun tamamlandığında çağrılır - süre engelini aşmışsa her oyun gösterilecek
  void onGameCompleted() {
    showInterstitialAd();
  }

  /// Interstitial reklamı göster
  void showInterstitialAd() {
    // 1. Süre Kontrolü (Zaman Sınırlaması)
    if (_lastAdShowTime != null) {
      final difference = DateTime.now().difference(_lastAdShowTime!);
      if (difference.inSeconds < _minSecondsBetweenAds) {
        print(
          'Reklam göstermek için çok erken. Kalan süre: ${_minSecondsBetweenAds - difference.inSeconds} saniye',
        );
        return; // Süre dolmadıysa reklamı kesinkes gösterme ve iptal et
      }
    }

    // 2. Reklam Hazır Mı Kontrolü
    if (_isInterstitialAdReady && _interstitialAd != null) {
      _interstitialAd!.show(); // Reklamı ekrana ver
      _lastAdShowTime =
          DateTime.now(); // Ne zaman ekranda gösterildiğini kaydet
      _isInterstitialAdReady = false;
    } else {
      print('Interstitial ad not ready yet.');
      _loadInterstitialAd(); // Hazır değilse yükle
    }
  }

  /// Ödüllü (Rewarded) reklam yükle
  void _loadRewardedAd() {
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedAdReady = true;
        },
        onAdFailedToLoad: (error) {
          print('Rewarded ad failed to load: $error');
          _isRewardedAdReady = false;
          // 30 saniye sonra tekrar dene
          Future.delayed(const Duration(seconds: 30), _loadRewardedAd);
        },
      ),
    );
  }

  /// Ödüllü (Rewarded) reklamı göster (Bunu Can/Hak bittiğinde çağıracağız)
  void showRewardedAd({
    required Function() onRewardEarned,
    required Function() onAdClosed,
    required Function() onAdFailedToLoad,
  }) {
    if (_isRewardedAdReady && _rewardedAd != null) {
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _isRewardedAdReady = false;
          _loadRewardedAd();
          onAdClosed();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _isRewardedAdReady = false;
          _loadRewardedAd();
          onAdFailedToLoad();
        },
      );

      _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          onRewardEarned();
        },
      );
      _rewardedAd = null;
      _isRewardedAdReady = false;
    } else {
      print('Rewarded ad not ready yet.');
      _loadRewardedAd();
      onAdFailedToLoad();
    }
  }

  /// Kaynakları temizle
  void dispose() {
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    _interstitialAd = null;
    _rewardedAd = null;
    _isInterstitialAdReady = false;
    _isRewardedAdReady = false;
  }
}
