import 'package:picnic_lib/core/config/environment.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/supabase_options.dart';

class SupabaseHealthCheck {
  /// Supabase 연결 상태 및 설정을 확인하는 헬스체크
  static Future<bool> checkSupabaseHealth() async {
    try {
      logger.i('Supabase 헬스체크 시작...');
      
      // 1. 환경 설정 확인
      logger.i('환경 설정 확인:');
      logger.i('- 현재 환경: ${Environment.currentEnvironment}');
      logger.i('- Supabase URL: ${Environment.supabaseUrl}');
      logger.i('- Anon Key 길이: ${Environment.supabaseAnonKey.length}');
      
      // 2. URL 형식 확인
      if (!Environment.supabaseUrl.startsWith('https://')) {
        logger.e('잘못된 Supabase URL 형식: ${Environment.supabaseUrl}');
        return false;
      }
      
      // 3. 키 길이 확인
      if (Environment.supabaseAnonKey.length < 100) {
        logger.e('Supabase Anon Key가 너무 짧습니다: ${Environment.supabaseAnonKey.length}');
        return false;
      }
      
      // 4. 클라이언트 초기화 상태 확인
      if (!isSupabaseLoggedSafely) {
        logger.w('Supabase 로그인 상태가 안전하지 않습니다');
      }
      
      // 5. 간단한 연결 테스트 (products 테이블 조회)
      try {
        final response = await supabase
            .from('products')
            .select('id')
            .limit(1);
        
        logger.i('Supabase 연결 테스트 성공');
        logger.i('응답 데이터: $response');
        
        return true;
      } catch (e) {
        logger.e('Supabase 연결 테스트 실패: $e');
        
        // 특정 에러 패턴 분석
        if (e.toString().contains('Project not specified')) {
          logger.e('❌ 프로젝트 미지정 에러 - URL이나 키 설정 문제');
        } else if (e.toString().contains('Invalid API key')) {
          logger.e('❌ 잘못된 API 키');
        } else if (e.toString().contains('relation "products" does not exist')) {
          logger.e('❌ products 테이블이 존재하지 않음');
        }
        
        return false;
      }
      
    } catch (e, s) {
      logger.e('헬스체크 중 예외 발생', error: e, stackTrace: s);
      return false;
    }
  }
  
  /// 앱 시작 시 자동으로 헬스체크 실행
  static Future<void> runHealthCheckOnAppStart() async {
    logger.i('앱 시작 시 Supabase 헬스체크 실행...');
    
    final isHealthy = await checkSupabaseHealth();
    
    if (!isHealthy) {
      logger.e('⚠️ Supabase 헬스체크 실패 - 상품 로딩에 문제가 발생할 수 있습니다');
    } else {
      logger.i('✅ Supabase 헬스체크 성공');
    }
  }
} 