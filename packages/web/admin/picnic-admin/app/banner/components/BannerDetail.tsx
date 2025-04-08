'use client';

import { Typography, Image } from 'antd';
import { Banner } from '@/lib/types/banner';
import { getCdnImageUrl } from '@/lib/image';

const { Title, Text } = Typography;

type BannerDetailProps = {
    record?: Banner;
    loading?: boolean;
};

export default function BannerDetail({ record, loading }: BannerDetailProps) {
    console.log(record);
    return (
        <>
            <Title level={5}>이미지 (한국어)</Title>
            <Image src={getCdnImageUrl(record?.image?.ko)} alt='배너 이미지 (한국어)' width={300} preview={false} />

            <Title level={5}>이미지 (영어)</Title>
            <Image src={getCdnImageUrl(record?.image?.en)} alt='배너 이미지 (영어)' width={300} preview={false} />

            <Title level={5}>제목 (일본어)</Title>
            <Image src={getCdnImageUrl(record?.image?.ja)} alt='배너 이미지 (일본어)' width={300} preview={false} />

            <Title level={5}>제목 (중국어)</Title>
            <Image src={getCdnImageUrl(record?.image?.zh)} alt='배너 이미지 (중국어)' width={300} preview={false} />

            <Title level={5}>시작일</Title>
            <Text>{record?.start_at?.toLocaleString()}</Text>

            <Title level={5}>종료일</Title>
            <Text>{record?.end_at?.toLocaleString()}</Text>

            <Title level={5}>순서</Title>
            <Text>{record?.order}</Text>

            <Title level={5}>위치</Title>
            <Text>{record?.location}</Text>

            <Title level={5}>지속시간</Title>
            <Text>{record?.duration}</Text>

            <Title level={5}>링크</Title>
            <Text>{record?.link}</Text>
        </>
    );
}
