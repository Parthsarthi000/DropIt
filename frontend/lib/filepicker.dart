import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

Future<Map<String, dynamic>?> pickFile() async {
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'jpg', 'png', 'jpeg'],
    withData: true, // Ensures bytes are included
  );

  if (result != null) {
    return {
      "fileName": result.files.single.name,
      "fileBytes": result.files.single.bytes, // Use bytes instead of path
    };
  } else {
    return null; // No file selected
  }
}

Future<int> uploadFile(
    Uint8List fileBytes, String fileName, String username) async {
  Uri url = Uri.parse("http://43.199.44.69:5002/api/uploadFile");

  try {
    // Extract file metadata
    String fileType = fileName.split('.').last; // Get file extension
    int fileSize = fileBytes.length; // Get file size in bytes

    var request = http.MultipartRequest("POST", url);
    request.fields["username"] = username;
    request.fields["filename"] = fileName;
    request.fields["filetype"] = fileType;
    request.fields["filesize"] = fileSize.toString(); // Convert int to string
    request.files.add(
        http.MultipartFile.fromBytes("file", fileBytes, filename: fileName));

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    return response.statusCode; // Return response code
  } catch (e) {
    print("Error: $e");
    return 500;
  }
}

Future<int> deleteFile(String filename, String username) async {
  Uri url = Uri.parse("http://43.199.44.69:5002/api/deleteFile");

  try {
    var response = await http.delete(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "username": username,
        "filename": filename,
      }),
    );

    return response.statusCode; // Return status code to handle in UI
  } catch (e) {
    print("Error deleting file: $e");
    return 500; // Handle failure gracefully
  }
}

Future<String> fetchDocument(String username, String filename) async {
  // ✅ Pass parameters in the URL instead of using `body`
  Uri url = Uri.parse(
      "http://43.199.44.69:5002/api/getFile?username=$username&filename=${Uri.encodeComponent(filename)}");

  try {
    var response = await http.get(
      url,
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      return data["file_url"]; // ✅ Correctly extracts file URL
    } else {
      print("Error fetching document: ${response.statusCode}");
      return "";
    }
  } catch (e) {
    print("Error: $e");
    return "";
  }
}
