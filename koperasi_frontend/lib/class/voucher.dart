class Voucher {
  final int id;
  final String name;
  final String description;
  final int requiredPoints;
  final int discountPercent;
  final int maxDiscountAmount;

  Voucher({
    required this.id,
    required this.name,
    required this.description,
    required this.requiredPoints,
    required this.discountPercent,
    required this.maxDiscountAmount,
  });

  factory Voucher.fromJson(Map<String, dynamic> json) {
    return Voucher(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      requiredPoints: json['required_points'] ?? 0,
      discountPercent: json['discount_amount'] ?? 0,
      maxDiscountAmount: json['max_discount_amount'] ?? 0,
    );
  }
}
