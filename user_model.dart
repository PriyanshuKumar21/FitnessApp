import 'package:flutter/foundation.dart';

class User {
  final String id;
  final String name;
  final String email;
  final String photoUrl;
  final DateTime registrationDate;
  final bool isVerified;
  final String gender;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl = '',
    required this.registrationDate,
    this.isVerified = false,
    this.gender = 'male',
  });

  // Convert User object to a map for storage
  Map<String, dynamic> toMap() {
    // Ensure field names match database column names exactly
    return {
      'id': id,
      'name': name,
      'email': email,
      'photo_url': photoUrl,  // Match the column name in database
      'registration_date': registrationDate.millisecondsSinceEpoch,  // Store as INTEGER
      'is_verified': isVerified ? 1 : 0,  // Convert boolean to integer for SQLite
      'gender': gender,
    };
  }

  // Create a User object from a map (e.g., from storage)
  factory User.fromMap(Map<String, dynamic> map) {
    // Debug: Print the map contents to see what we're working with
    debugPrint('Creating User from map: $map');
    
    bool isVerified = false;
    // Handle different possible types for is_verified
    if (map['is_verified'] != null) {
      if (map['is_verified'] is bool) {
        isVerified = map['is_verified'];
      } else if (map['is_verified'] is int) {
        isVerified = map['is_verified'] == 1;
      } else if (map['is_verified'] is String) {
        isVerified = map['is_verified'] == '1' || map['is_verified'].toLowerCase() == 'true';
      }
    }
    
    // For backward compatibility, also check the old field name
    if (map['isVerified'] != null && !isVerified) {
      if (map['isVerified'] is bool) {
        isVerified = map['isVerified'];
      } else if (map['isVerified'] is int) {
        isVerified = map['isVerified'] == 1;
      } else if (map['isVerified'] is String) {
        isVerified = map['isVerified'] == '1' || map['isVerified'].toLowerCase() == 'true';
      }
    }
    
    // Handle registration date (could be INTEGER or STRING)
    DateTime registrationDate;
    try {
      if (map['registration_date'] != null) {
        if (map['registration_date'] is int) {
          registrationDate = DateTime.fromMillisecondsSinceEpoch(map['registration_date']);
        } else {
          registrationDate = DateTime.parse(map['registration_date'].toString());
        }
      } else if (map['registrationDate'] != null) {
        // Try legacy field name
        if (map['registrationDate'] is int) {
          registrationDate = DateTime.fromMillisecondsSinceEpoch(map['registrationDate']);
        } else {
          registrationDate = DateTime.parse(map['registrationDate'].toString());
        }
      } else {
        registrationDate = DateTime.now();
      }
    } catch (e) {
      debugPrint('Error parsing registration date: $e');
      registrationDate = DateTime.now();
    }
    
    return User(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      photoUrl: map['photo_url'] ?? map['photoUrl'] ?? '', // Try both field names
      registrationDate: registrationDate,
      isVerified: isVerified,
      gender: map['gender'] ?? 'male',
    );
  }

  // Create a copy of a User with updated properties
  User copyWith({
    String? id,
    String? name,
    String? email,
    String? photoUrl,
    DateTime? registrationDate,
    bool? isVerified,
    String? gender,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      registrationDate: registrationDate ?? this.registrationDate,
      isVerified: isVerified ?? this.isVerified,
      gender: gender ?? this.gender,
    );
  }
} 