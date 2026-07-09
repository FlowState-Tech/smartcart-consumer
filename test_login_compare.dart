import 'dart:convert';
import 'package:http/http.dart' as http;

final baseUrl = 'https://smartcart-api-production.up.railway.app';

void main() async {
  final signinRes = await http.post(
    Uri.parse('$baseUrl/api/v1/authentication/sign-in'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      "username": "seed_admin",
      "password": "seed_password123"
    }),
  );
  
  if (signinRes.statusCode != 200) {
    print('Signin failed: ${signinRes.body}');
    return;
  }
  final token = jsonDecode(signinRes.body)['token'];
  
  // Create list 1 if not exists
  await http.post(
    Uri.parse('$baseUrl/api/v1/planning/lists'),
    headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
    body: jsonEncode({"buyerId": 1, "name": "Mi Canasta"}),
  );
  
  // Add item
  await http.post(
    Uri.parse('$baseUrl/api/v1/planning/lists/1/items'),
    headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
    body: jsonEncode({
      "sku": "GL-123",
      "productName": "Leche Gloria",
      "quantity": 1,
      "unit": "unit"
    }),
  );
  
  // Compare prices
  final compareRes = await http.get(
    Uri.parse('$baseUrl/api/v1/planning/lists/1/compare-prices'),
    headers: {'Authorization': 'Bearer $token'},
  );
  
  print('Compare Status: ${compareRes.statusCode}');
  print('Compare Body: ${compareRes.body}');
}
