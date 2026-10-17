import 'dart:convert';

class PlayerFieldRequirement {
  final String key;
  final String label;
  final String regex;
  final String hint;

  const PlayerFieldRequirement({
    required this.key,
    required this.label,
    required this.regex,
    required this.hint,
  });

  factory PlayerFieldRequirement.fromJson(Map<String, dynamic> json) {
    return PlayerFieldRequirement(
      key: json['key'] ?? 'player_id',
      label: json['label'] ?? 'Player UID',
      regex: json['regex'] ?? '.*',
      hint: json['hint'] ?? '',
    );
  }
}

class TopUpPackageModel {
  final String id;
  final String gameId;
  final String name;
  final String itemQuantity;
  final double price;
  final String? badge;
  final int sortOrder;

  const TopUpPackageModel({
    required this.id,
    required this.gameId,
    required this.name,
    required this.itemQuantity,
    required this.price,
    this.badge,
    this.sortOrder = 0,
  });

  factory TopUpPackageModel.fromJson(Map<String, dynamic> json) {
    return TopUpPackageModel(
      id: json['id'] ?? '',
      gameId: json['game_id'] ?? '',
      name: json['name'] ?? '',
      itemQuantity: json['item_quantity'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      badge: json['badge'],
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }
}

class GameModel {
  final String id;
  final String name;
  final String slug;
  final String category;
  final String icon;
  final String banner;
  final bool active;
  final String deliveryMethod;
  final List<PlayerFieldRequirement> requiredFields;
  final List<TopUpPackageModel> packages;

  const GameModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.category,
    required this.icon,
    required this.banner,
    this.active = true,
    this.deliveryMethod = 'auto_api',
    this.requiredFields = const [],
    this.packages = const [],
  });

  GameModel copyWith({List<TopUpPackageModel>? packages}) {
    return GameModel(
      id: id,
      name: name,
      slug: slug,
      category: category,
      icon: icon,
      banner: banner,
      active: active,
      deliveryMethod: deliveryMethod,
      requiredFields: requiredFields,
      packages: packages ?? this.packages,
    );
  }

  factory GameModel.fromJson(Map<String, dynamic> json) {
    List<PlayerFieldRequirement> fields = [];
    if (json['required_player_fields'] != null) {
      dynamic rawFields = json['required_player_fields'];
      if (rawFields is String) {
        try {
          rawFields = jsonDecode(rawFields);
        } catch (_) {
          rawFields = [];
        }
      }
      if (rawFields is List) {
        fields = rawFields.map((f) => PlayerFieldRequirement.fromJson(f as Map<String, dynamic>)).toList();
      }
    }

    List<TopUpPackageModel> pkgs = [];
    if (json['packages'] is List) {
      pkgs = (json['packages'] as List)
          .map((p) => TopUpPackageModel.fromJson(p as Map<String, dynamic>))
          .toList();
    }

    return GameModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      category: json['category'] ?? 'Battle Royale',
      icon: json['icon'] ?? '🎮',
      banner: json['banner'] ?? '',
      active: json['active'] == 1 || json['active'] == true,
      deliveryMethod: json['delivery_method'] ?? 'auto_api',
      requiredFields: fields,
      packages: pkgs,
    );
  }
}
