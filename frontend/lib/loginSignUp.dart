import 'package:http/http.dart' as http;
import 'dart:convert';

Future<int> auth(String username, String password, String requestType) async {
  const String baseUrl = "http://43.199.44.69:5002/api";

  if (username.trim().isEmpty || password.trim().isEmpty) {
    return 0; // Return 0 if fields are empty
  }

  Uri url = Uri.parse("$baseUrl/$requestType");

  try {
    http.Response response = await http
        .post(
          url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({"username": username, "password": password}),
        )
        .timeout(const Duration(seconds: 10)); // Timeout after 10 seconds

    return response.statusCode;
  } catch (e) {
    return 500; // Return 500 if request fails
  }
}

Future<List<String>> getFileMetaData(String username) async {
  Uri url = Uri.parse("http://43.199.44.69:5002/api/getFileMetaData");
  try {
    http.Response response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"username": username}),
    );

    if (response.statusCode == 200) {
      return List<String>.from(
          jsonDecode(response.body)["files"]); // Extract list correctly
    } else {
      return [];
    }
  } catch (e) {
    return []; // Avoid app crash
  }
}
