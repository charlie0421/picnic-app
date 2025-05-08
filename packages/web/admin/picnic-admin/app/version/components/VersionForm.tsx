'use client';

import { Form, Input, Button } from 'antd';
import { Version } from '@/lib/types/version';
import { FormProps } from 'antd';

interface VersionFormProps {
  mode: 'create' | 'edit';
  id?: string;
  formProps: FormProps;
  saveButtonProps?: {
    onClick?: () => void;
  };
}

export default function VersionForm({
  mode,
  id,
  formProps,
  saveButtonProps,
}: VersionFormProps) {
  return (
    <Form {...formProps} layout='vertical'>
      <Form.Item label='Android' required style={{ marginBottom: 0 }}>
        <Form.Item
          label='권장 업데이트 버전'
          name={['android', 'version']}
          rules={[
            {
              required: true,
              message: 'Android 권장 업데이트 버전을 입력해주세요',
            },
          ]}
          style={{
            display: 'inline-block',
            width: 'calc(33% - 8px)',
            marginRight: 8,
          }}
        >
          <Input placeholder='권장 업데이트 버전' />
        </Form.Item>
        <Form.Item
          label='강제 업데이트 버전'
          name={['android', 'force_version']}
          rules={[
            {
              required: true,
              message: 'Android 강제 업데이트 버전을 입력해주세요',
            },
          ]}
          style={{
            display: 'inline-block',
            width: 'calc(33% - 8px)',
            marginRight: 8,
          }}
        >
          <Input placeholder='강제 업데이트 버전' />
        </Form.Item>
        <Form.Item
          label='URL'
          name={['android', 'url']}
          rules={[{ required: true, message: 'Android URL을 입력해주세요' }]}
          style={{ display: 'inline-block', width: 'calc(33% - 8px)' }}
        >
          <Input placeholder='URL' />
        </Form.Item>
      </Form.Item>

      <Form.Item label='iOS' required style={{ marginBottom: 0 }}>
        <Form.Item
          label='권장 업데이트 버전'
          name={['ios', 'version']}
          rules={[
            {
              required: true,
              message: 'iOS 권장 업데이트 버전을 입력해주세요',
            },
          ]}
          style={{
            display: 'inline-block',
            width: 'calc(33% - 8px)',
            marginRight: 8,
          }}
        >
          <Input placeholder='권장 업데이트 버전' />
        </Form.Item>
        <Form.Item
          label='강제 업데이트 버전'
          name={['ios', 'force_version']}
          rules={[
            {
              required: true,
              message: 'iOS 강제 업데이트 버전을 입력해주세요',
            },
          ]}
          style={{
            display: 'inline-block',
            width: 'calc(33% - 8px)',
            marginRight: 8,
          }}
        >
          <Input placeholder='강제 업데이트 버전' />
        </Form.Item>
        <Form.Item
          label='URL'
          name={['ios', 'url']}
          rules={[{ required: true, message: 'iOS URL을 입력해주세요' }]}
          style={{ display: 'inline-block', width: 'calc(33% - 8px)' }}
        >
          <Input placeholder='URL' />
        </Form.Item>
      </Form.Item>

      <Form.Item label='Windows' style={{ marginBottom: 0 }}>
        <Form.Item
          label='권장 업데이트 버전'
          name={['windows', 'version']}
          style={{
            display: 'inline-block',
            width: 'calc(33% - 8px)',
            marginRight: 8,
          }}
        >
          <Input placeholder='권장 업데이트 버전' />
        </Form.Item>
        <Form.Item
          label='강제 업데이트 버전'
          name={['windows', 'force_version']}
          style={{
            display: 'inline-block',
            width: 'calc(33% - 8px)',
            marginRight: 8,
          }}
        >
          <Input placeholder='강제 업데이트 버전' />
        </Form.Item>
        <Form.Item
          label='URL'
          name={['windows', 'url']}
          style={{ display: 'inline-block', width: 'calc(33% - 8px)' }}
        >
          <Input placeholder='URL' />
        </Form.Item>
      </Form.Item>

      <Form.Item label='Linux' style={{ marginBottom: 0 }}>
        <Form.Item
          label='권장 업데이트 버전'
          name={['linux', 'version']}
          style={{
            display: 'inline-block',
            width: 'calc(33% - 8px)',
            marginRight: 8,
          }}
        >
          <Input placeholder='권장 업데이트 버전' />
        </Form.Item>
        <Form.Item
          label='강제 업데이트 버전'
          name={['linux', 'force_version']}
          style={{
            display: 'inline-block',
            width: 'calc(33% - 8px)',
            marginRight: 8,
          }}
        >
          <Input placeholder='강제 업데이트 버전' />
        </Form.Item>
        <Form.Item
          label='URL'
          name={['linux', 'url']}
          style={{ display: 'inline-block', width: 'calc(33% - 8px)' }}
        >
          <Input placeholder='URL' />
        </Form.Item>
      </Form.Item>

      <Form.Item label='macOS' style={{ marginBottom: 0 }}>
        <Form.Item
          label='권장 업데이트 버전'
          name={['macos', 'version']}
          style={{
            display: 'inline-block',
            width: 'calc(33% - 8px)',
            marginRight: 8,
          }}
        >
          <Input placeholder='권장 업데이트 버전' />
        </Form.Item>
        <Form.Item
          label='강제 업데이트 버전'
          name={['macos', 'force_version']}
          style={{
            display: 'inline-block',
            width: 'calc(33% - 8px)',
            marginRight: 8,
          }}
        >
          <Input placeholder='강제 업데이트 버전' />
        </Form.Item>
        <Form.Item
          label='URL'
          name={['macos', 'url']}
          style={{ display: 'inline-block', width: 'calc(33% - 8px)' }}
        >
          <Input placeholder='URL' />
        </Form.Item>
      </Form.Item>
    </Form>
  );
}
