import { AdParameters } from '@shared/services/ad/interfaces/ad-parameters.ts';

export interface AdVerificationResult {
  isValid: boolean;
  error?: string;
}

export interface AdVerificationService {
  verifyAdCallback(params: AdParameters): Promise<AdVerificationResult>;
  validateParameters(params: AdParameters): boolean;
  extractParameters(url: URL): AdParameters;
}
