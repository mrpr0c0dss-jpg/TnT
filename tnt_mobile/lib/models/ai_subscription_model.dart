class AiToolModel {
  final String id;
  final String name;
  final String description;
  final String icon;
  final double monthlyPrice;
  final double yearlyPrice;
  final String category;

  const AiToolModel({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.monthlyPrice,
    required this.yearlyPrice,
    required this.category,
  });

  factory AiToolModel.fromJson(Map<String, dynamic> json) {
    return AiToolModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      icon: json['icon'] ?? '🤖',
      monthlyPrice: (json['monthly_price'] as num?)?.toDouble() ?? 20.0,
      yearlyPrice: (json['yearly_price'] as num?)?.toDouble() ?? 200.0,
      category: json['category'] ?? 'LLM',
    );
  }

  static const List<AiToolModel> seedTools = [
    AiToolModel(
      id: 'ai_chatgpt',
      name: 'ChatGPT Plus',
      description: 'GPT-4o, DALL·E 3, Advanced Voice Mode & Custom GPTs',
      icon: '🤖',
      monthlyPrice: 20.0,
      yearlyPrice: 219.0,
      category: 'LLM & Reasoning',
    ),
    AiToolModel(
      id: 'ai_claude',
      name: 'Claude 3.5 Pro',
      description: 'Claude 3.5 Sonnet, 200K Context Window & Artifacts',
      icon: '🧠',
      monthlyPrice: 20.0,
      yearlyPrice: 219.0,
      category: 'Coding & Analysis',
    ),
    AiToolModel(
      id: 'ai_midjourney',
      name: 'Midjourney Pro',
      description: 'Photorealistic AI Art generation & Fast GPU Hours',
      icon: '🎨',
      monthlyPrice: 30.0,
      yearlyPrice: 288.0,
      category: 'Generative Art',
    ),
    AiToolModel(
      id: 'ai_cursor',
      name: 'Cursor Pro',
      description: 'AI Code Editor with multi-file edits & Claude integration',
      icon: '💻',
      monthlyPrice: 20.0,
      yearlyPrice: 192.0,
      category: 'Developer Tools',
    ),
    AiToolModel(
      id: 'ai_perplexity',
      name: 'Perplexity Pro',
      description: 'Pro search with academic citations & multi-model toggle',
      icon: '🔍',
      monthlyPrice: 20.0,
      yearlyPrice: 200.0,
      category: 'AI Search',
    ),
    AiToolModel(
      id: 'ai_copilot',
      name: 'GitHub Copilot',
      description: 'Official GitHub pair programmer & workspace completions',
      icon: '🐙',
      monthlyPrice: 10.0,
      yearlyPrice: 100.0,
      category: 'Developer Tools',
    ),
  ];
}

class AiSubscriptionModel {
  final String id;
  final String toolId;
  final String toolName;
  final String planName;
  final String? licenseKey;
  final String status; // 'ACTIVE', 'EXPIRED', 'PENDING'
  final DateTime startsAt;
  final DateTime expiresAt;

  const AiSubscriptionModel({
    required this.id,
    required this.toolId,
    required this.toolName,
    required this.planName,
    this.licenseKey,
    required this.status,
    required this.startsAt,
    required this.expiresAt,
  });

  factory AiSubscriptionModel.fromJson(Map<String, dynamic> json) {
    return AiSubscriptionModel(
      id: json['id'] ?? '',
      toolId: json['tool_id'] ?? '',
      toolName: json['tool_name'] ?? 'AI Tool',
      planName: json['plan_name'] ?? '1-Month Pro',
      licenseKey: json['license_key'],
      status: json['status'] ?? 'ACTIVE',
      startsAt: DateTime.tryParse(json['starts_at'] ?? '') ?? DateTime.now(),
      expiresAt: DateTime.tryParse(json['expires_at'] ?? '') ?? DateTime.now().add(const Duration(days: 30)),
    );
  }
}
