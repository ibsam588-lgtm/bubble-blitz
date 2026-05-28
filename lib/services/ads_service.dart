import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../utils/constants.dart';
import 'save_service.dart';

class AdsService {
  static AdsService? _instance;
  static AdsService get instance => _instance ??= AdsService._();
  AdsService._();

  bool _initialized = false;
  RewardedAd? _rewardedAd;
  bool _loadingRewarded = false;

  Future<void> init() async {
    if (_initialized) return;
    if (kIsWeb) {
      _initialized = true;
      return;
    }
    try {
      await MobileAds.instance.initialize();
      _initialized = true;
      loadRewardedAd();
    } catch (e) {
      if (kDebugMode) debugPrint('AdsService init failed: $e');
    }
  }

  bool get adsRemoved => SaveService.instance.adsRemoved;

  BannerAd? createBannerAd() {
    if (kIsWeb || adsRemoved) return null;
    try {
      final ad = BannerAd(
        adUnitId: AdMobIds.bannerAdUnitId,
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdFailedToLoad: (ad, error) {
            ad.dispose();
            if (kDebugMode) debugPrint('Banner failed: $error');
          },
        ),
      );
      ad.load();
      return ad;
    } catch (e) {
      if (kDebugMode) debugPrint('createBannerAd error: $e');
      return null;
    }
  }

  void loadRewardedAd() {
    if (kIsWeb) return;
    if (adsRemoved) return;
    if (_loadingRewarded || _rewardedAd != null) return;
    _loadingRewarded = true;
    try {
      RewardedAd.load(
        adUnitId: AdMobIds.rewardedAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _rewardedAd = ad;
            _loadingRewarded = false;
          },
          onAdFailedToLoad: (error) {
            _rewardedAd = null;
            _loadingRewarded = false;
            if (kDebugMode) debugPrint('Rewarded failed: $error');
          },
        ),
      );
    } catch (e) {
      _loadingRewarded = false;
      if (kDebugMode) debugPrint('loadRewardedAd error: $e');
    }
  }

  Future<bool> showRewardedAd() async {
    if (kIsWeb) return false;
    if (adsRemoved) return false;
    final ad = _rewardedAd;
    if (ad == null) {
      loadRewardedAd();
      return false;
    }
    bool earned = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        loadRewardedAd();
      },
    );
    try {
      await ad.show(onUserEarnedReward: (_, __) {
        earned = true;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('showRewardedAd error: $e');
    }
    return earned;
  }
}
