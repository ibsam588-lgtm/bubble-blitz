import '../models/store_item.dart';
import '../utils/constants.dart';
import 'iap_service.dart';
import 'save_service.dart';

class StoreService {
  static StoreService? _instance;
  static StoreService get instance => _instance ??= StoreService._();
  StoreService._();

  static const List<StoreItem> _staticItems = [
    StoreItem(
      id: IapIds.coinpackStarter,
      name: 'Starter Bubble Bits',
      description: '2,500 bubble bits',
      emoji: 'B',
      type: StoreItemType.iapCoins,
      coinAmount: 2500,
      iapProductId: IapIds.coinpackStarter,
      priceLabel: '\$0.99',
    ),
    StoreItem(
      id: IapIds.coinpackValue,
      name: 'Hero Bubble Vault',
      description: '7,000 bubble bits',
      emoji: 'H',
      type: StoreItemType.iapCoins,
      coinAmount: 7000,
      iapProductId: IapIds.coinpackValue,
      priceLabel: '\$2.49',
    ),
    StoreItem(
      id: IapIds.coinpackMega,
      name: 'Mega Bubble Cache',
      description: '15,000 bubble bits',
      emoji: 'M',
      type: StoreItemType.iapCoins,
      coinAmount: 15000,
      iapProductId: IapIds.coinpackMega,
      priceLabel: '\$4.99',
    ),
    StoreItem(
      id: IapIds.removeAds,
      name: 'Remove Ads',
      description: 'No more ads, ever.',
      emoji: 'AD',
      type: StoreItemType.iapNoAds,
      iapProductId: IapIds.removeAds,
      priceLabel: '\$1.99',
    ),
    StoreItem(
      id: 'char_phoenix',
      name: 'Red Dino',
      description: 'A red arcade dino with white speed markings.',
      emoji: 'F',
      type: StoreItemType.character,
      coinCost: AppConstants.characterPhoenixCost,
    ),
    StoreItem(
      id: 'char_shadow',
      name: 'Blue Dino',
      description: 'A blue arcade dino for high-jump stages.',
      emoji: 'N',
      type: StoreItemType.character,
      coinCost: AppConstants.characterShadowCost,
    ),
    StoreItem(
      id: 'pack_shield',
      name: 'Bubble Shield Pack',
      description: '5 shields',
      emoji: 'SH',
      type: StoreItemType.powerup,
      coinCost: AppConstants.shieldPackCost,
    ),
    StoreItem(
      id: 'pack_speed',
      name: 'Speed Boost Pack',
      description: '5 speed boosts',
      emoji: 'SP',
      type: StoreItemType.powerup,
      coinCost: AppConstants.speedPackCost,
    ),
    StoreItem(
      id: 'pack_multibubble',
      name: 'Multi-Bubble Pack',
      description: '5 multi-bubble shots',
      emoji: 'x3',
      type: StoreItemType.powerup,
      coinCost: AppConstants.multiBubblePackCost,
    ),
    StoreItem(
      id: 'life_1',
      name: 'Extra Life',
      description: '+1 life',
      emoji: '+1',
      type: StoreItemType.life,
      coinCost: AppConstants.extraLife1Cost,
    ),
    StoreItem(
      id: 'life_5',
      name: '5 Lives Pack',
      description: '+5 lives',
      emoji: '+5',
      type: StoreItemType.life,
      coinCost: AppConstants.extraLife5Cost,
    ),
  ];

  List<StoreItem> get items => _staticItems;

  String priceLabelFor(StoreItem item) {
    if (item.iapProductId != null) {
      final product = IapService.instance.findProduct(item.iapProductId!);
      if (product != null) return product.price;
      return item.priceLabel ?? '-';
    }
    return '${item.coinCost} bits';
  }

  bool isOwned(StoreItem item) {
    final save = SaveService.instance.data;
    if (item.type == StoreItemType.iapNoAds) {
      return SaveService.instance.adsRemoved;
    }
    if (item.type == StoreItemType.character) {
      if (item.id == 'char_phoenix') {
        return save.unlockedChars.contains('phoenix');
      }
      if (item.id == 'char_shadow') {
        return save.unlockedChars.contains('shadow');
      }
    }
    return false;
  }

  Future<StorePurchaseResult> purchaseWithCoins(StoreItem item) async {
    final cost = item.coinCost;
    if (cost == null) return StorePurchaseResult.failed;
    final save = SaveService.instance;
    if (save.data.coins < cost) return StorePurchaseResult.notEnoughCoins;
    final ok = await save.spendCoins(cost);
    if (!ok) return StorePurchaseResult.notEnoughCoins;

    switch (item.id) {
      case 'char_phoenix':
        await save.unlockCharacter('phoenix');
        break;
      case 'char_shadow':
        await save.unlockCharacter('shadow');
        break;
      case 'pack_shield':
        await save.addShields(5);
        break;
      case 'pack_speed':
        await save.addSpeedBoosts(5);
        break;
      case 'pack_multibubble':
        await save.addMultiBubbles(5);
        break;
      case 'life_1':
        await save.addExtraLives(1);
        break;
      case 'life_5':
        await save.addExtraLives(5);
        break;
    }
    return StorePurchaseResult.success;
  }
}

enum StorePurchaseResult { success, notEnoughCoins, failed }
