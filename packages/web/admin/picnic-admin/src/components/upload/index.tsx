'use client';

import { useState, useEffect } from 'react';
import { Upload, Button, message } from 'antd';
import {
  UploadOutlined,
  LoadingOutlined,
  DeleteOutlined,
} from '@ant-design/icons';
import { v4 as uuidv4 } from 'uuid';
import { uploadToS3, deleteFromS3 } from '@/utils/s3';
import { getImageUrl } from '@/utils/image';

interface ImageUploadProps {
  value?: string;
  onChange?: (url: string) => void;
  bucket?: string;
  folder?: string;
  maxSize?: number; // MB 단위
  width?: number | string;
  height?: number | string;
}

export default function ImageUpload({
  value,
  onChange,
  bucket = 'picnic-prod-cdn',
  folder = 'vote',
  maxSize = 5, // 기본 5MB
  width = 200,
  height = 200,
}: ImageUploadProps) {
  const [loading, setLoading] = useState(false);
  const [imageUrl, setImageUrl] = useState<string | undefined>(value);
  const [imageLoading, setImageLoading] = useState(true);
  const [isDeleting, setIsDeleting] = useState(false);

  useEffect(() => {
    setImageUrl(value);
    if (value) {
      setImageLoading(true);
    }
  }, [value]);

  const handleImageLoad = () => {
    setImageLoading(false);
  };

  const handleImageLoadStart = () => {
    setImageLoading(true);
  };

  const handleImageError = (e: React.SyntheticEvent<HTMLImageElement>) => {
    console.error('이미지 로드 오류:', e);
    setImageLoading(false);
    message.error('이미지 로드에 실패했습니다.');
  };

  const beforeUpload = (file: File) => {
    const isImage = file.type.startsWith('image/');
    if (!isImage) {
      message.error('이미지 파일만 업로드할 수 있습니다!');
      return false;
    }

    const isLessThanMaxSize = file.size / 1024 / 1024 < maxSize;
    if (!isLessThanMaxSize) {
      message.error(`이미지 크기는 ${maxSize}MB 이하여야 합니다!`);
      return false;
    }

    return true;
  };

  const customUpload = async (options: any) => {
    const { file, onSuccess, onError } = options;

    try {
      setLoading(true);

      // 고유한 파일명 생성 (UUID + 원본 확장자)
      const fileExt = file.name.split('.').pop();
      const fileName = `${uuidv4()}.${fileExt}`;
      const filePath = `${folder}/${fileName}`;
      // AWS S3에 파일 업로드
      await uploadToS3(file, bucket, folder, fileName);

      // 업로드 성공 핸들링 - filePath만 저장하여 전달
      setImageUrl(filePath);
      if (onChange) {
        try {
          onChange(filePath);
        } catch (changeError) {
          console.error('onChange 호출 중 오류 발생:', changeError);
        }
      }

      message.success('이미지가 성공적으로 업로드되었습니다!');
      onSuccess(filePath, file);
    } catch (error) {
      console.error('업로드 오류 상세 정보:', error);
      message.error('이미지 업로드 중 오류가 발생했습니다.');
      onError(error);
    } finally {
      setLoading(false);
    }
  };

  const handleRemove = async (e: React.MouseEvent) => {
    e.stopPropagation(); // 이벤트 버블링 방지
    try {
      if (imageUrl) {
        setIsDeleting(true);
        // 이미지 URL에서 경로 정보만 추출 (folder/file.ext 형식)
        await deleteFromS3(imageUrl, bucket);
        message.success('이미지가 성공적으로 삭제되었습니다.');
        setImageUrl(undefined);
        if (onChange) {
          onChange('');
        }
      }
    } catch (error) {
      console.error('이미지 삭제 오류:', error);
      message.error('이미지 삭제 중 오류가 발생했습니다.');
    } finally {
      setIsDeleting(false);
    }
  };

  return (
    <div className='image-upload-container'>
      <Upload
        customRequest={customUpload}
        showUploadList={false}
        beforeUpload={beforeUpload}
        disabled={loading || isDeleting}
      >
        <div className='image-upload-wrapper'>
          {imageUrl ? (
            <div className='image-preview'>
              {imageLoading && (
                <div className='image-loading'>
                  <LoadingOutlined style={{ fontSize: '32px' }} />
                  <div className='loading-text'>이미지 로딩 중...</div>
                </div>
              )}
              <img
                src={getImageUrl(imageUrl)}
                alt='Preview'
                style={{ width, height, objectFit: 'cover' }}
                onLoad={handleImageLoad}
                onLoadStart={handleImageLoadStart}
                onError={handleImageError}
              />
            </div>
          ) : (
            <div className='upload-placeholder'>
              {loading ? (
                <div className='upload-loading'>
                  <LoadingOutlined style={{ fontSize: '32px' }} />
                  <div className='loading-text'>이미지 업로드 중...</div>
                </div>
              ) : (
                <>
                  <UploadOutlined style={{ fontSize: '32px' }} />
                  <div className='upload-text'>이미지 업로드</div>
                </>
              )}
            </div>
          )}
        </div>
      </Upload>
      {imageUrl && (
        <div className='image-actions'>
          <Button
            type='text'
            icon={<DeleteOutlined style={{ fontSize: '18px' }} />}
            onClick={handleRemove}
            disabled={loading || isDeleting}
            loading={isDeleting}
            size='large'
          >
            삭제
          </Button>
        </div>
      )}
      <style jsx>{`
        .image-upload-container {
          width: ${width}px;
          height: ${height}px;
          position: relative;
          display: flex;
          align-items: flex-start;
          gap: 8px;
        }

        .image-upload-wrapper {
          width: 100%;
          height: 100%;
          border: 1px dashed #d9d9d9;
          border-radius: 8px;
          cursor: pointer;
          position: relative;
          overflow: hidden;
          transition: border-color 0.3s;
        }

        .image-upload-wrapper:hover {
          border-color: #1890ff;
        }

        .image-preview {
          width: 100%;
          height: 100%;
          position: relative;
        }

        .image-preview img {
          width: 100%;
          height: 100%;
          object-fit: cover;
        }

        .image-loading {
          position: absolute;
          top: 0;
          left: 0;
          right: 0;
          bottom: 0;
          display: flex;
          flex-direction: column;
          align-items: center;
          justify-content: center;
          background: rgba(255, 255, 255, 0.95);
          z-index: 1;
          gap: 12px;
        }

        .image-loading :global(.anticon) {
          color: #1890ff;
        }

        .loading-text {
          font-size: 14px;
          color: #1890ff;
          font-weight: 500;
        }

        .upload-loading {
          display: flex;
          flex-direction: column;
          align-items: center;
          justify-content: center;
          gap: 12px;
        }

        .upload-loading :global(.anticon) {
          color: #1890ff;
        }

        .upload-placeholder {
          width: 100%;
          height: 100%;
          display: flex;
          flex-direction: column;
          align-items: center;
          justify-content: center;
          color: #8c8c8c;
          gap: 8px;
        }

        .upload-placeholder :global(.anticon) {
          color: #8c8c8c;
        }

        .upload-text {
          font-size: 14px;
          font-weight: 500;
        }

        .image-actions {
          position: relative;
          z-index: 2;
        }

        .image-actions .ant-btn {
          color: #ff4d4f;
          background: white;
          border: 2px solid #ff4d4f;
          border-radius: 6px;
          padding: 8px 16px;
          height: auto;
          font-size: 14px;
          font-weight: 500;
          display: flex;
          align-items: center;
          gap: 6px;
          box-shadow: 0 2px 8px rgba(255, 77, 79, 0.15);
          transition: all 0.3s ease;
        }

        .image-actions .ant-btn:hover {
          color: white;
          background: #ff4d4f;
          transform: translateY(-1px);
          box-shadow: 0 4px 12px rgba(255, 77, 79, 0.25);
        }

        .image-actions .ant-btn:active {
          transform: translateY(0);
        }

        .image-actions .ant-btn:disabled {
          color: rgba(0, 0, 0, 0.25);
          background: white;
          border-color: #d9d9d9;
          box-shadow: none;
        }

        .image-actions .ant-btn-loading {
          opacity: 0.8;
        }
      `}</style>
    </div>
  );
}
