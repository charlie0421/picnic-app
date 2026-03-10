import 'package:mockito/mockito.dart';
import 'package:picnic_lib/core/services/auth/auth_service.dart';
import 'package:picnic_lib/core/services/network_connectivity_service.dart';
import 'package:picnic_lib/core/services/secure_storage_service.dart';
import 'package:picnic_lib/core/services/youtube_service.dart';
import 'package:picnic_lib/core/services/search_service.dart';
import 'package:picnic_lib/core/services/search_cache_service.dart';
import 'package:picnic_lib/core/services/purchase_service.dart';
import 'package:picnic_lib/core/services/push_token_service.dart';
import 'package:picnic_lib/core/services/update_service.dart';
import 'package:picnic_lib/core/services/link_service.dart';
import 'package:picnic_lib/core/services/consent_service.dart';
import 'package:picnic_lib/core/services/notification_inbox_service.dart';
import 'package:picnic_lib/core/services/app_badge_service.dart';
import 'package:picnic_lib/core/services/in_app_purchase_service.dart';
import 'package:picnic_lib/core/services/receipt_verification_service.dart';
import 'package:picnic_lib/core/services/receipt_queue_service.dart';
import 'package:picnic_lib/core/services/youtube_mission_service.dart';
import 'package:picnic_lib/core/services/device_manager.dart';

/// 인증 서비스 Mock
class MockAuthService extends Mock implements AuthService {}

/// 네트워크 연결 서비스 Mock
class MockNetworkConnectivityService extends Mock
    implements NetworkConnectivityService {}

/// 보안 저장소 서비스 Mock
class MockSecureStorageService extends Mock implements SecureStorageService {}

/// YouTube 콘텐츠 서비스 Mock
class MockYouTubeContentService extends Mock implements YouTubeContentService {}

/// 검색 서비스 Mock
class MockSearchService extends Mock implements SearchService {}

/// 검색 캐시 서비스 Mock
class MockSearchCacheService extends Mock implements SearchCacheService {}

/// 구매 서비스 Mock
class MockPurchaseService extends Mock implements PurchaseService {}

/// 푸시 토큰 서비스 Mock
class MockPushTokenService extends Mock implements PushTokenService {}

/// 업데이트 서비스 Mock
class MockUpdateService extends Mock implements UpdateService {}

/// 링크 서비스 Mock
class MockLinkService extends Mock implements LinkService {}

/// 동의 서비스 Mock
class MockConsentService extends Mock implements ConsentService {}

/// 알림 인박스 서비스 Mock
class MockNotificationInboxService extends Mock
    implements NotificationInboxService {}

/// 앱 배지 서비스 Mock
class MockAppBadgeService extends Mock implements AppBadgeService {}

/// 인앱 구매 서비스 Mock
class MockInAppPurchaseService extends Mock implements InAppPurchaseService {}

/// 영수증 검증 서비스 Mock
class MockReceiptVerificationService extends Mock
    implements ReceiptVerificationService {}

/// 영수증 큐 서비스 Mock
class MockReceiptQueueService extends Mock implements ReceiptQueueService {}

/// YouTube 미션 서비스 Mock
class MockYouTubeMissionService extends Mock implements YouTubeMissionService {}

/// 디바이스 매니저 Mock
class MockDeviceManager extends Mock implements DeviceManager {}
