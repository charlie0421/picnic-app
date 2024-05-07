import { BaseEntitiy } from './base.entitiy';
import type { PaginationInfo } from './pagination-info';
export declare class EventBanner extends BaseEntitiy {
    tag_ko: string;
    tag_en: string;
    title_ko: string;
    title_en: string;
    subtitle_ko: string;
    subtitle_en: string;
    event_img_ko: string;
    getImageKo(): void;
    event_img_en: string;
    getImageEn(): void;
    url: string;
    start_at: Date;
    end_at: Date;
}
export declare class PaginatedEventBanner {
    items: EventBanner[];
    meta: PaginationInfo;
}
