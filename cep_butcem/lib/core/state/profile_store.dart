import 'package:flutter/material.dart';

class ProfileData {
  final int? id;
  final String firstName;
  final String lastName;
  final String occupation;

  const ProfileData({
    this.id,
    required this.firstName,
    required this.lastName,
    required this.occupation,
  });

  String get fullName {
    final full = '${firstName.trim()} ${lastName.trim()}'.trim();
    return full.isEmpty ? 'Kullanıcı' : full;
  }

  ProfileData copyWith({
    int? id,
    String? firstName,
    String? lastName,
    String? occupation,
  }) {
    return ProfileData(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      occupation: occupation ?? this.occupation,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'occupation': occupation,
    };
  }

  factory ProfileData.fromMap(Map<String, dynamic> map) {
    return ProfileData(
      id: map['id'] as int?,
      firstName: map['first_name'] as String? ?? '',
      lastName: map['last_name'] as String? ?? '',
      occupation: map['occupation'] as String? ?? '',
    );
  }
}

class ProfileStore extends ValueNotifier<ProfileData> {
  ProfileStore(super.value);

  void setProfile(ProfileData data) {
    value = data;
    notifyListeners();
  }
}

class ProfileScope extends InheritedWidget {
  final ProfileStore store;

  const ProfileScope({super.key, required this.store, required super.child});

  static ProfileStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ProfileScope>();
    assert(
      scope != null,
      'ProfileScope bulunamadı. main.dart içine sardın mı?',
    );
    return scope!.store;
  }

  @override
  bool updateShouldNotify(ProfileScope oldWidget) => store != oldWidget.store;
}
