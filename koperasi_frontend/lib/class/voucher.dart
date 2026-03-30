class Voucher {
  final int id;
  final String name;
  final int requiredPoints;

  Voucher({
    required this.id,
    required this.name,
    required this.requiredPoints,
  });

  factory Voucher.fromJson(Map<String, dynamic> json) {
    return Voucher(
      id: json['id'],
      name: json['name'] ?? '',
      requiredPoints: json['required_points'] ?? 0,
    );
  }
}