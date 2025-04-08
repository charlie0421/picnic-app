# 4. AWS 서비스 설정 가이드

## 목차
1. [ECS/Fargate 설정](#ecsfargate-설정)
2. [EventBridge 설정](#eventbridge-설정)
3. [Lambda 설정](#lambda-설정)
4. [SQS 설정](#sqs-설정)
5. [IAM 설정](#iam-설정)
6. [CloudWatch 설정](#cloudwatch-설정)

## ECS/Fargate 설정

### 1. ECS 클러스터 생성
```bash
# ECS 클러스터 생성
aws ecs create-cluster --cluster-name youtube-watcher

# 클러스터 확인
aws ecs describe-clusters --clusters youtube-watcher
```

### 2. 태스크 정의 생성
```json
// task-definition.json
{
  "family": "youtube-watcher",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "1024",
  "memory": "2048",
  "executionRoleArn": "arn:aws:iam::ACCOUNT_ID:role/ecsTaskExecutionRole",
  "taskRoleArn": "arn:aws:iam::ACCOUNT_ID:role/youtube-watcher-task-role",
  "containerDefinitions": [
    {
      "name": "youtube-watcher",
      "image": "ACCOUNT_ID.dkr.ecr.REGION.amazonaws.com/youtube-watcher:latest",
      "essential": true,
      "environment": [
        {
          "name": "SUPABASE_URL",
          "value": "YOUR_SUPABASE_URL"
        },
        {
          "name": "SUPABASE_KEY",
          "value": "YOUR_SUPABASE_KEY"
        }
      ],
      "secrets": [
        {
          "name": "YOUTUBE_CLIENT_ID",
          "valueFrom": "arn:aws:ssm:REGION:ACCOUNT_ID:parameter/youtube/client-id"
        },
        {
          "name": "YOUTUBE_CLIENT_SECRET",
          "valueFrom": "arn:aws:ssm:REGION:ACCOUNT_ID:parameter/youtube/client-secret"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/youtube-watcher",
          "awslogs-region": "REGION",
          "awslogs-stream-prefix": "ecs"
        }
      }
    }
  ]
}
```

```bash
# 태스크 정의 등록
aws ecs register-task-definition --cli-input-json file://task-definition.json
```

### 3. ECR 저장소 생성 및 이미지 푸시
```bash
# ECR 저장소 생성
aws ecr create-repository --repository-name youtube-watcher

# Docker 이미지 빌드 및 푸시
docker build -t youtube-watcher .
aws ecr get-login-password --region REGION | docker login --username AWS --password-stdin ACCOUNT_ID.dkr.ecr.REGION.amazonaws.com
docker tag youtube-watcher:latest ACCOUNT_ID.dkr.ecr.REGION.amazonaws.com/youtube-watcher:latest
docker push ACCOUNT_ID.dkr.ecr.REGION.amazonaws.com/youtube-watcher:latest
```

## EventBridge 설정

### 1. 규칙 생성
```json
// eventbridge-rule.json
{
  "Name": "youtube-watcher-schedule",
  "ScheduleExpression": "rate(1 minute)",
  "State": "ENABLED",
  "Description": "YouTube watcher schedule rule",
  "Targets": [
    {
      "Id": "youtube-watcher-target",
      "Arn": "arn:aws:ecs:REGION:ACCOUNT_ID:cluster/youtube-watcher",
      "RoleArn": "arn:aws:iam::ACCOUNT_ID:role/EventBridgeInvokeECSRole",
      "EcsParameters": {
        "TaskDefinitionArn": "arn:aws:ecs:REGION:ACCOUNT_ID:task-definition/youtube-watcher:1",
        "TaskCount": 1,
        "LaunchType": "FARGATE",
        "NetworkConfiguration": {
          "awsvpcConfiguration": {
            "Subnets": ["subnet-xxxxxxxx"],
            "SecurityGroups": ["sg-xxxxxxxx"],
            "AssignPublicIp": "ENABLED"
          }
        }
      }
    }
  ]
}
```

```bash
# EventBridge 규칙 생성
aws events put-rule --cli-input-json file://eventbridge-rule.json
```

## Lambda 설정

### 1. Lambda 함수 생성
```typescript
// src/lambda/comment-generator.ts
import { YouTubeAPIService } from '../services/YouTubeAPIService';
import { OpenAI } from 'openai';

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY
});

export const handler = async (event: any) => {
  try {
    const { videoId, accountId } = event;
    const apiService = new YouTubeAPIService();
    
    // YouTube API 인증 설정
    await apiService.setAuth(accountId);
    
    // 동영상 설명 가져오기
    const description = await apiService.getVideoDescription();
    
    // OpenAI로 댓글 생성
    const completion = await openai.chat.completions.create({
      messages: [
        {
          role: "system",
          content: "You are a helpful assistant that generates engaging YouTube comments."
        },
        {
          role: "user",
          content: `Generate a thoughtful comment for this video description: ${description}`
        }
      ],
      model: "gpt-3.5-turbo"
    });
    
    const comment = completion.choices[0].message.content;
    
    // 댓글 게시
    await apiService.postComment(videoId, comment);
    
    // 좋아요 처리
    await apiService.likeVideo(videoId);
    
    return {
      statusCode: 200,
      body: JSON.stringify({ message: 'Comment posted successfully' })
    };
  } catch (error) {
    console.error('Error:', error);
    throw error;
  }
};
```

### 2. Lambda 배포 패키지 생성
```bash
# 의존성 설치
npm install

# 배포 패키지 생성
zip -r function.zip . -x "*.git*" "node_modules/aws-sdk/*"

# Lambda 함수 업로드
aws lambda create-function \
  --function-name youtube-comment-generator \
  --runtime nodejs18.x \
  --handler src/lambda/comment-generator.handler \
  --zip-file fileb://function.zip \
  --role arn:aws:iam::ACCOUNT_ID:role/lambda-youtube-role \
  --environment Variables={OPENAI_API_KEY=YOUR_OPENAI_API_KEY}
```

## SQS 설정

### 1. 큐 생성
```bash
# 표준 큐 생성
aws sqs create-queue --queue-name youtube-watch-complete

# 큐 URL 확인
aws sqs get-queue-url --queue-name youtube-watch-complete
```

### 2. Lambda 트리거 설정
```bash
# Lambda 함수에 SQS 트리거 추가
aws lambda create-event-source-mapping \
  --function-name youtube-comment-generator \
  --event-source-arn arn:aws:sqs:REGION:ACCOUNT_ID:youtube-watch-complete
```

## IAM 설정

### 1. ECS 태스크 실행 역할
```json
// ecs-task-execution-role.json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "*"
    }
  ]
}
```

### 2. ECS 태스크 역할
```json
// ecs-task-role.json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "sqs:SendMessage",
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage"
      ],
      "Resource": "arn:aws:sqs:REGION:ACCOUNT_ID:youtube-watch-complete"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ssm:GetParameter",
        "ssm:GetParameters"
      ],
      "Resource": [
        "arn:aws:ssm:REGION:ACCOUNT_ID:parameter/youtube/*"
      ]
    }
  ]
}
```

### 3. Lambda 실행 역할
```json
// lambda-execution-role.json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes"
      ],
      "Resource": "arn:aws:sqs:REGION:ACCOUNT_ID:youtube-watch-complete"
    },
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:REGION:ACCOUNT_ID:log-group:/aws/lambda/youtube-comment-generator:*"
    }
  ]
}
```

## CloudWatch 설정

### 1. 로그 그룹 생성
```bash
# ECS 로그 그룹
aws logs create-log-group --log-group-name /ecs/youtube-watcher

# Lambda 로그 그룹
aws logs create-log-group --log-group-name /aws/lambda/youtube-comment-generator
```

### 2. 알림 설정
```json
// cloudwatch-alarm.json
{
  "AlarmName": "youtube-watcher-error-alarm",
  "AlarmDescription": "Alarm when YouTube watcher encounters errors",
  "MetricName": "Errors",
  "Namespace": "AWS/ECS",
  "Statistic": "Sum",
  "Period": 300,
  "EvaluationPeriods": 1,
  "Threshold": 1,
  "ComparisonOperator": "GreaterThanThreshold",
  "AlarmActions": [
    "arn:aws:sns:REGION:ACCOUNT_ID:youtube-watcher-alerts"
  ]
}
```

```bash
# CloudWatch 알람 생성
aws cloudwatch put-metric-alarm --cli-input-json file://cloudwatch-alarm.json
```

## 다음 단계
- [보안 및 모니터링 가이드](../docs/05-security-guide.md)로 이동 