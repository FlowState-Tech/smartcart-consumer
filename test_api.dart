import 'package:http/http.dart' as http;
void main() async {
  final res = await http.get(Uri.parse('https://smartcart-api-production.up.railway.app/api/v1/planning/lists/1/compare-prices'));
  print('Status: ${res.statusCode}');
  print('Body: ${res.body}');
}
