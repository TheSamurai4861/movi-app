/// Port for local user data cleanup on logout.
abstract interface class LocalCleanupPort {
  Future<void> clearAllLocalData();
}

