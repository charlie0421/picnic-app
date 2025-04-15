import { Form, Input, Switch, Select, Upload, Button } from 'antd';
import { UploadOutlined } from '@ant-design/icons';
import { useState, useEffect } from 'react';
import { PostCreateInput } from '../../../lib/types/post';

interface PostFormProps {
  formProps: any;
  boardOptions?: { label: string; value: string }[];
  initialFileList?: any[];
  onSave?: (values: any) => any;
}

export const PostForm: React.FC<PostFormProps> = ({
  formProps,
  boardOptions = [],
  initialFileList = [],
  onSave,
}) => {
  const [fileList, setFileList] = useState<any[]>(initialFileList);

  // 초기 파일 목록 설정
  useEffect(() => {
    if (initialFileList.length > 0) {
      setFileList(initialFileList);
    }
  }, [initialFileList]);

  // 저장 처리
  const handleSave = async (values: any) => {
    const transformedValues: PostCreateInput = {
      ...values,
      attachments: fileList.map((file) => file.name || file.url),
    };
    
    if (onSave) {
      return onSave(transformedValues);
    }
    
    return transformedValues;
  };

  const uploadProps = {
    onRemove: (file: any) => {
      const index = fileList.indexOf(file);
      const newFileList = fileList.slice();
      newFileList.splice(index, 1);
      setFileList(newFileList);
    },
    beforeUpload: (file: any) => {
      setFileList([...fileList, file]);
      return false;
    },
    fileList,
  };

  return (
    <Form {...formProps} layout="vertical">
      <Form.Item
        name="title"
        label="제목"
        rules={[{ required: true, message: '제목을 입력해주세요' }]}
      >
        <Input />
      </Form.Item>

      <Form.Item
        name="content"
        label="내용"
        rules={[{ required: true, message: '내용을 입력해주세요' }]}
      >
        <Input.TextArea rows={6} />
      </Form.Item>

      <Form.Item name="board_id" label="게시판">
        <Select
          placeholder="게시판 선택"
          allowClear
          options={boardOptions}
        />
      </Form.Item>

      <Form.Item
        name="user_id"
        label="작성자"
        rules={[{ required: true, message: '작성자를 입력해주세요' }]}
      >
        <Input />
      </Form.Item>

      <Form.Item
        name="is_anonymous"
        label="익명 여부"
        valuePropName="checked"
        initialValue={false}
      >
        <Switch />
      </Form.Item>

      <Form.Item
        name="is_hidden"
        label="숨김 여부"
        valuePropName="checked"
        initialValue={false}
      >
        <Switch />
      </Form.Item>

      <Form.Item
        name="is_temporary"
        label="임시 저장"
        valuePropName="checked"
        initialValue={false}
      >
        <Switch />
      </Form.Item>

      <Form.Item label="첨부 파일">
        <Upload {...uploadProps}>
          <Button icon={<UploadOutlined />}>파일 선택</Button>
        </Upload>
      </Form.Item>
    </Form>
  );
}; 