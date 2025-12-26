import 'package:supabase_flutter/supabase_flutter.dart';

/// Datasource Supabase : requÃƒÂªtes brutes (I/O).
///
/// - Aucun mapping vers l'entity ici.
/// - Pas de logique mÃƒÂ©tier.
/// - Retourne des rows typÃƒÂ©es `Map<String, dynamic>`.
class SupabaseProfileDatasource {
  SupabaseProfileDatasource(this._client);

  final SupabaseClient _client;

  static const String table = 'profiles';
  static const String colAccountId = 'account_id';

  Future<List<Map<String, dynamic>>> selectProfilesByAccountId(String accountId) async {
    final rows = await _client.from(table).select().eq(colAccountId, accountId);

    return rows
        .map((e) => (e as Map).cast<String, dynamic>())
        .toList(growable: false);
  }

  Future<Map<String, dynamic>> insertProfile(Map<String, dynamic> payload) async {
    final row = await _client.from(table).insert(payload).select().single();
    return (row as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> updateProfile({
    required String profileId,
    required Map<String, dynamic> updates,
  }) async {
    final row = await _client
        .from(table)
        .update(updates)
        .eq('id', profileId)
        .select()
        .single();
    return (row as Map).cast<String, dynamic>();
  }

  Future<void> deleteProfile(String profileId) async {
    await _client.from(table).delete().eq('id', profileId);
  }

  Future<Map<String, dynamic>> selectProfileById(String profileId) async {
    final row = await _client.from(table).select().eq('id', profileId).single();
    return (row as Map).cast<String, dynamic>();
  }
}
