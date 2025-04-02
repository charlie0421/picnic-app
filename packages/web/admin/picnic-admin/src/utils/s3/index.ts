import { S3Client, PutObjectCommand } from '@aws-sdk/client-s3';

// AWS S3 클라이언트 설정
export const getS3Client = () => {
  const region = process.env.NEXT_PUBLIC_AWS_REGION;
  const accessKeyId = process.env.NEXT_PUBLIC_AWS_ACCESS_KEY_ID;
  const secretAccessKey = process.env.NEXT_PUBLIC_AWS_SECRET_ACCESS_KEY;

  if (!region || !accessKeyId || !secretAccessKey) {
    throw new Error(
      'AWS 설정이 완료되지 않았습니다. 환경 변수를 확인해주세요.',
    );
  }

  return new S3Client({
    region,
    credentials: {
      accessKeyId,
      secretAccessKey,
    },
  });
};

/**
 * AWS S3에 파일 업로드
 * @param file 업로드할 파일
 * @param bucket S3 버킷 이름
 * @param key 파일 경로 및 이름
 * @returns 업로드된 URL
 */
export const uploadToS3 = async (
  file: File,
  bucket: string,
  key: string,
): Promise<string> => {
  try {
    console.log('S3 업로드 시작:', { bucket, key, fileType: file.type });

    // 환경 변수 확인 로그
    console.log('S3 환경 변수 확인:', {
      region: process.env.NEXT_PUBLIC_AWS_REGION ? 'Ok' : 'Missing',
      accessKey: process.env.NEXT_PUBLIC_AWS_ACCESS_KEY_ID ? 'Ok' : 'Missing',
      secretKey: process.env.NEXT_PUBLIC_AWS_SECRET_ACCESS_KEY
        ? 'Ok'
        : 'Missing',
      s3Url: process.env.NEXT_PUBLIC_AWS_S3_URL,
    });

    const s3Client = getS3Client();

    // 파일을 바이너리 데이터로 변환
    const fileArrayBuffer = await file.arrayBuffer();
    const fileBuffer = Buffer.from(fileArrayBuffer);
    console.log('파일 변환 완료, 크기:', fileBuffer.length, 'bytes');

    // S3에 업로드
    const command = new PutObjectCommand({
      Bucket: bucket,
      Key: key,
      Body: fileBuffer,
      ContentType: file.type,
      ACL: 'public-read', // 공개 읽기 권한 설정
    });

    console.log('S3 명령 생성, 업로드 시작');
    const result = await s3Client.send(command);
    console.log('S3 업로드 응답:', result);

    // 업로드된 파일의 URL 생성
    const cdnUrl = process.env.NEXT_PUBLIC_AWS_S3_URL;

    if (!cdnUrl) {
      console.warn('NEXT_PUBLIC_AWS_S3_URL 환경 변수가 설정되지 않았습니다');
    }

    const s3Url = `${cdnUrl}/${key}`;
    console.log('생성된 S3 URL:', s3Url);
    return s3Url;
  } catch (error) {
    console.error('S3 업로드 오류 상세:', error);
    throw error;
  }
};

/**
 * S3 이미지 URL 가져오기
 * @param key S3 오브젝트 키
 * @returns 이미지 URL
 */
export const getS3ImageUrl = (path: string): string => {
  const cdnUrl = process.env.NEXT_PUBLIC_AWS_S3_URL;

  if (!path) return '';

  // path가 이미 전체 URL인 경우 (스토리지 마이그레이션 고려)
  if (path.startsWith('http')) {
    return path;
  }

  if (!cdnUrl) {
    console.warn('NEXT_PUBLIC_AWS_S3_URL이 정의되지 않았습니다');
    return path;
  }

  return `${cdnUrl}/${path}`;
};
