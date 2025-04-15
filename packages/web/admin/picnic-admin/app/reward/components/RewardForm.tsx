'use client';

import { SaveButtonProps } from '@refinedev/antd';
import {
  Form,
  Input,
  InputNumber,
  Tabs,
  Upload,
  FormProps,
  message,
  Row,
  Col,
  Card,
} from 'antd';
import { PlusOutlined } from '@ant-design/icons';
import { useState, useEffect } from 'react';
import { Reward, defaultLocalizations } from './types';
import { UploadFile } from 'antd/lib/upload/interface';
import { getCdnImageUrl } from '@/lib/image';
import { getLanguageLabel } from '@/lib/utils/language';

interface RewardFormProps {
  formProps: FormProps;
  saveButtonProps: SaveButtonProps;
  mode: 'create' | 'edit';
}

export default function RewardForm({
  formProps,
  saveButtonProps,
  mode,
}: RewardFormProps) {
  const [messageApi, contextHolder] = message.useMessage();
  const [initialValues, setInitialValues] = useState<any>(
    formProps.initialValues || {},
  );

  // 초기값이 변경될 때 이미지 파일 목록 형식으로 변환
  useEffect(() => {
    if (formProps.initialValues) {
      const values = { ...formProps.initialValues };

      console.log('RewardForm 초기값:', values); // 디버그용 로그

      // 썸네일 처리
      if (values.thumbnail) {
        values.thumbnail = [
          {
            uid: '-1',
            name: 'thumbnail.jpg',
            status: 'done',
            url: getCdnImageUrl(values.thumbnail, 100),
            thumbUrl: getCdnImageUrl(values.thumbnail, 100),
          },
        ];
      }

      // 개요 이미지 처리
      if (values.overview_images && Array.isArray(values.overview_images)) {
        values.overview_images = values.overview_images.map((url, index) => ({
          uid: `-${index + 1}`,
          name: `overview-${index + 1}.jpg`,
          status: 'done',
          url: getCdnImageUrl(url, 100),
          thumbUrl: getCdnImageUrl(url, 100),
        }));
      } else {
        values.overview_images = [];
      }

      // 위치 이미지 처리
      if (values.location_images && Array.isArray(values.location_images)) {
        values.location_images = values.location_images.map((url, index) => ({
          uid: `-${index + 1}`,
          name: `location-${index + 1}.jpg`,
          status: 'done',
          url: getCdnImageUrl(url, 100),
          thumbUrl: getCdnImageUrl(url, 100),
        }));
      } else {
        values.location_images = [];
      }

      // 사이즈 가이드 이미지 처리
      if (values.size_guide_images && Array.isArray(values.size_guide_images)) {
        values.size_guide_images = values.size_guide_images.map(
          (url, index) => ({
            uid: `-${index + 1}`,
            name: `size-guide-${index + 1}.jpg`,
            status: 'done',
            url: getCdnImageUrl(url, 100),
            thumbUrl: getCdnImageUrl(url, 100),
          }),
        );
      } else {
        values.size_guide_images = [];
      }

      // 사이즈 가이드 데이터 처리 (문자열로 저장된 경우 파싱)
      if (!values.size_guide) values.size_guide = {};

      defaultLocalizations.forEach((locale) => {
        if (!values.size_guide[locale]) {
          values.size_guide[locale] = '';
          return;
        }

        if (typeof values.size_guide[locale] === 'string') {
          if (values.size_guide[locale].trim() === '') {
            values.size_guide[locale] = '';
            return;
          }

          try {
            // JSON 문자열인 경우 파싱
            if (
              values.size_guide[locale].trim().startsWith('[') ||
              values.size_guide[locale].trim().startsWith('{')
            ) {
              const parsed = JSON.parse(values.size_guide[locale]);
              // 다시 문자열로 변환하여 JSON 형식 유지
              values.size_guide[locale] = JSON.stringify(parsed, null, 2);
            }
          } catch (e) {
            console.error(`사이즈 가이드 데이터 파싱 오류 (${locale}):`, e);
          }
        } else if (typeof values.size_guide[locale] === 'object') {
          // 객체인 경우 문자열로 변환
          values.size_guide[locale] = JSON.stringify(
            values.size_guide[locale],
            null,
            2,
          );
        }
      });

      // title과 location 데이터가 null 또는 undefined인 경우 빈 객체로 초기화
      if (!values.title) values.title = {};

      defaultLocalizations.forEach((locale) => {
        if (!values.title[locale]) values.title[locale] = '';
      });

      if (!values.location) values.location = {};

      defaultLocalizations.forEach((locale) => {
        if (!values.location[locale]) values.location[locale] = '';
      });

      // 순서가 null인 경우 0으로 초기화
      if (values.order === null || values.order === undefined) {
        values.order = 0;
      }

      console.log('RewardForm 처리 후 값:', values); // 처리 후 값 로깅
      setInitialValues(values);
    } else {
      // 초기값이 없는 경우(새로 생성) 기본값 설정
      const defaultValues: Record<string, any> = {
        title: {} as Record<string, string>,
        location: {} as Record<string, string>,
        size_guide: {} as Record<string, any>,
        overview_images: [],
        location_images: [],
        size_guide_images: [],
        order: 0,
      };

      defaultLocalizations.forEach((locale) => {
        defaultValues.title[locale] = '';
        defaultValues.location[locale] = '';
        defaultValues.size_guide[locale] = '';
      });

      console.log('RewardForm 기본값 설정:', defaultValues);
      setInitialValues(defaultValues);
    }
  }, [formProps.initialValues]);

  const normFile = (e: any) => {
    console.log('normFile 함수 호출됨:', e);

    // e가 배열인 경우
    if (Array.isArray(e)) {
      return e;
    }

    // e가 undefined 또는 null인 경우 빈 배열 반환
    if (!e) {
      console.log('normFile: e가 undefined 또는 null임, 빈 배열 반환');
      return [];
    }

    // e.fileList가 있고 배열인 경우
    if (e.fileList && Array.isArray(e.fileList)) {
      return e.fileList;
    }

    // e.file이 있는 경우 (단일 파일)
    if (e.file) {
      return [e.file];
    }

    // 그 외의 경우 빈 배열 반환
    console.log('normFile: 처리할 수 없는 형식, 빈 배열 반환');
    return [];
  };

  // 업로드 완료 후 처리
  const handleUploadChange = (info: any) => {
    if (info.file.status === 'done') {
      const { response } = info.file;
      if (response && response.path) {
        messageApi.success(`${info.file.name} 업로드 성공`);
        // response.path 값을 각 필드에 설정하는 로직 추가 가능
      }
    } else if (info.file.status === 'error') {
      messageApi.error(`${info.file.name} 업로드 실패`);
    }
  };

  return (
    <>
      {contextHolder}
      <Form {...formProps} layout='vertical' initialValues={initialValues}>
        <Card title='기본 정보' style={{ marginBottom: 20 }}>
          <Form.Item label='순서' name='order' rules={[{ type: 'number' }]}>
            <InputNumber min={0} style={{ width: '100%' }} />
          </Form.Item>

          <h3>제목</h3>
          {defaultLocalizations.map((locale) => (
            <Form.Item
              key={`title-${locale}`}
              label={`제목 (${getLanguageLabel(locale)})`}
              name={['title', locale]}
            >
              <Input
                placeholder={`${getLanguageLabel(locale)} 제목을 입력하세요`}
              />
            </Form.Item>
          ))}
        </Card>

        <Card title='이미지 정보' style={{ marginBottom: 20 }}>
          <Form.Item
            label='썸네일'
            name='thumbnail'
            valuePropName='fileList'
            getValueFromEvent={normFile}
          >
            <Upload
              listType='picture-card'
              maxCount={1}
              action='/api/upload'
              accept='image/*'
              onChange={handleUploadChange}
              beforeUpload={(file) => {
                // 파일 타입 검증
                const isImage = file.type.startsWith('image/');
                if (!isImage) {
                  messageApi.error('이미지 파일만 업로드 가능합니다.');
                }
                return isImage ? true : Upload.LIST_IGNORE;
              }}
            >
              <div>
                <PlusOutlined />
                <div style={{ marginTop: 8 }}>업로드</div>
              </div>
            </Upload>
          </Form.Item>

          <Form.Item
            label='개요 이미지'
            name='overview_images'
            valuePropName='fileList'
            getValueFromEvent={normFile}
          >
            <Upload
              listType='picture-card'
              multiple
              action='/api/upload'
              accept='image/*'
              onChange={handleUploadChange}
              beforeUpload={(file) => {
                // 파일 타입 검증
                const isImage = file.type.startsWith('image/');
                if (!isImage) {
                  messageApi.error('이미지 파일만 업로드 가능합니다.');
                }
                return isImage ? true : Upload.LIST_IGNORE;
              }}
            >
              <div>
                <PlusOutlined />
                <div style={{ marginTop: 8 }}>업로드</div>
              </div>
            </Upload>
          </Form.Item>
        </Card>

        <Card title='위치 정보' style={{ marginBottom: 20 }}>
          <Row gutter={[24, 24]}>
            <Col span={12}>
              {defaultLocalizations.map((locale) => (
                <Form.Item
                  key={`location-${locale}`}
                  label={`위치 정보 (${getLanguageLabel(locale)})`}
                  name={['location', locale]}
                >
                  <Input.TextArea
                    rows={4}
                    placeholder={`${getLanguageLabel(
                      locale,
                    )} 위치 정보를 입력하세요`}
                  />
                </Form.Item>
              ))}
            </Col>
            <Col span={12}>
              <Form.Item
                label='위치 이미지'
                name='location_images'
                valuePropName='fileList'
                getValueFromEvent={normFile}
              >
                <Upload
                  listType='picture-card'
                  multiple
                  action='/api/upload'
                  accept='image/*'
                  onChange={handleUploadChange}
                  beforeUpload={(file) => {
                    // 파일 타입 검증
                    const isImage = file.type.startsWith('image/');
                    if (!isImage) {
                      messageApi.error('이미지 파일만 업로드 가능합니다.');
                    }
                    return isImage ? true : Upload.LIST_IGNORE;
                  }}
                >
                  <div>
                    <PlusOutlined />
                    <div style={{ marginTop: 8 }}>업로드</div>
                  </div>
                </Upload>
              </Form.Item>
            </Col>
          </Row>
        </Card>

        <Card title='사이즈 가이드' style={{ marginBottom: 20 }}>
          <Row gutter={[24, 24]}>
            <Col span={12}>
              {defaultLocalizations.map((locale) => (
                <Form.Item
                  key={`size_guide-${locale}`}
                  label={`사이즈 가이드 (${getLanguageLabel(locale)})`}
                  name={['size_guide', locale]}
                  getValueFromEvent={(e) => {
                    // TextArea 값이 변경될 때 JSON 데이터의 경우 문자열로 변환
                    let value = e.target.value;
                    if (
                      value &&
                      (value.trim().startsWith('{') ||
                        value.trim().startsWith('['))
                    ) {
                      try {
                        // 입력값이 유효한 JSON인지 확인
                        JSON.parse(value);
                      } catch (error) {
                        messageApi.error('유효하지 않은 JSON 형식입니다.');
                      }
                    }
                    return value;
                  }}
                  rules={[
                    {
                      validator: (_, value) => {
                        if (!value) return Promise.resolve();
                        if (
                          typeof value === 'string' &&
                          (value.trim().startsWith('{') ||
                            value.trim().startsWith('['))
                        ) {
                          try {
                            JSON.parse(value);
                            return Promise.resolve();
                          } catch (error) {
                            return Promise.reject(
                              '유효하지 않은 JSON 형식입니다.',
                            );
                          }
                        }
                        return Promise.resolve();
                      },
                    },
                  ]}
                >
                  <Input.TextArea
                    rows={8}
                    placeholder={`${getLanguageLabel(
                      locale,
                    )} 사이즈 가이드를 입력하세요. 배열 형식의 JSON 데이터를 입력하세요.
예시: [{"desc": ["설명1", "설명2"], "image": ["이미지경로"]}]`}
                  />
                </Form.Item>
              ))}
            </Col>
            <Col span={12}>
              <Form.Item
                label='사이즈 가이드 이미지'
                name='size_guide_images'
                valuePropName='fileList'
                getValueFromEvent={normFile}
              >
                <Upload
                  listType='picture-card'
                  multiple
                  action='/api/upload'
                  accept='image/*'
                  onChange={handleUploadChange}
                  beforeUpload={(file) => {
                    // 파일 타입 검증
                    const isImage = file.type.startsWith('image/');
                    if (!isImage) {
                      messageApi.error('이미지 파일만 업로드 가능합니다.');
                    }
                    return isImage ? true : Upload.LIST_IGNORE;
                  }}
                >
                  <div>
                    <PlusOutlined />
                    <div style={{ marginTop: 8 }}>업로드</div>
                  </div>
                </Upload>
              </Form.Item>
            </Col>
          </Row>
        </Card>
      </Form>
    </>
  );
}
