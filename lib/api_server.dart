// Clothes POS API Server (Dart Shelf Example)
// Provides REST endpoints for products, categories, orders, and admin authentication

import 'dart:convert';
import 'dart:io';
import 'package:clothes_pos/core/db/database_helper.dart';
import 'package:clothes_pos/core/config/feature_flags.dart';
import 'package:clothes_pos/data/datasources/attribute_dao.dart';
import 'package:shelf/shelf.dart';
import 'package:sqflite/sqflite.dart';

void main() async {
  final handler = Pipeline().addMiddleware(logRequests()).addHandler(_router);

  final server = await HttpServer.bind('localhost', 8080);
  serveRequests(server, handler);
  print('API Server running on localhost:${server.port}');
}

Future<void> serveRequests(HttpServer server, Handler handler) async {
  await for (final request in server) {
    final headersMap = <String, String>{};
    request.headers.forEach((name, values) {
      headersMap[name] = values.join(',');
    });
    final shelfRequest = Request(
      request.method,
      request.requestedUri,
      headers: headersMap,
      body: request,
    );
    final shelfResponse = await handler(shelfRequest);
    request.response.statusCode = shelfResponse.statusCode;
    shelfResponse.headers.forEach((key, value) {
      request.response.headers.set(key, value);
    });
    await request.response.addStream(shelfResponse.read());
    await request.response.close();
  }
}

Future<Response> _router(Request request) async {
  final path = request.url.path;
  final method = request.method;

  // المنتجات
  if (path == 'products' && method == 'GET') {
    final db = await DatabaseHelper.instance.database;
    final products = await db.rawQuery(
      'SELECT id, name, price FROM product_variants',
    );

    if (FeatureFlags.useDynamicAttributes && products.isNotEmpty) {
      try {
        final attrDao = AttributeDao(DatabaseHelper.instance);
        for (final p in products) {
          final vid = (p['id'] as int?);
          if (vid != null) {
            final vals = await attrDao.getAttributeValuesForVariant(vid);
            p['attributes'] = vals.map((v) => v.toMap()).toList();
          } else {
            p['attributes'] = [];
          }
        }
      } catch (_) {
        // ignore attribute enrichment failures in demo API
      }
    }
    return Response.ok(
      jsonEncode(products),
      headers: {'content-type': 'application/json'},
    );
  }

  // الفئات
  if (path == 'categories' && method == 'GET') {
    final db = await DatabaseHelper.instance.database;
    final categories = await db.rawQuery('SELECT id, name FROM categories');
    return Response.ok(
      jsonEncode(categories),
      headers: {'content-type': 'application/json'},
    );
  }

  // الطلبات
  if (path == 'orders' && method == 'POST') {
    final db = await DatabaseHelper.instance.database;
    final body = await request.readAsString();
    final data = jsonDecode(body);
    // مثال: حفظ الطلب في جدول sales
    final saleId = await db.insert('sales', {
      'customer_id': data['customer_id'],
      'total': data['total'],
      'created_at': DateTime.now().toIso8601String(),
    });
    // حفظ عناصر الطلب في جدول sale_items
    if (data['items'] is List) {
      for (final item in data['items']) {
        await db.insert('sale_items', {
          'sale_id': saleId,
          'product_id': item['product_id'],
          'quantity': item['quantity'],
          'price': item['price'],
        });
      }
    }
    return Response.ok(
      jsonEncode({'status': 'success', 'sale_id': saleId}),
      headers: {'content-type': 'application/json'},
    );
  }

  // تسجيل دخول المدير
  if (path == 'auth/login' && method == 'POST') {
    final db = await DatabaseHelper.instance.database;
    final body = await request.readAsString();
    final data = jsonDecode(body);
    final user = await db.rawQuery(
      'SELECT id, username FROM users WHERE username = ? AND password = ?',
      [data['username'], data['password']],
    );
    if (user.isNotEmpty) {
      // هنا يمكن توليد JWT حقيقي لاحقاً
      return Response.ok(
        jsonEncode({'token': 'demo-jwt-token', 'user': user.first}),
        headers: {'content-type': 'application/json'},
      );
    } else {
      return Response.forbidden(
        jsonEncode({'error': 'بيانات الدخول غير صحيحة'}),
        headers: {'content-type': 'application/json'},
      );
    }
  }

  // العروض
  if (path == 'offers' && method == 'GET') {
    final db = await DatabaseHelper.instance.database;
    final offers = await db.rawQuery(
      'SELECT id, title, valid_until FROM offers',
    );
    return Response.ok(
      jsonEncode(offers),
      headers: {'content-type': 'application/json'},
    );
  }

  // تقارير المبيعات
  if (path == 'reports/sales' && method == 'GET') {
    final db = await DatabaseHelper.instance.database;
    final totalSales =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT SUM(total) FROM sales'),
        ) ??
        0;
    final ordersCount =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM sales'),
        ) ??
        0;
    final topProducts = await db.rawQuery('''
      SELECT pv.name, SUM(si.quantity) as sold
      FROM sale_items si
      JOIN product_variants pv ON pv.id = si.product_id
      GROUP BY pv.id
      ORDER BY sold DESC
      LIMIT 5
    ''');
    return Response.ok(
      jsonEncode({
        'total_sales': totalSales,
        'orders_count': ordersCount,
        'top_products': topProducts,
      }),
      headers: {'content-type': 'application/json'},
    );
  }

  // تقارير المخزون
  if (path == 'reports/inventory' && method == 'GET') {
    final db = await DatabaseHelper.instance.database;
    final products = await db.rawQuery(
      'SELECT id, name, stock FROM product_variants',
    );

    if (FeatureFlags.useDynamicAttributes && products.isNotEmpty) {
      try {
        final attrDao = AttributeDao(DatabaseHelper.instance);
        for (final p in products) {
          final vid = (p['id'] as int?);
          if (vid != null) {
            final vals = await attrDao.getAttributeValuesForVariant(vid);
            p['attributes'] = vals.map((v) => v.toMap()).toList();
          } else {
            p['attributes'] = [];
          }
        }
      } catch (_) {
        // ignore enrichment failures
      }
    }

    return Response.ok(
      jsonEncode({'products': products}),
      headers: {'content-type': 'application/json'},
    );
  }

  return Response.notFound('Not Found');
}
