import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String username;
  final String email;
  final String photoURL;
  final DateTime? dateOfBirth;
  final double? bodyWeight;
  final double? bodyHeight;
  final String? gender;
  final int points;
  final bool isProfileComplete;
  
  UserModel({
    required this.id,
    required this.username,
    required this.email,
    this.photoURL = '',
    this.dateOfBirth,
    this.bodyWeight,
    this.bodyHeight,
    this.gender,
    this.points = 0,
    this.isProfileComplete = false,
  });
  
  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      username: map['username'] ?? '',
      email: map['email'] ?? '',
      photoURL: map['photoURL'] ?? '',
      dateOfBirth: map['dateOfBirth'] != null 
          ? (map['dateOfBirth'] as Timestamp).toDate() 
          : null,
      bodyWeight: map['bodyWeight']?.toDouble(),
      bodyHeight: map['bodyHeight']?.toDouble(),
      gender: map['gender'],
      points: map['points'] ?? 0,
      isProfileComplete: map['isProfileComplete'] ?? false,
    );
  }
  
  Map<String, dynamic> toMap() {
    final hasRequiredFields = 
        (dateOfBirth ?? dateOfBirth) != null && 
        (bodyWeight ?? bodyWeight) != null && 
        (bodyHeight ?? bodyHeight) != null && 
        (gender ?? gender) != null;
        
    return {
      'username': username,
      'email': email,
      'photoURL': photoURL,
      'dateOfBirth': dateOfBirth,
      'bodyWeight': bodyWeight,
      'bodyHeight': bodyHeight,
      'gender': gender,
      'points': points,
      'isProfileComplete': isProfileComplete || hasRequiredFields,
    };
  }
  
  UserModel copyWith({
    String? username,
    String? email,
    String? photoURL,
    DateTime? dateOfBirth,
    double? bodyWeight,
    double? bodyHeight,
    String? gender,
    int? points,
    bool? isProfileComplete,
  }) {
    final hasRequiredFields = 
        (dateOfBirth ?? this.dateOfBirth) != null && 
        (bodyWeight ?? this.bodyWeight) != null && 
        (bodyHeight ?? this.bodyHeight) != null && 
        (gender ?? this.gender) != null;
        
    return UserModel(
      id: id,
      username: username ?? this.username,
      email: email ?? this.email,
      photoURL: photoURL ?? this.photoURL,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      bodyWeight: bodyWeight ?? this.bodyWeight,
      bodyHeight: bodyHeight ?? this.bodyHeight,
      gender: gender ?? this.gender,
      points: points ?? this.points,
      isProfileComplete: isProfileComplete ?? (this.isProfileComplete || hasRequiredFields),
    );
  }
} 