import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../services/report_service.dart';
import '../drawer/drawer_admin.dart';

class ReportAdminPage extends StatefulWidget {
  const ReportAdminPage({super.key});

  @override
  State<ReportAdminPage> createState() => _ReportAdminPageState();
}

class _ReportAdminPageState extends State<ReportAdminPage> {
  late Future<Map<String, dynamic>> futureSummary;

  @override
  void initState() {
    super.initState();
    loadSummary();
  }

  void loadSummary() {
    futureSummary = ReportService.getSummary();
  }

  Future<void> refreshData() async {
    setState(() {
      loadSummary();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AdminDrawer(),
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          "Laporan",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.red.shade700,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: RefreshIndicator(
        color: Colors.red.shade700,
        onRefresh: refreshData,
        child: FutureBuilder<Map<String, dynamic>>(
          future: futureSummary,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(color: Colors.red.shade700),
              );
            }

            final report = snapshot.data ?? {};
            final overview =
                _asMap(report['overview']);
            final monthlySales =
                _asList(report['monthly_sales']);
            final workerTotals =
                _asList(report['worker_totals']);
            final topProducts =
                _asList(report['top_products']);
            final paymentMethods =
                _asList(report['payment_method_breakdown']);

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildHeaderCard(overview),
                const SizedBox(height: 16),
                _buildOverviewCards(overview),
                const SizedBox(height: 16),
                _buildMonthlySalesChart(monthlySales),
                const SizedBox(height: 16),
                _buildWorkerTotals(workerTotals),
                const SizedBox(height: 16),
                _buildPaymentMethodChart(paymentMethods),
                const SizedBox(height: 16),
                _buildTopProducts(topProducts),
              ],
            );
          },
        ),
      ),
    );
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    return {};
  }

  List<Map<String, dynamic>> _asList(dynamic value) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    return [];
  }

  Widget _buildHeaderCard(Map<String, dynamic> overview) {
    final year = overview['year']?.toString() ?? DateTime.now().year.toString();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade700, Colors.red.shade500],
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.query_stats,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Ringkasan Laporan",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Data penjualan dan aktivitas koperasi tahun $year",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCards(Map<String, dynamic> overview) {
    final itemsThisMonth = _toInt(overview['total_items_this_month']);
    final revenueThisMonth = _toInt(overview['total_revenue_this_month']);
    final ordersThisMonth = _toInt(overview['total_orders_this_month']);

    return Row(
      children: [
        Expanded(
          child: _buildSmallCard(
            title: "Barang Terjual",
            value: "$itemsThisMonth",
            subtitle: "bulan ini",
            icon: Icons.inventory_2,
            color: Colors.red.shade700,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSmallCard(
            title: "Transaksi",
            value: "$ordersThisMonth",
            subtitle: "bulan ini",
            icon: Icons.receipt_long,
            color: Colors.orange.shade700,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSmallCard(
            title: "Omzet",
            value: _formatCurrency(revenueThisMonth),
            subtitle: "bulan ini",
            icon: Icons.payments,
            color: Colors.blue.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildSmallCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.grey.shade900,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlySalesChart(List<Map<String, dynamic>> monthlySales) {
    final hasData =
        monthlySales.any((item) => _toInt(item['total_quantity']) > 0);

    return _buildSectionCard(
      title: "Jumlah Penjualan Barang per Bulan",
      subtitle: "Diagram batang jumlah barang terjual setiap bulan",
      child: hasData
          ? SizedBox(
              height: 260,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _getMaxMonthlyValue(monthlySales) + 5,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 5,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: Colors.grey.shade200,
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 34,
                        getTitlesWidget: (value, meta) => Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= monthlySales.length) {
                            return const SizedBox.shrink();
                          }

                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              monthlySales[index]['month_name']?.toString() ?? '',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: monthlySales.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;

                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: _toInt(item['total_quantity']).toDouble(),
                          color: Colors.red.shade600,
                          width: 16,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            )
          : _buildEmptyChart("Belum ada penjualan selesai di tahun ini"),
    );
  }

  Widget _buildWorkerTotals(List<Map<String, dynamic>> workerTotals) {
    return _buildSectionCard(
      title: "Total Nominal Transaksi per Worker",
      subtitle: "Khusus role worker",
      child: workerTotals.isEmpty
          ? _buildEmptyChart("Belum ada data transaksi worker")
          : Column(
              children: workerTotals.map((worker) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.person,
                          color: Colors.red.shade700,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              worker['worker_name']?.toString() ?? '-',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${_toInt(worker['total_transactions'])} transaksi",
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        _formatCurrency(_toInt(worker['total_nominal'])),
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildPaymentMethodChart(List<Map<String, dynamic>> paymentMethods) {
    final colors = [
      Colors.red.shade600,
      Colors.orange.shade600,
      Colors.blue.shade600,
      Colors.green.shade600,
    ];

    return _buildSectionCard(
      title: "Komposisi Metode Pembayaran",
      subtitle: "Rekomendasi tambahan untuk membaca kebiasaan transaksi",
      child: paymentMethods.isEmpty
          ? _buildEmptyChart("Belum ada data metode pembayaran")
          : Column(
              children: [
                SizedBox(
                  height: 220,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 4,
                      centerSpaceRadius: 46,
                      sections: paymentMethods.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        final totalOrders = _toInt(item['total_orders']).toDouble();

                        return PieChartSectionData(
                          color: colors[index % colors.length],
                          value: totalOrders,
                          radius: 62,
                          title: "${totalOrders.toInt()}",
                          titleStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ...paymentMethods.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: colors[index % colors.length],
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _formatPaymentMethod(item['payment_method']?.toString() ?? ''),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          "${_toInt(item['total_orders'])} order",
                          style: TextStyle(
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
    );
  }

  Widget _buildTopProducts(List<Map<String, dynamic>> topProducts) {
    return _buildSectionCard(
      title: "Produk Terlaris",
      subtitle: "Rekomendasi tambahan untuk stok dan restock",
      child: topProducts.isEmpty
          ? _buildEmptyChart("Belum ada data produk terlaris")
          : Column(
              children: topProducts.asMap().entries.map((entry) {
                final index = entry.key + 1;
                final product = entry.value;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text(
                            "$index",
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product['product_name']?.toString() ?? '-',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${_toInt(product['total_quantity'])} item terjual",
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        _formatCurrency(_toInt(product['total_nominal'])),
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _buildEmptyChart(String text) {
    return SizedBox(
      height: 140,
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is double) {
      return value.toInt();
    }

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _getMaxMonthlyValue(List<Map<String, dynamic>> monthlySales) {
    if (monthlySales.isEmpty) {
      return 10;
    }

    final maxValue = monthlySales
        .map((item) => _toInt(item['total_quantity']).toDouble())
        .reduce((a, b) => a > b ? a : b);

    return maxValue <= 0 ? 10 : maxValue;
  }

  String _formatCurrency(int value) {
    final text = value.toString();
    final buffer = StringBuffer();
    int count = 0;

    for (int i = text.length - 1; i >= 0; i--) {
      buffer.write(text[i]);
      count++;
      if (count % 3 == 0 && i != 0) {
        buffer.write('.');
      }
    }

    return "Rp ${buffer.toString().split('').reversed.join()}";
  }

  String _formatPaymentMethod(String method) {
    if (method == 'cash') {
      return 'Cash';
    }

    if (method == 'online') {
      return 'Online';
    }

    return method;
  }
}
