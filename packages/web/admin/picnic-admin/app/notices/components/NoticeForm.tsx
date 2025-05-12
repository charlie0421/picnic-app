import { Form, FormProps, Select, Space, Switch } from 'antd';
import MultilingualInput from './MultilingualInput';

const { Option } = Select;

interface NoticeFormProps {
  formProps: FormProps<any>;
}

export const NoticeForm = ({ formProps }: NoticeFormProps) => {
  return (
    <Form {...formProps} layout='vertical'>
      {/* 다국어 제목 입력 */}
      <MultilingualInput name='title' label='제목' required baseLocale='ko' />

      {/* 다국어 내용 입력 */}
      <MultilingualInput
        name='content'
        label='내용'
        required
        baseLocale='ko'
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
