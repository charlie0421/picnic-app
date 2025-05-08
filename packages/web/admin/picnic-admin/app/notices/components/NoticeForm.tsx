import { Form, Select, Space, Switch } from 'antd';
import { NoticeFormData } from '@/lib/types/notice';
import MultilingualInput from './MultilingualInput';

const { Option } = Select;

interface NoticeFormProps {
  formProps: any;
  onSubmit?: (values: NoticeFormData) => void;
}

export const NoticeForm = ({ formProps, onSubmit }: NoticeFormProps) => {
  return (
    <Form {...formProps} layout='vertical' onFinish={onSubmit}>
      {/* 다국어 제목 입력 */}
      <MultilingualInput name='title' label='제목' required baseLocale='ko' />

      {/* 다국어 내용 입력 */}
      <MultilingualInput
        name='content'
        label='내용'
        required
        baseLocale='ko'
        useRichText
      />

      <Space>
        <Form.Item label='상태' name='status' rules={[{ required: true }]}>
          <Select style={{ width: 200 }}>
            <Option value='DRAFT'>초안</Option>
            <Option value='PUBLISHED'>발행</Option>
            <Option value='ARCHIVED'>보관</Option>
          </Select>
        </Form.Item>

        <Form.Item label='상단 고정' name='is_pinned' valuePropName='checked'>
          <Switch />
        </Form.Item>
      </Space>
    </Form>
  );
};
