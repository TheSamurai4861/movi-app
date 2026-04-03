abstract interface class SecurePayloadStore {
  Future<void> put({
    required String key,
    required Map<String, dynamic> payload,
  });

  Future<Map<String, dynamic>?> get(String key);

  Future<void> remove(String key);
}
