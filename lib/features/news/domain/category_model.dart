import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryModel {
  final String id;
  final String name;
  final String slug; // Added slug
  final int postCount;
  final bool enabled;

  CategoryModel({
    required this.id,
    required this.name,
    this.slug = '', 
    this.postCount = 0,
    this.enabled = true,
  });

  // Factory for Firestore Document
  factory CategoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return CategoryModel(
      id: doc.id,
      name: data['name'] as String? ?? doc.id,
      slug: data['slug'] as String? ?? doc.id, // Fallback to ID
      postCount: data['postCount'] as int? ?? 0,
      enabled: data['enabled'] as bool? ?? true,
    );
  }

  // Factory for REST API JSON
  factory CategoryModel.fromRestJson(Map<String, dynamic> json) {
    // Structure: { "name": "projects/.../documents/categories/{id}", "fields": { ... } }
    
    // Extract ID from "name" field
    String docId = '';
    if (json.containsKey('name')) {
      final nameParts = (json['name'] as String).split('/');
      if (nameParts.isNotEmpty) docId = nameParts.last;
    }

    final fields = json['fields'] as Map<String, dynamic>? ?? {};

    // Helper to get integer
    int getInt(String key) {
      if (!fields.containsKey(key)) return 0;
      final field = fields[key] as Map<String, dynamic>;
      if (field.containsKey('integerValue')) {
        return int.tryParse(field['integerValue'].toString()) ?? 0;
      }
      return 0;
    }

    // Helper to get string
    String getString(String key) {
      if (!fields.containsKey(key)) return '';
      final field = fields[key] as Map<String, dynamic>;
      return field['stringValue'] as String? ?? '';
    }

    // Helper to get boolean
    bool getBool(String key) {
       if (!fields.containsKey(key)) return true; // Default true if missing? or strict?
       final field = fields[key] as Map<String, dynamic>;
       return field['booleanValue'] as bool? ?? false;
    }

    return CategoryModel(
      id: docId,
      name: getString('name').isNotEmpty ? getString('name') : docId,
      slug: getString('slug').isNotEmpty ? getString('slug') : docId,
      postCount: getInt('postCount'),
      enabled: getBool('enabled'),
    );
  }
}
