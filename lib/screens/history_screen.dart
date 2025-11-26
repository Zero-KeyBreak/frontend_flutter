import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<TransactionModel> transactions = [];
  List<TransactionModel> filteredTransactions = [];

  bool isLoading = true;
  String? errorMessage;

  // Y chang login + home
  final List<String> apiUrls = [
    "https://df4b91vt-4000.asse.devtunnels.ms",
    "http://10.0.2.2:4000",
    "http://localhost:4000"
  ];

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  // ====================================================
  // LOAD HISTORY
  // ====================================================
  Future<void> loadHistory() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt("user_id");

      if (userId == null) {
        setState(() {
          errorMessage = "Không tìm thấy user_id!";
          isLoading = false;
        });
        return;
      }

      http.Response? response;

      for (final base in apiUrls) {
        try {
          final uri = Uri.parse("$base/history/$userId");
          response = await http.get(uri).timeout(const Duration(seconds: 10));

          debugPrint("GET $uri → ${response.statusCode}");

          if (response.statusCode == 200 &&
              response.body.contains("transactions")) {
            break;
          }
        } catch (_) {}
      }

      if (response == null) {
        setState(() {
          errorMessage = "Không thể kết nối server!";
          isLoading = false;
        });
        return;
      }

      if (response.statusCode != 200) {
        setState(() {
          errorMessage = "Lỗi server: ${response?.statusCode}";
          isLoading = false;
        });
        return;
      }

      final data = jsonDecode(response.body);
      List<dynamic> rows = data["transactions"] ?? [];

      transactions = rows.map((e) {
        return TransactionModel(
          id: e["id"].toString(),
          date: DateTime.tryParse(e["date"] ?? "") ?? DateTime.now(),
          description: e["description"] ?? "",
          amount: double.tryParse("${e["amount"]}") ?? 0.0,
          balance: double.tryParse("${e["balance"]}") ?? 0.0,
          type: e["type"] ?? "", // ví dụ: TRANSFER_IN, TRANSFER_OUT, TOPUP_DATA,...
        );
      }).toList();

      setState(() {
        filteredTransactions = List.from(transactions);
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = "Lỗi tải lịch sử: $e";
        isLoading = false;
      });
    }
  }

  // ====================================================
  // UI
  // ====================================================

  String formatCurrency(double amount) =>
      NumberFormat("#,###", "vi_VN").format(amount.abs()) + " VND";

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<TransactionModel>>{};

    for (final t in filteredTransactions) {
      final key = DateFormat('yyyy-MM-dd').format(t.date);
      grouped.putIfAbsent(key, () => []).add(t);
    }

    final dates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Lịch sử giao dịch"),
        backgroundColor: const Color(0xFF6D32D3),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadHistory,
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Text(errorMessage!))
              : RefreshIndicator(
                  onRefresh: loadHistory,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        "${filteredTransactions.length} giao dịch",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      ...dates.map(
                        (d) => _buildDateSection(
                          DateTime.parse(d),
                          grouped[d]!,
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildDateSection(DateTime date, List<TransactionModel> list) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            DateFormat("dd/MM/yyyy").format(date),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        ...list.map(_buildTransactionItem),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTransactionItem(TransactionModel t) {
    final bool isIncome = t.amount > 0; // tiền vào
    final bool isTransferIn = t.type == 'TRANSFER_IN'; 
    // bạn chỉnh lại chuỗi 'TRANSFER_IN' đúng với backend

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // LEFT
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Mô tả giao dịch
                Text(
                  t.description,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 4),

                // Nếu là tiền vào do người khác chuyển → hiện chip / label
                if (isTransferIn && isIncome) ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.arrow_downward,
                        size: 14,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          "Tiền vào từ người khác",
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],

                // Thời gian
                Text(
                  "Lúc: ${DateFormat('HH:mm:ss').format(t.date)}",
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),

                const SizedBox(height: 2),

                // Số dư sau giao dịch
                Text(
                  "SD: ${formatCurrency(t.balance)}",
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),

          // RIGHT – Số tiền
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
  "${t.amount < 0 ? "-" : "+"}${formatCurrency(t.amount)}",
  style: TextStyle(
    fontSize: 15,
    color: t.amount < 0 ? Colors.red : Colors.green,
    fontWeight: FontWeight.bold,
  ),
),

            ],
          ),
        ],
      ),
    );
  }
}

// ====================================================
// MODEL
// ====================================================
class TransactionModel {
  final String id;
  final DateTime date;
  final String description;
  final double amount;
  final double balance;
  final String type;

  TransactionModel({
    required this.id,
    required this.date,
    required this.description,
    required this.amount,
    required this.balance,
    required this.type,
  });
}
