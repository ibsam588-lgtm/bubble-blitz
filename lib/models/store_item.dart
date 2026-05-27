enum StoreItemType { iapCoins, iapNoAds, character, powerup, life }

class StoreItem {
  final String id;
  final String name;
  final String description;
  final String emoji;
  final StoreItemType type;
  final int? coinCost;
  final int? coinAmount;
  final String? iapProductId;
  final String? priceLabel;

  const StoreItem({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.type,
    this.coinCost,
    this.coinAmount,
    this.iapProductId,
    this.priceLabel,
  });
}
