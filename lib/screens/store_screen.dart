import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/player_data.dart';
import '../models/store_item.dart';
import '../services/iap_service.dart';
import '../services/save_service.dart';
import '../services/store_service.dart';
import '../utils/constants.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  @override
  Widget build(BuildContext context) {
    final items = StoreService.instance.items;
    return Scaffold(
      backgroundColor: AppConstants.uiDark,
      appBar: AppBar(
        backgroundColor: AppConstants.uiDark,
        title: Text(
          'Avatar Shop',
          style: GoogleFonts.fredoka(color: AppConstants.foamWhite),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppConstants.foamWhite),
          onPressed: () => context.go('/menu'),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Text(
                '${SaveService.instance.data.coins} bits',
                style: GoogleFonts.fredoka(
                  color: AppConstants.accentYellow,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppConstants.uiDark, AppConstants.uiPanel],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            _section('Bubble Bits',
                items.where((i) => i.type == StoreItemType.iapCoins)),
            _section('Arcade Pass',
                items.where((i) => i.type == StoreItemType.iapNoAds)),
            _section('Dino Avatars',
                items.where((i) => i.type == StoreItemType.character)),
            _section('Power Bubbles',
                items.where((i) => i.type == StoreItemType.powerup)),
            _section('Extra Lives',
                items.where((i) => i.type == StoreItemType.life)),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, Iterable<StoreItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
          child: Text(
            title,
            style: GoogleFonts.fredoka(
              color: AppConstants.foamWhite,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        for (final item in items) _itemCard(item),
      ],
    );
  }

  Widget _itemCard(StoreItem item) {
    final owned = StoreService.instance.isOwned(item);
    final priceLabel = StoreService.instance.priceLabelFor(item);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppConstants.uiCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppConstants.bubbleBlue.withValues(alpha: 0.18),
              shape: BoxShape.circle,
              border: Border.all(
                  color: AppConstants.foamWhite.withValues(alpha: 0.4)),
            ),
            child: Text(
              item.emoji,
              style: GoogleFonts.fredoka(
                color: AppConstants.foamWhite,
                fontSize: item.emoji.length > 2 ? 14 : 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: GoogleFonts.fredoka(
                    color: AppConstants.foamWhite,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  item.description,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: owned ? null : () => _onBuy(item),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.bubbleBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              owned ? 'OWNED' : priceLabel,
              style: GoogleFonts.fredoka(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onBuy(StoreItem item) async {
    if (item.iapProductId != null) {
      final ok = await IapService.instance.buy(item.iapProductId!);
      if (!ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Purchase unavailable. Try again later.')),
        );
      }
      if (!mounted) return;
      setState(() {});
      return;
    }

    final result = await StoreService.instance.purchaseWithCoins(item);
    if (!mounted) return;
    switch (result) {
      case StorePurchaseResult.success:
        if (item.id == 'char_phoenix') {
          await SaveService.instance
              .setSelectedCharacter(CharacterType.phoenix.id);
        } else if (item.id == 'char_shadow') {
          await SaveService.instance
              .setSelectedCharacter(CharacterType.shadow.id);
        }
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Purchased ${item.name}!')),
        );
        break;
      case StorePurchaseResult.notEnoughCoins:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Not enough coins.')),
        );
        break;
      case StorePurchaseResult.failed:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purchase failed.')),
        );
        break;
    }
    setState(() {});
  }
}
