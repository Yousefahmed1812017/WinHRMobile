import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final url = Uri.parse('http://deltamansoura.ddns.net:9090/ords/deltaamaindata/Query/Subordinates');
  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'managerId': 5036, 'pageNumber': 0, 'pageSize': 2}),
  );
  print(response.body);
}
