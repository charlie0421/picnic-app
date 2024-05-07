import { BaseEntitiy } from './base.entitiy';
export type AgreementType = 'TERMS' | 'COMMERCE' | 'PRIVACY' | 'LOCATION' | 'MARKETING';
export declare class Agreement extends BaseEntitiy {
    type: AgreementType;
    title: string;
    content: string;
    version: string;
    effectiveDate: Date;
    isRequired: boolean;
}
