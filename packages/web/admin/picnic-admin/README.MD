# picnic-admin

<div align="center" style="margin: 30px;">
    <a href="https://refine.dev">
    <img alt="refine logo" src="https://refine.ams3.cdn.digitaloceanspaces.com/readme/refine-readme-banner.png">
    </a>
</div>
<br/>

This [Refine](https://github.com/refinedev/refine) project was generated with [create refine-app](https://github.com/refinedev/refine/tree/master/packages/create-refine-app).

## Getting Started

A React Framework for building internal tools, admin panels, dashboards & B2B apps with unmatched flexibility ✨

Refine's hooks and components simplifies the development process and eliminates the repetitive tasks by providing industry-standard solutions for crucial aspects of a project, including authentication, access control, routing, networking, state management, and i18n.

## Available Scripts

### Running the development server.

```bash
    npm run dev
```

### Building for production.

```bash
    npm run build
```

### Running the production server.

```bash
    npm run start
```

## Learn More

To learn more about **Refine**, please check out the [Documentation](https://refine.dev/docs)

- **Supabase Data Provider** [Docs](https://refine.dev/docs/core/providers/data-provider/#overview)
- **Ant Design** [Docs](https://refine.dev/docs/ui-frameworks/antd/tutorial/)

## License

MIT

## 이미지 업로드 기능

투표 생성 및 수정 페이지에서 메인 이미지를 AWS S3에 업로드하고 CDN을 통해 제공할 수 있습니다.

### AWS S3 설정

1. AWS 계정에서 S3 버킷 생성 ('picnic-images' 등)
2. 버킷 권한 설정:
   - CORS 설정 활성화
   - 퍼블릭 액세스 차단 해제 (또는 CloudFront와 함께 사용)
   - 버킷 정책 설정으로 읽기 권한 부여

### CDN 설정 (권장)

1. AWS CloudFront 또는 다른 CDN 서비스 설정
2. 오리진으로 S3 버킷 연결
3. 캐싱 설정 및 HTTPS 활성화

### IAM 설정

1. 이미지 업로드를 위한 IAM 사용자 또는 역할 생성
2. 다음 권한을 부여:
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Action": [
           "s3:PutObject",
           "s3:GetObject",
           "s3:ListBucket"
         ],
         "Resource": [
           "arn:aws:s3:::picnic-images",
           "arn:aws:s3:::picnic-images/*"
         ]
       }
     ]
   }
   ```

### 환경 변수 설정

```
# S3 업로드에 필요한 변수
NEXT_PUBLIC_AWS_REGION=ap-northeast-2
NEXT_PUBLIC_AWS_ACCESS_KEY_ID=your-access-key
NEXT_PUBLIC_AWS_SECRET_ACCESS_KEY=your-secret-key

# 이미지 조회에 사용할 CDN URL
NEXT_PUBLIC_CDN_URL=https://your-cdn-domain.com
```

### 사용 방법

1. 투표 생성 또는 수정 페이지에서 '메인 이미지' 필드에서 '이미지 업로드' 버튼 클릭
2. 이미지 파일 선택 (최대 5MB)
3. 업로드 완료 후 이미지가 미리보기로 표시됨
4. 삭제 버튼을 클릭하여 업로드한 이미지 제거 가능

### 참고

- 이미지는 'vote/main' 폴더에 저장됩니다
- 파일명은 고유한 UUID로 생성되어 중복 방지
- 이미지 조회는 S3에 직접 접근하는 대신 CDN을 통해 이루어져 성능이 향상됩니다
