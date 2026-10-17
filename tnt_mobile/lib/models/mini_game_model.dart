class MiniGameModel {
  final String id;
  final String title;
  final String subtitle;
  final String category;
  final String icon;
  final String iconImage;
  final String banner;
  final double rating;
  final String playsCount;
  final int rewardCoins;
  final String? externalUrl;
  final String likeRatio;
  final String activePlaying;
  final String developer;

  const MiniGameModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.icon,
    this.iconImage = '',
    required this.banner,
    this.rating = 4.9,
    this.playsCount = '12.4K',
    this.rewardCoins = 25,
    this.externalUrl,
    this.likeRatio = '96%',
    this.activePlaying = '14.2K',
    this.developer = 'TNT Gaming Studio',
  });

  String get effectiveIconImage => iconImage.isNotEmpty ? iconImage : banner;
}
