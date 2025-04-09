import { AdParameters } from '@shared/services/ad/interfaces/ad-parameters.ts';
import { AdVerificationResult } from '@shared/services/ad/interfaces/ad-verification.ts';
import { AdMobService } from '@shared/services/ad/platforms/admob-service.ts';
import { PangleService } from '@shared/services/ad/platforms/pangle-service.ts';
import { PincruxService } from '@shared/services/ad/platforms/pincrux-service.ts';
import { TapjoyService } from '@shared/services/ad/platforms/tapjoy-service.ts';
import { UnityService } from '@shared/services/ad/platforms/unity-service.ts';
import { BaseAdService } from '@shared/services/ad/base-ad-service.ts';

export type { AdParameters, AdVerificationResult };
export {
  AdMobService,
  PangleService,
  PincruxService,
  TapjoyService,
  BaseAdService,
};

export class AdServiceFactory {
  static createService(platform: string, secretKey: string): BaseAdService {
    switch (platform.toLowerCase()) {
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
        throw new Error(`Unsupported ad platform: ${platform}`);
    }
  }
}
