import { BaseEntitiy } from './base.entitiy';
import { PaginationInfo } from './pagination-info';
export type UserNotificationType = 'EMERGENCY_MATCH' | 'SOCIAL_MATCH_REQUEST' | 'TEAM_MATCH_REQUEST' | 'NOTICE';
export declare class UserNotification extends BaseEntitiy {
    uid?: number;
    type?: UserNotificationType;
    message?: string;
    referenceId?: number;
    isRead?: boolean;
}
export declare class PaginatedUserNotification {
    items: UserNotification[];
    meta: PaginationInfo;
}
