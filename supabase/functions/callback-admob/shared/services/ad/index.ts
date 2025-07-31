import { AdMobService } from '@shared/services/ad/platforms/admob-service.ts';
import { PangleService } from '@shared/services/ad/platforms/pangle-service.ts';
import { PincruxService } from '@shared/services/ad/platforms/pincrux-service.ts';
import { TapjoyService } from '@shared/services/ad/platforms/tapjoy-service.ts';
import { UnityService } from '@shared/services/ad/platforms/unity-service.ts';
import { BaseAdService } from '@shared/services/ad/base-ad-service.ts';

export { AdMobService, PangleService, PincruxService, TapjoyService, UnityService, BaseAdService };

export class AdServiceFactory {
  static createService(platform, secretKey) {
    switch(platform.toLowerCase()){
      case 'admob':
        return new AdMobService(secretKey);
      case 'pangle':
        return new PangleService(secretKey);
      case 'pincrux':
        return new PincruxService(secretKey);
      case 'tapjoy':
        return new TapjoyService(secretKey);
      case 'unity':
        return new UnityService(secretKey);
      default:
        throw new Error(`지원하지 않는 광고 플랫폼입니다: ${platform}`);
    }
  }
}
