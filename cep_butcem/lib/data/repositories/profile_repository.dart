import '../../core/state/profile_store.dart';
import '../local/app_database.dart';

class ProfileRepository {
  Future<ProfileData?> getProfile() async {
    final db = await AppDatabase.instance.database;
    final result = await db.query('profile', limit: 1);

    if (result.isEmpty) return null;
    return ProfileData.fromMap(result.first);
  }

  Future<void> saveProfile(ProfileData profile) async {
    final db = await AppDatabase.instance.database;
    final existing = await db.query('profile', limit: 1);

    if (existing.isEmpty) {
      await db.insert('profile', profile.toMap());
    } else {
      final id = existing.first['id'] as int;
      await db.update(
        'profile',
        profile.copyWith(id: id).toMap(),
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }
}
