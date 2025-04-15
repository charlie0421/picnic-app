import { Form, Input, Switch, Select, InputNumber, Space, Button, Tag } from 'antd';
import { PlusOutlined } from '@ant-design/icons';
import { useState, useEffect } from 'react';
import { BoardCreateInput, BoardUpdateInput } from '../../../lib/types/board';
import { MultiLanguageInput } from '@/components/ui';

interface BoardFormProps {
  formProps: any;
  artistOptions?: { label: string; value: string }[];
  boardOptions?: { label: string; value: string }[];
  initialFeatures?: string[];
  onSave?: (values: any) => any;
}

export const BoardForm: React.FC<BoardFormProps> = ({
  formProps,
  artistOptions = [],
  boardOptions = [],
  initialFeatures = [],
  onSave,
}) => {
  const [features, setFeatures] = useState<string[]>(initialFeatures);
  const [inputFeature, setInputFeature] = useState('');

  // 초기 features 설정
  useEffect(() => {
    if (initialFeatures.length > 0) {
      setFeatures(initialFeatures);
    }
  }, [initialFeatures]);

  // 저장 처리
  const handleSave = async (values: any) => {
    const transformedValues: BoardCreateInput | BoardUpdateInput = {
      ...values,
      features: features,
    };

    if (onSave) {
      return onSave(transformedValues);
    }

    return transformedValues;
  };

  // 기능(features) 추가
  const addFeature = () => {
    if (inputFeature && !features.includes(inputFeature)) {
      setFeatures([...features, inputFeature]);
      setInputFeature('');
    }
  };

  // 기능(feature) 삭제
  const removeFeature = (feature: string) => {
    setFeatures(features.filter((item) => item !== feature));
  };

  formProps.onFinish = async (values: any) => {
    const transformedValues = await handleSave(values);
    formProps.onFinish?.(transformedValues);
  };

  return (
    <Form {...formProps} layout="vertical">
      <MultiLanguageInput name="name" label="이름" required />

      <Form.Item
        name="description"
        label="설명"
        rules={[{ required: true, message: '설명을 입력해주세요' }]}
      >
        <Input.TextArea rows={4} />
      </Form.Item>

      <Form.Item name="status" label="상태" initialValue="PENDING">
        <Select
          options={[
            { label: '활성', value: 'ACTIVE' },
            { label: '대기중', value: 'PENDING' },
            { label: '거부됨', value: 'REJECTED' },
          ]}
        />
      </Form.Item>

      <Form.Item
        name="is_official"
        label="공식 게시판"
        valuePropName="checked"
        initialValue={false}
      >
        <Switch />
      </Form.Item>

      <Form.Item name="parent_board_id" label="상위 게시판">
        <Select
          placeholder="상위 게시판 선택"
          allowClear
          options={boardOptions}
        />
      </Form.Item>

      <Form.Item name="artist_id" label="아티스트">
        <Select
          placeholder="아티스트 선택"
          allowClear
          options={artistOptions}
        />
      </Form.Item>

      <Form.Item name="request_message" label="신청 메시지">
        <Input.TextArea rows={3} />
      </Form.Item>

      <Form.Item name="order" label="정렬 순서" initialValue={0}>
        <InputNumber min={0} />
      </Form.Item>

      <Form.Item label="기능">
        <Space style={{ marginBottom: 8 }} wrap>
          {features.map((feature) => (
            <Tag
              key={feature}
              closable
              onClose={() => removeFeature(feature)}
            >
              {feature}
            </Tag>
          ))}
        </Space>
        <Input.Group compact>
          <Input
            style={{ width: 'calc(100% - 78px)' }}
            value={inputFeature}
            onChange={(e) => setInputFeature(e.target.value)}
            onPressEnter={addFeature}
            placeholder="추가할 기능을 입력하세요"
          />
          <Button type="primary" icon={<PlusOutlined />} onClick={addFeature}>
            추가
          </Button>
        </Input.Group>
      </Form.Item>
    </Form>
  );
}; 