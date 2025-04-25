import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  Future<String?> uploadFoodImage(File imageFile, String userId, {String? prefix}) async {
    try {
      final fileName = prefix != null 
          ? '${prefix}food_${DateTime.now().millisecondsSinceEpoch}.jpg'
          : 'food_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      final ref = _storage.ref().child('users/$userId/food_images/$fileName');
      
      final uploadTask = ref.putFile(imageFile);
      
      final snapshot = await uploadTask;
      
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      print('Error uploading food image: $e');
      return null;
    }
  }
  
  Future<String?> uploadFoodImageWithName(File imageFile, String userId, String fileName) async {
    try {
      final ref = _storage.ref().child('users/$userId/food_images/$fileName');
      
      final uploadTask = ref.putFile(imageFile);
      
      final snapshot = await uploadTask;
      
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      print('Successfully uploaded image with name $fileName');
      return downloadUrl;
    } catch (e) {
      print('Error uploading food image with specific name: $e');
      return null;
    }
  }
  
  Future<File> downloadFoodImage(String imageUrl) async {
    try {
      final fileName = 'downloaded_food_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      final appDir = await getApplicationDocumentsDirectory();
      final filePath = '${appDir.path}/$fileName';
      
      final response = await http.get(Uri.parse(imageUrl));
      
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);
      
      return file;
    } catch (e) {
      throw Exception('Error downloading food image: $e');
    }
  }
  
  Future<void> deleteFoodImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      
      await ref.delete();
    } catch (e) {
      print('Error deleting food image: $e');
    }
  }
}