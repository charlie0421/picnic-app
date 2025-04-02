import { S3Client, PutObjectCommand, DeleteObjectCommand } from '@aws-sdk/client-s3';

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
 * @param folder 하위 폴더
 * @param key 파일 경로 및 이름
 * @returns 업로드된 URL
 */
export const uploadToS3 = async (
  file: File,
  bucket: string = process.env.NEXT_PUBLIC_AWS_S3_BUCKET || 'picnic-prod-cdn',
  folder: string = 'vote',
  key: string,
): Promise<string> => {
  try {
    if (!key) {
      throw new Error('파일 키가 지정되지 않았습니다.');
    }

    // 기본 폴더 가져오기
    const baseFolder = process.env.NEXT_PUBLIC_AWS_S3_BASE_FOLDER || 'picnic';

    // 전체 경로 생성 (기본 폴더 아래에 전달된 folder와 key를 붙임)
    const fullKey = `${baseFolder}/${folder}/${key}`;
    console.log('S3 업로드 시작:', { bucket, fullKey, fileType: file.type });

    // 환경 변수 확인 로그
    console.log('S3 환경 변수 확인:', {
      region: process.env.NEXT_PUBLIC_AWS_REGION ? 'Ok' : 'Missing',
      accessKey: process.env.NEXT_PUBLIC_AWS_ACCESS_KEY_ID ? 'Ok' : 'Missing',
      secretKey: process.env.NEXT_PUBLIC_AWS_SECRET_ACCESS_KEY
        ? 'Ok'
        : 'Missing',
      bucket: process.env.NEXT_PUBLIC_AWS_S3_BUCKET ? 'Ok' : 'Missing',
      baseFolder: process.env.NEXT_PUBLIC_AWS_S3_BASE_FOLDER ? 'Ok' : 'Missing',
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
      Key: fullKey,
      Body: fileBuffer,
      ContentType: file.type,
    });

    console.log('S3 명령 생성, 업로드 시작');
    const result = await s3Client.send(command);
    console.log('S3 업로드 응답:', result);

    // 업로드된 파일의 URL 생성
    const cdnUrl = process.env.NEXT_PUBLIC_CDN_URL;
    if (!cdnUrl) {
      throw new Error('NEXT_PUBLIC_CDN_URL 환경 변수가 설정되지 않았습니다.');
    }

    const s3Url = `${cdnUrl}/${fullKey}`;
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
  const cdnUrl = process.env.NEXT_PUBLIC_CDN_URL;
  const baseFolder = process.env.NEXT_PUBLIC_AWS_S3_BASE_FOLDER || 'picnic';

  if (!path) return '';

  // path가 이미 전체 URL인 경우 (스토리지 마이그레이션 고려)
  if (path.startsWith('http')) {
    return path;
  }

  if (!cdnUrl) {
    console.warn('NEXT_PUBLIC_CDN_URL이 정의되지 않았습니다');
    return path;
  }

  // path가 이미 baseFolder를 포함하고 있는지 확인
  const fullPath = path.startsWith(baseFolder) ? path : `${baseFolder}/${path}`;
  return `${cdnUrl}/${fullPath}`;
};

/**
 * S3에서 이미지 삭제
 * @param key S3 오브젝트 키
 * @param bucket S3 버킷 이름
 */
export const deleteFromS3 = async (
  key: string,
  bucket: string = process.env.NEXT_PUBLIC_AWS_S3_BUCKET || 'picnic-prod-cdn',
): Promise<void> => {
  try {
    // 기본 폴더 가져오기
    const baseFolder = process.env.NEXT_PUBLIC_AWS_S3_BASE_FOLDER || 'picnic';

    // 전체 경로 생성 (기본 폴더 아래에 key를 붙임)
    const fullKey = `${baseFolder}/${key}`;
    console.log('S3 이미지 삭제 시작:', { bucket, fullKey });

    const s3Client = getS3Client();
    const command = new DeleteObjectCommand({
      Bucket: bucket,
      Key: fullKey,
    });

    await s3Client.send(command);
    console.log('S3 이미지 삭제 완료:', fullKey);
  } catch (error) {
    console.error('S3 이미지 삭제 오류:', error);
    throw error;
  }
};
