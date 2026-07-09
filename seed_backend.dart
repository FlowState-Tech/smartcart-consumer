import 'dart:convert';
import 'package:http/http.dart' as http;

final baseUrl = 'https://smartcart-api-production.up.railway.app';
String token = '';

Future<void> main() async {
  print('Iniciando Seeding...');
  
  // 1. Autenticar o crear usuario
  try {
    final signupRes = await http.post(
      Uri.parse('$baseUrl/api/v1/authentication/sign-up'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "username": "seed_admin",
        "password": "seed_password123",
        "roles": ["ROLE_MERCHANT"]
      }),
    );
    print('Signup: ${signupRes.statusCode}');
  } catch (e) {
    print('Signup error: $e');
  }

  try {
    final signinRes = await http.post(
      Uri.parse('$baseUrl/api/v1/authentication/sign-in'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "username": "seed_admin",
        "password": "seed_password123"
      }),
    );
    print('Signin: ${signinRes.statusCode}');
    if (signinRes.statusCode == 200) {
      final body = jsonDecode(signinRes.body);
      token = body['token'] ?? '';
      print('Token obtenido.');
    }
  } catch (e) {
    print('Signin error: $e');
    return;
  }

  if (token.isEmpty) {
    print('Fallo al obtener token.');
    return;
  }

  // Tiendas
  final operatingHours = [{"dayOfWeek": "MONDAY", "openTime": "08:00:00", "closeTime": "22:00:00"}];
  final storesData = [
    {"merchantId": "seed_admin", "name": "Plaza Vea Centro", "ruc": "10000000001", "address": {"street": "Av Arequipa", "district": "Lima", "latitude": -12.0, "longitude": -77.0}, "operatingHours": operatingHours},
    {"merchantId": "seed_admin", "name": "Metro San Isidro", "ruc": "10000000002", "address": {"street": "Av Salaverry", "district": "San Isidro", "latitude": -12.0, "longitude": -77.0}, "operatingHours": operatingHours},
    {"merchantId": "seed_admin", "name": "Wong Ovalo", "ruc": "10000000003", "address": {"street": "Ovalo", "district": "Miraflores", "latitude": -12.0, "longitude": -77.0}, "operatingHours": operatingHours},
    {"merchantId": "seed_admin", "name": "Tottus Megaplaza", "ruc": "10000000004", "address": {"street": "Panamericana Norte", "district": "Independencia", "latitude": -11.9, "longitude": -77.0}, "operatingHours": operatingHours},
    {"merchantId": "seed_admin", "name": "Oxxo Encalada", "ruc": "10000000005", "address": {"street": "Av Encalada", "district": "Surco", "latitude": -12.1, "longitude": -76.9}, "operatingHours": operatingHours},
    {"merchantId": "seed_admin", "name": "Mass San Juan", "ruc": "10000000006", "address": {"street": "Av Próceres", "district": "San Juan de Lurigancho", "latitude": -11.9, "longitude": -76.9}, "operatingHours": operatingHours},
    {"merchantId": "seed_admin", "name": "Listo! 24h", "ruc": "10000000007", "address": {"street": "Av Javier Prado", "district": "San Borja", "latitude": -12.0, "longitude": -77.0}, "operatingHours": [{"dayOfWeek": "MONDAY", "openTime": "00:00:00", "closeTime": "23:59:59"}]},
  ];

  final storeIds = [];
  for (var s in storesData) {
    final res = await http.post(
      Uri.parse('$baseUrl/api/v1/store-management/stores'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode(s),
    );
    print('Crear Tienda ${s['name']}: ${res.statusCode} -> ${res.body}');
    if (res.statusCode == 201 || res.statusCode == 200) {
      // Body can be just an integer based on Swagger
      final idStr = res.body.replaceAll('"', '').trim();
      if (idStr.isNotEmpty && int.tryParse(idStr) != null) {
        storeIds.add(int.parse(idStr));
      } else {
        // Maybe it's a JSON object
        try {
          final b = jsonDecode(res.body);
          storeIds.add(b['storeId'] ?? b['id'] ?? b);
        } catch(_) {}
      }
    }
  }

  if (storeIds.isEmpty) {
    print('Error: No se crearon tiendas. Usando IDs manuales (1,2,3)');
    storeIds.addAll([1, 2, 3]);
  }

  // Base products
  final productsBase = [
    {"sku": "GL-123", "name": "Leche Gloria", "brand": "Gloria", "categoryId": 1, "currency": "PEN", "quantity": 100, "minThreshold": 10, "promotional": false},
    {"sku": "BI-456", "name": "Pan Bimbo", "brand": "Bimbo", "categoryId": 1, "currency": "PEN", "quantity": 100, "minThreshold": 10, "promotional": false},
    {"sku": "AR-789", "name": "Arroz Costeño", "brand": "Costeño", "categoryId": 1, "currency": "PEN", "quantity": 100, "minThreshold": 10, "promotional": false},
    {"sku": "HU-012", "name": "Huevos La Calera", "brand": "La Calera", "categoryId": 1, "currency": "PEN", "quantity": 100, "minThreshold": 10, "promotional": false},
    {"sku": "AC-345", "name": "Aceite Primor", "brand": "Primor", "categoryId": 1, "currency": "PEN", "quantity": 100, "minThreshold": 10, "promotional": false},
  ];

  // Randomize prices slightly per store
  final prices = {
    1: [4.50, 8.00, 4.20, 7.50, 9.50], // Plaza Vea (Cheap)
    2: [4.70, 8.20, 4.30, 7.80, 9.80], // Metro (Mid)
    3: [5.20, 8.90, 4.80, 8.50, 10.50], // Wong (Expensive)
  };

  int i = 0;
  for (var storeId in storeIds) {
    final listKey = (i % 3) + 1;
    final storePrices = prices[listKey]!;
    
    for (int j = 0; j < productsBase.length; j++) {
      final p = Map<String, dynamic>.from(productsBase[j]);
      p['priceAmount'] = storePrices[j];
      
      final res = await http.post(
        Uri.parse('$baseUrl/api/v1/store-management/stores/$storeId/inventory/items'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode(p),
      );
      print('Añadir producto ${p['name']} a tienda $storeId: ${res.statusCode}');
    }
    i++;
  }

  print('Seeding Completado!');
}
