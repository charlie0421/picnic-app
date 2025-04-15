'use client';

import { Edit, useForm } from '@refinedev/antd';
import { Form, Input, Switch, Button, Space, Divider, Select } from 'antd';
import { useGetIdentity, useNavigation } from '@refinedev/core';
import { AuthorizePage } from '@/components/auth/AuthorizePage';
import { useEffect } from 'react';
import TextEditor from '@/components/ui/TextEditor';
import { QnA } from '@/lib/types/qna';

const { Option } = Select;

export default function QnAEditPage({ params }: { params: { id: string } }) {
  const { goBack } = useNavigation();
  const { formProps, saveButtonProps, queryResult } = useForm<QnA>({
    resource: 'qnas',
    id: params.id,
    redirect: 'show',
    meta: {
      idField: 'qna_id',
    },
  });

  const qnaData = queryResult?.data?.data;
  const { data: identity } = useGetIdentity<{ id: string }>();

  // 폼 제출 핸들러 (추가 데이터 설정)
  const handleSubmit = async (values: any) => {
    // 답변이 추가되었는지 확인
    if (values.answer && (!qnaData?.answer || qnaData.answer !== values.answer)) {
      // 답변자 정보와 답변 시각 설정
      values.answered_by = identity?.id;
      values.answered_at = new Date().toISOString();
      
      // 상태를 '답변 완료'로 변경
      if (values.status === 'PENDING') {
        values.status = 'ANSWERED';
      }
    }
    
    return values;
  };

  return (
    <AuthorizePage resource="qnas" action="edit">
      <Edit
        title="질문 수정/답변"
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
          onFinish={handleSubmit}
        >
          <Form.Item
            label="제목"
            name="title"
            rules={[{ required: true, message: '제목을 입력해주세요' }]}
          >
            <Input placeholder="제목을 입력하세요" />
          </Form.Item>

          <Form.Item
            label="질문 내용"
            name="question"
            rules={[{ required: true, message: '질문 내용을 입력해주세요' }]}
          >
            <TextEditor />
          </Form.Item>
          
          <Space>
            <Form.Item
              label="비공개 질문"
              name="is_private"
              valuePropName="checked"
              help="비공개 질문은 본인과 관리자만 볼 수 있습니다."
            >
              <Switch />
            </Form.Item>
            
            <Form.Item
              label="상태"
              name="status"
              rules={[{ required: true }]}
              style={{ marginLeft: 20 }}
            >
              <Select style={{ width: 150 }}>
                <Option value="PENDING">대기중</Option>
                <Option value="ANSWERED">답변완료</Option>
                <Option value="ARCHIVED">보관</Option>
              </Select>
            </Form.Item>
          </Space>

          <Divider>답변 작성</Divider>

          <Form.Item
            label="답변"
            name="answer"
            help="답변을 작성하면 상태가 자동으로 '답변완료'로 변경됩니다."
          >
            <TextEditor />
          </Form.Item>
        </Form>
      </Edit>
    </AuthorizePage>
  );
} 