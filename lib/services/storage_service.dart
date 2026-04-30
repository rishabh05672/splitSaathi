import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Service for handling file uploads to ImgBB (Free Image Hosting).
class StorageService {
  final String _apiKey = 'f761337ac28b8d50687a60e07635cbeb';

  /// Uploads a profile image to ImgBB.
  /// Returns the download URL.
  Future<String> uploadProfileImage(String userId, File file) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.imgbb.com/1/upload?key=$_apiKey'),
      );

      request.files.add(await http.MultipartFile.fromPath('image', file.path));

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final result = json.decode(responseData);

      if (response.statusCode == 200 && result['success'] == true) {
        return result['data']['url'] as String;
      } else {
        final errorMessage = result['error']?['message'] ?? 'Unknown error';
        throw Exception('Upload failed: $errorMessage');
      }
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }
}
