import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class WifiScreen extends StatefulWidget {
  const WifiScreen({super.key});

  @override
  State<WifiScreen> createState() => _WifiScreenState();
}

class _WifiScreenState extends State<WifiScreen> {
  Map<String, String>? selectedPackage;

  void selectPackage(Map<String, String> package) {
    setState(() {
      selectedPackage = package;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 223, 212, 241),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 223, 212, 241),
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 65.0),
          child: const Text(
            'Nạp Data 3G,4G',
            style: TextStyle(color: Colors.black, fontSize: 20),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Từ tài khoản',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),

              // STK và Số dư
              Container(
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Row(
                    children: [
                      Icon(
                        FontAwesomeIcons.heartCircleCheck,
                        color: Colors.purple,
                      ),
                      SizedBox(width: 10),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('06437082701', style: TextStyle(fontSize: 12)),
                          SizedBox(height: 5),
                          Text(
                            '1,840,367 VND',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Thông tin nạp tiền',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),

              // Số điện thoại và Nhà mạng
              Row(
                children: [
                  SizedBox(
                    width: 195,
                    child: _buildInputField(
                      icon: Icons.phone,
                      hint: 'Số điện thoại',
                      isNumber: true,
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                  SizedBox(width: 10),
                  SizedBox(
                    width: 195,
                    child: _buildInputField(icon: Icons.wifi, hint: 'Nhà mạng'),
                  ),
                ],
              ),
              SizedBox(height: 20),

              // gói cước 1 ngày
              Text('Gói 1 ngày', style: TextStyle(fontSize: 12)),
              SizedBox(height: 10),
              _buildPackageRow([
                {'data': '8GB', 'price': '10,000 VND'},
                {'data': '24GB', 'price': '20,000 VND'},
              ]),
              SizedBox(height: 20),

              // gói cước 10 ngày
              Text('Gói 10 ngày', style: TextStyle(fontSize: 12)),
              SizedBox(height: 10),
              _buildPackageRow([
                {'data': '1GB', 'price': '10,000 VND'},
                {'data': '1.4GB', 'price': '14,000 VND'},
              ]),
              SizedBox(height: 20),

              //gói cước 3 ngày
              Text('Gói 3 ngày', style: TextStyle(fontSize: 12)),
              SizedBox(height: 10),
              _buildSinglePackage('15GB', '15,000 VND'),
              SizedBox(height: 20),

              //gói cước 7 ngày
              Text('Gói 7 ngày', style: TextStyle(fontSize: 12)),
              SizedBox(height: 10),
              _buildSinglePackage('30GB', '30,000 VND'),
              SizedBox(height: 20),

              // gói cước 30 ngày
              Text('Gói 30 ngày', style: TextStyle(fontSize: 12)),
              SizedBox(height: 10),
              _buildPackageRow([
                {'data': '8GB', 'price': '84,000 VND'},
                {'data': '50GB/30 ngày', 'price': '155,000 VND'},
              ]),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 104, 5, 211),
              minimumSize: Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: () {
              if (selectedPackage == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Vui lòng chọn gói cước trước khi tiếp tục'),
                  ),
                );
                return;
              } else {
                showModalBottomSheet(
                  context: context,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  builder: (context) {
                    return Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                              width: 50,
                              height: 5,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          SizedBox(height: 20),
                          Center(
                            child: Text(
                              'Xác nhận giao dịch',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(height: 20),
                          Text(
                            'Gói bạn chọn:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '${selectedPackage!['data']} - ${selectedPackage!['price']}',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 30),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Đã xác nhận nạp ${selectedPackage!['data']}(${selectedPackage!['price']})',
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple,
                                minimumSize: Size(double.infinity, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                'Xác nhận',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              }
            },
            child: Text(
              'Tiếp tục',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSinglePackage(String data, String price) {
    final package = {'data': data, 'price': price};
    final bool isSelected =
        selectedPackage?['data'] == data && selectedPackage?['price'] == price;
    return GestureDetector(
      onTap: () => selectPackage(package),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        margin: EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.amber[100] : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? Colors.amber : Colors.transparent,
            width: 2,
          ),
        ),
        height: 50,

        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                data,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              Text(price, style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPackageRow(List<Map<String, String>> packages) {
    return Row(
      children: packages.map((package) {
        final bool isSelected =
            selectedPackage?['data'] == package['data'] &&
            selectedPackage?['price'] == package['price'];
        return Expanded(
          child: GestureDetector(
            onTap: () => selectPackage(package),
            child: AnimatedContainer(
              duration: Duration(milliseconds: 200),
              margin: EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: isSelected ? Colors.amber[100] : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? Colors.amber : Colors.transparent,
                  width: 2,
                ),
              ),
              height: 50,

              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      package['data']!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      package['price']!,
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

Widget _buildInputField({
  required IconData icon,
  required String hint,
  TextInputType? keyboardType,
  bool isNumber = false,
}) {
  return Container(
    height: 60,

    decoration: BoxDecoration(
      color: Colors.grey[200],
      borderRadius: BorderRadius.circular(10),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.purple),
          SizedBox(width: 10),
          Expanded(
            child: TextField(
              style: TextStyle(fontSize: 12),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hint,
              ),
              keyboardType: isNumber
                  ? TextInputType.number
                  : TextInputType.text,
            ),
          ),
        ],
      ),
    ),
  );
}
