'use client';

import { Edit, useForm } from '@refinedev/antd';
import { Form, Input, Select, Switch, Button, Space } from 'antd';
import { useNavigation } from '@refinedev/core';
import { AuthorizePage } from '@/components/auth/AuthorizePage';
import TextEditor from '@/components/ui/TextEditor';
import { Notice } from '@/lib/types/notice';

const { Option } = Select;

export default function NoticeEditPage({ params }: { params: { id: string } }) {
  const { goBack } = useNavigation();
  const { formProps, saveButtonProps, queryResult } = useForm<Notice>({
    resource: 'notices',
    id: params.id,
    redirect: 'show',
    meta: {
      idField: 'notice_id',
    },
  });

  const noticeData = queryResult?.data?.data;

  return (
    <AuthorizePage resource="notices" action="edit">
      <Edit
        title="공지사항 수정"
        footerButtons={
          <>
            <Button onClick={goBack}>취소</Button>
            <Button type="primary" {...saveButtonProps}>
              저장
            </Button>
          </>
        }
      >
        <Form 
          {...formProps} 
          layout="vertical"
        >
          <Form.Item
            label="제목"
            name="title"
            rules={[{ required: true, message: '제목을 입력해주세요' }]}
          >
            <Input placeholder="제목을 입력하세요" />
          </Form.Item>

          <Form.Item
            label="내용"
            name="content"
            rules={[{ required: true, message: '내용을 입력해주세요' }]}
          >
            <TextEditor />
          </Form.Item>

          <Space>
            <Form.Item
              label="상태"
              name="status"
              rules={[{ required: true }]}
            >
              <Select style={{ width: 200 }}>
                <Option value="DRAFT">초안</Option>
                <Option value="PUBLISHED">발행</Option>
                <Option value="ARCHIVED">보관</Option>
              </Select>
            </Form.Item>

            <Form.Item
              label="상단 고정"
              name="is_pinned"
              valuePropName="checked"
            >
              <Switch />
            </Form.Item>
          </Space>
        </Form>
      </Edit>
    </AuthorizePage>
  );
} 