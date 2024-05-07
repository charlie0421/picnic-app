export const ORDER = {
    desc: 'DESC',
    asc: 'ASC',
} as const;

type ORDER = typeof ORDER[keyof typeof ORDER];

export const GENDER = {
    FEMAIL: 'F',
    MALE: 'M',
} as const;

type GENDER = typeof GENDER[keyof typeof GENDER];

export const TYPE = {
    subscription: 'SUBSCRIPTION',
    mystar: 'MYSTAR',
    gst: 'GST',
} as const;

type TYPE = typeof TYPE[keyof typeof TYPE];

export const POLICY_LEGALITY = {
    PRIVACY_KO: 'PRIVACY_KO',
    PRIVACY_EN: 'PRIVACY_EN',
    TERMS_KO: 'TERMS_KO',
    TERMS_EN: 'TERMS_EN',
    WITHDRAW_ACCOUNT_KO: 'WITHDRAW_ACCOUNT_KO',
    WITHDRAW_ACCOUNT_EN: 'WITHDRAW_ACCOUNT_EN',
} as const;

type POLICY_LEGALITY = typeof POLICY_LEGALITY[keyof typeof POLICY_LEGALITY];

export enum Policy {
    PRIVACY_KO = 'PRIVACY_KO',
    PRIVACY_EN = 'PRIVACY_EN',
    TERMS_KO = 'TERMS_KO',
    TERMS_EN = 'TERMS_EN',
    WITHDRAW_ACCOUNT_KO = 'WITHDRAW_ACCOUNT_KO',
    WITHDRAW_ACCOUNT_EN = 'WITHDRAW_ACCOUNT_EN',
}

export const LANGUAGE = {
    KO: 'KO',
    EN: 'EN',
} as const;

type LANGUAGE = typeof LANGUAGE[keyof typeof LANGUAGE];

export type PolicyType<T> = T[keyof T];
