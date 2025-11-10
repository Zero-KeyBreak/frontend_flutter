import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CCCDScreen extends StatefulWidget {
  const CCCDScreen({super.key});

  @override
  State<CCCDScreen> createState() => _CCCDScreenState();
}

class _CCCDScreenState extends State<CCCDScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _cccdController = TextEditingController();
  final TextEditingController _issueDateController = TextEditingController();
  final TextEditingController _issuePlaceController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _birthController = TextEditingController();

  String? _gender;
  final Color primaryColor = const Color(0xFF6D32D3);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6FF),
      appBar: AppBar(
        title: const Text(
          "Cập nhật CCCD",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel("Họ và tên"),
              _buildTextField(_nameController, "Nhập họ tên đầy đủ"),

              _buildLabel("Số CCCD/CMND"),
              _buildTextField(_cccdController, "Nhập số CCCD", isNumber: true),

              _buildLabel("Ngày sinh"),
              _buildDateField(_birthController, "Chọn ngày sinh"),

              _buildLabel("Giới tính"),
              _buildGenderSelector(),

              _buildLabel("Ngày cấp"),
              _buildDateField(_issueDateController, "Chọn ngày cấp"),

              _buildLabel("Nơi cấp"),
              _buildTextField(_issuePlaceController, "Nhập nơi cấp"),

              _buildLabel("Địa chỉ thường trú"),
              _buildTextField(_addressController, "Nhập địa chỉ thường trú"),

              const SizedBox(height: 30),
              Center(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Thông tin CCCD đã được lưu thành công!",
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );

                        // ✅ Gửi kết quả "đã xác thực" về PersonalScreen
                        Navigator.pop(context, true);
                      }
                    },
                    child: const Text(
                      "Xác nhận",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- LABEL ---
  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  // --- TEXT FIELD ---
  Widget _buildTextField(
    TextEditingController controller,
    String hint, {
    bool isNumber = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        hintText: hint,
        fillColor: Colors.white,
        filled: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.grey),
        ),
      ),
      validator: (value) =>
          value == null || value.isEmpty ? 'Vui lòng nhập thông tin' : null,
    );
  }

  // --- DATE PICKER FIELD ---
  Widget _buildDateField(TextEditingController controller, String hint) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        hintText: hint,
        suffixIcon: const Icon(Icons.calendar_today, color: Colors.grey),
        fillColor: Colors.white,
        filled: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.grey),
        ),
      ),
      validator: (value) =>
          value == null || value.isEmpty ? 'Vui lòng chọn ngày' : null,
      onTap: () async {
        DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: DateTime(2000),
          firstDate: DateTime(1950),
          lastDate: DateTime.now(),
          builder: (context, child) {
            return Theme(
              data: Theme.of(
                context,
              ).copyWith(colorScheme: ColorScheme.light(primary: primaryColor)),
              child: child!,
            );
          },
        );
        if (pickedDate != null) {
          setState(() {
            controller.text = DateFormat('dd/MM/yyyy').format(pickedDate);
          });
        }
      },
    );
  }

  // --- GENDER SELECTOR ---
  Widget _buildGenderSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _gender,
          hint: const Text("Chọn giới tính"),
          isExpanded: true,
          items: const [
            DropdownMenuItem(value: "Nam", child: Text("Nam")),
            DropdownMenuItem(value: "Nữ", child: Text("Nữ")),
            DropdownMenuItem(value: "Khác", child: Text("Khác")),
          ],
          onChanged: (value) {
            setState(() {
              _gender = value;
            });
          },
        ),
      ),
    );
  }
}
