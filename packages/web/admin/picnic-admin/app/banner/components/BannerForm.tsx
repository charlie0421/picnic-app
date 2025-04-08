'use client';

import { Form, Input, DatePicker, InputNumber } from 'antd';
import { Banner } from '@/lib/types/banner';

type BannerFormProps = {
    mode: 'create' | 'edit' | 'show';
    initialValues?: Banner;
    readOnly?: boolean;
};

export default function BannerForm({ mode, initialValues, readOnly }: BannerFormProps) {
    return (
        <Form layout="vertical" initialValues={initialValues} disabled={readOnly}>
            <Form.Item label="제목" name={['title', 'ko']}>
                <Input />
            </Form.Item>
            <Form.Item label="내용" name={['content', 'ko']}
                rules={[
                    {
                        required: true,
                        message: '내용을 입력해주세요',
                    },
                ]}
            >
                <Input.TextArea rows={4} />
            </Form.Item>
            <Form.Item label="썸네일" name="thumbnail">
                <Input />
            </Form.Item>
            <Form.Item label="시작일" name="start_at"
                rules={[
                    {
                        required: true,
                        message: '시작일을 선택해주세요',
                    },
                ]}
            >
                <DatePicker showTime />
            </Form.Item>
            <Form.Item label="종료일" name="end_at"
                rules={[
                    {
                        required: true,
                        message: '종료일을 선택해주세요',
                    },
                ]}
            >
                <DatePicker showTime />
            </Form.Item>
            <Form.Item label="순서" name="order">
                <InputNumber />
            </Form.Item>
            <Form.Item label="지속시간" name="duration">
                <InputNumber />
            </Form.Item>
            <Form.Item label="링크" name="link">
                <Input />
            </Form.Item>
        </Form>
    );
}
