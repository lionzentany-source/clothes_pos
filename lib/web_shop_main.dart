// Flutter Web Shop Main Entry
// Displays products and categories from API, with admin login placeholder

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(const WebShopApp());
}

class WebShopApp extends StatelessWidget {
  const WebShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clothes POS Web Shop',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const ProductsPage(),
    );
  }
}

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  List products = [];
  List categories = [];
  List offers = [];
  bool loading = true;
  String? errorMsg;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      final prodRes = await http.get(Uri.parse('http://localhost:8080/products'));
      final catRes = await http.get(Uri.parse('http://localhost:8080/categories'));
      final offersRes = await http.get(Uri.parse('http://localhost:8080/offers'));
      if (prodRes.statusCode != 200 || catRes.statusCode != 200 || offersRes.statusCode != 200) {
        setState(() {
          errorMsg = 'تعذر تحميل البيانات من السيرفر. تأكد أن السيرفر يعمل.';
          loading = false;
        });
        return;
      }
      setState(() {
        products = jsonDecode(prodRes.body);
        categories = jsonDecode(catRes.body);
        offers = jsonDecode(offersRes.body);
        loading = false;
      });
    } catch (e) {
      setState(() {
        errorMsg = 'خطأ في الاتصال بالسيرفر: $e';
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (errorMsg != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('المتجر الإلكتروني')),
        body: Center(
          child: Text(errorMsg!, style: const TextStyle(color: Colors.red, fontSize: 18)),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('المتجر الإلكتروني')),
      body: Column(
        children: [
          // عروض في الأعلى
          if (offers.isNotEmpty)
            SizedBox(
              height: 60,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: offers
                    .map(
                      (offer) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Chip(
                          label: Text(
                            offer['title'],
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          SizedBox(
            height: 60,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: categories
                  .map(
                    (cat) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Chip(label: Text(cat['name'])),
                    ),
                  )
                  .toList(),
            ),
          ),
          Expanded(
            child: GridView.count(
              crossAxisCount: 3,
              children: products
                  .map(
                    (prod) => Card(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            prod['name'],
                            style: const TextStyle(fontSize: 18),
                          ),
                          Text('السعر: ${prod['price']}'),
                          ElevatedButton(
                            onPressed: () {},
                            child: const Text('إضافة للسلة'),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const AdminLoginPage()));
        },
        child: const Icon(Icons.admin_panel_settings),
      ),
    );
  }
}

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String? _error;

  Future<void> _login() async {
    final res = await http.post(
      Uri.parse('http://localhost:8080/auth/login'),
      body: jsonEncode({
        'username': _userCtrl.text,
        'password': _passCtrl.text,
      }),
      headers: {'content-type': 'application/json'},
    );
    final data = jsonDecode(res.body);
    if (data['token'] != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AdminDashboard()),
      );
    } else {
      setState(() => _error = 'بيانات الدخول غير صحيحة');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('دخول المدير')),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _userCtrl,
              decoration: const InputDecoration(labelText: 'اسم المستخدم'),
            ),
            TextField(
              controller: _passCtrl,
              decoration: const InputDecoration(labelText: 'كلمة المرور'),
              obscureText: true,
            ),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _login, child: const Text('دخول')),
          ],
        ),
      ),
    );
  }
}

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  Future<Map<String, dynamic>> fetchSalesReport() async {
    final res = await http.get(
      Uri.parse('http://localhost:8080/reports/sales'),
    );
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> fetchInventoryReport() async {
    final res = await http.get(
      Uri.parse('http://localhost:8080/reports/inventory'),
    );
    return jsonDecode(res.body);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('لوحة تحكم المدير')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          ElevatedButton(
            onPressed: () {
              // TODO: إضافة منتج جديد
            },
            child: const Text('إضافة منتج جديد'),
          ),
          const SizedBox(height: 24),
          const Text(
            'تقارير المبيعات',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          FutureBuilder<Map<String, dynamic>>(
            future: fetchSalesReport(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const CircularProgressIndicator();
              final report = snapshot.data!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('إجمالي المبيعات: ${report['total_sales']}'),
                  Text('عدد الطلبات: ${report['orders_count']}'),
                  const Text('المنتجات الأكثر مبيعاً:'),
                  ...((report['top_products'] as List).map(
                    (p) => Text('- ${p['name']}: ${p['sold']}'),
                  )),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          const Text(
            'تقارير المخزون',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          FutureBuilder<Map<String, dynamic>>(
            future: fetchInventoryReport(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const CircularProgressIndicator();
              final report = snapshot.data!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...((report['products'] as List).map(
                    (p) => Text('- ${p['name']}: الكمية ${p['stock']}'),
                  )),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
