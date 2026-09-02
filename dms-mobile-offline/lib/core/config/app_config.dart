// ============================================================================
// AppConfig - cau hinh app dong (env, country, sync settings)
// ============================================================================
// Enterprise: Multi-Country, Scoping, Sync Configuration

import '../../features/outlet/models/outlet_model.dart' show CountryCode;

/// AppConfig - luu tru cau hinh static cua app
class AppConfig {
  // ============ Environment ============
  /// Base URL cua backend API
  /// - Android emulator: 10.0.2.2
  /// - iOS simulator: localhost
  /// - Production: https://api.dms.example.com
  static const String apiBaseUrl = 'http://10.0.2.2:3000/api/v1';

  /// API timeout (seconds)
  static const int apiTimeoutSeconds = 30;

  // ============ Multi-Country ============
  /// Ma quoc gia mac dinh - VNM (Viet Nam)
  /// Co the doi sang LAO, CAM, MMR khi mo rong
  static const CountryCode defaultCountry = CountryCode.vnm;

  // ============ Media Settings ============
  /// Max kich thuoc anh upload (KB)
  static const int maxImageSizeKb = 500;

  /// Chat luong JPEG/WebP (0-100)
  static const int imageQuality = 80;

  /// CDN base URL cho media files (MinIO/S3)
  static const String cdnBaseUrl = 'https://cdn.dms.example.com';

  // ============ Sync Settings ============
  /// So lan retry toi da khi sync that bai
  static const int maxSyncRetries = 5;

  /// Thoi gian delay retry ban dau (seconds)
  static const int initialRetryDelaySeconds = 30;

  /// Kiem tra sync tu dong (seconds) - 0 = manual only
  static const int autoSyncIntervalSeconds = 0;

  // ============ Scoping (Data Isolation) ============
  /// Ban kinh GPS check duplicate (meters)
  static const double duplicateGpsRadiusMeters = 20.0;

  /// Mac dinh distributor_id (se duoc override tu user session)
  static const int defaultDistributorId = 1;

  /// Mac dinh territory_id (se duoc override tu user session)
  static const int defaultTerritoryId = 1;

  // ============ UI Settings ============
  /// GPS accuracy requirement (meters)
  static const double gpsRequiredAccuracyMeters = 20.0;

  /// Timeout lay GPS (seconds)
  static const int gpsTimeoutSeconds = 10;
}