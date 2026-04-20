import 'package:flutter/material.dart';

class MyLevelPage extends StatelessWidget {
  final int annualSpend;
  final String membershipLevel;

  const MyLevelPage({
    super.key,
    required this.annualSpend,
    required this.membershipLevel,
  });

  static const List<Map<String, dynamic>> levels = [
    {"name": "Bronze", "min": 0, "max": 999999, "color": Color(0xFF8D5A3B)},
    {"name": "Silver", "min": 1000000, "max": 2999999, "color": Color(0xFF78909C)},
    {"name": "Gold", "min": 3000000, "max": 4999999, "color": Color(0xFFC69214)},
    {"name": "Platinum", "min": 5000000, "max": null, "color": Color(0xFF455A64)},
  ];

  String formatCurrency(int amount) {
    return "Rp ${amount.toString().replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => '.',
        )}";
  }

  Map<String, dynamic> getCurrentLevel() {
    return levels.firstWhere(
      (level) => level["name"].toString().toLowerCase() == membershipLevel.toLowerCase(),
      orElse: () => levels.first,
    );
  }

  Map<String, dynamic>? getNextLevel() {
    final currentIndex = levels.indexWhere(
      (level) => level["name"].toString().toLowerCase() == membershipLevel.toLowerCase(),
    );

    if (currentIndex == -1 || currentIndex == levels.length - 1) {
      return null;
    }

    return levels[currentIndex + 1];
  }

  double getProgressValue() {
    final current = getCurrentLevel();
    final next = getNextLevel();

    if (next == null) {
      return 1;
    }

    final currentMin = current["min"] as int;
    final nextMin = next["min"] as int;
    final range = nextMin - currentMin;

    if (range <= 0) {
      return 1;
    }

    final progress = (annualSpend - currentMin) / range;
    return progress.clamp(0, 1);
  }

  @override
  Widget build(BuildContext context) {
    final currentLevel = getCurrentLevel();
    final nextLevel = getNextLevel();
    final progress = getProgressValue();
    final currentColor = currentLevel["color"] as Color;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F6),
      appBar: AppBar(
        title: const Text("Level Club"),
        backgroundColor: const Color(0xFFB71C1C),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFB71C1C), Color(0xFFD32F2F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.shade100,
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "KOPBENEFIT LEVEL",
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          membershipLevel,
                          style: TextStyle(
                            color: currentColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            "Belanja 1 Tahun",
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          Text(
                            formatCurrency(annualSpend),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              currentLevel["name"],
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              nextLevel == null ? "Level tertinggi" : nextLevel["name"],
                              style: const TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 18,
                            backgroundColor: Colors.white24,
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          nextLevel == null
                              ? "Kamu sudah berada di level tertinggi."
                              : "Belanja ${formatCurrency((nextLevel["min"] as int) - annualSpend)} lagi untuk naik ke ${nextLevel["name"]}.",
                          style: const TextStyle(
                            color: Colors.white,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Tahapan Level",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFFB71C1C),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Naik level berdasarkan total belanja yang sudah diambil dalam 1 tahun.",
              style: TextStyle(
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            ...levels.map((level) {
              final isActive = level["name"] == membershipLevel;
              final color = level["color"] as Color;
              final min = level["min"] as int;
              final max = level["max"] as int?;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isActive ? color : Colors.red.shade100,
                    width: isActive ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.shade50,
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.workspace_premium_rounded,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            level["name"],
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            max == null
                                ? "Mulai ${formatCurrency(min)}"
                                : "${formatCurrency(min)} - ${formatCurrency(max)}",
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          "Level kamu",
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
