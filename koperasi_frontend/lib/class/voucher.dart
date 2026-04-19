class Voucher {
  final int id;
  final String name;
  final String description;
  final int requiredPoints;
  final int discountPercent;
  final int maxDiscountAmount;
  final int minimumPurchaseAmount;
  final String image;
  final String expiresAt;

  Voucher({
    required this.id,
    required this.name,
    required this.description,
    required this.requiredPoints,
    required this.discountPercent,
    required this.maxDiscountAmount,
    required this.minimumPurchaseAmount,
    required this.image,
    required this.expiresAt,
  });

  factory Voucher.fromJson(Map<String, dynamic> json) {
    return Voucher(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      requiredPoints: json['required_points'] ?? 0,
      discountPercent: json['discount_amount'] ?? 0,
      maxDiscountAmount: json['max_discount_amount'] ?? 0,
      minimumPurchaseAmount: json['minimum_purchase_amount'] ?? 0,
      image: json['image'] ?? '',
      expiresAt: json['expired_at'] ?? '',
    );
  }
}
