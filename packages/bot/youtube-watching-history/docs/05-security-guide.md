# 5. 보안 및 모니터링 가이드

## 목차
1. [보안 설정](#보안-설정)
2. [모니터링 설정](#모니터링-설정)
3. [알림 설정](#알림-설정)
4. [백업 및 복구](#백업-및-복구)
5. [정책 준수](#정책-준수)

## 보안 설정

### 1. AWS Secrets Manager 설정
```bash
# YouTube API 자격 증명 저장
aws secretsmanager create-secret \
  --name youtube/client-credentials \
  --secret-string '{"client_id":"YOUR_CLIENT_ID","client_secret":"YOUR_CLIENT_SECRET"}'

# OpenAI API 키 저장
aws secretsmanager create-secret \
  --name openai/api-key \
  --secret-string '{"api_key":"YOUR_OPENAI_API_KEY"}'
```

### 2. IAM 정책 업데이트
```json
// secrets-manager-policy.json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue"
      ],
      "Resource": [
        "arn:aws:secretsmanager:REGION:ACCOUNT_ID:secret:youtube/client-credentials-*",
        "arn:aws:secretsmanager:REGION:ACCOUNT_ID:secret:openai/api-key-*"
      ]
    }
  ]
}
```

### 3. VPC 보안 그룹 설정
```json
// security-group.json
{
  "GroupName": "youtube-watcher-sg",
  "Description": "Security group for YouTube watcher tasks",
  "VpcId": "vpc-xxxxxxxx",
  "IpPermissions": [
    {
      "IpProtocol": "tcp",
      "FromPort": 443,
      "ToPort": 443,
      "IpRanges": [
        {
          "CidrIp": "0.0.0.0/0",
          "Description": "HTTPS access"
        }
      ]
    }
  ]
}
```

## 모니터링 설정

### 1. CloudWatch 대시보드 생성
```json
// cloudwatch-dashboard.json
{
  "DashboardName": "youtube-watcher-dashboard",
  "DashboardBody": {
    "widgets": [
      {
        "type": "metric",
        "properties": {
          "metrics": [
            ["AWS/ECS", "CPUUtilization", "ClusterName", "youtube-watcher"],
            ["AWS/ECS", "MemoryUtilization", "ClusterName", "youtube-watcher"]
          ],
          "view": "timeSeries",
          "stacked": false,
          "region": "REGION",
          "title": "ECS Cluster Metrics"
        }
      },
      {
        "type": "metric",
        "properties": {
          "metrics": [
            ["AWS/Lambda", "Invocations", "FunctionName", "youtube-comment-generator"],
            ["AWS/Lambda", "Errors", "FunctionName", "youtube-comment-generator"]
          ],
          "view": "timeSeries",
          "stacked": false,
          "region": "REGION",
          "title": "Lambda Metrics"
        }
      }
    ]
  }
}
```

### 2. CloudWatch 로그 필터 설정
```json
// log-filter.json
{
  "logGroupName": "/ecs/youtube-watcher",
  "filterName": "error-filter",
  "filterPattern": "ERROR",
  "metricTransformations": [
    {
      "metricName": "YouTubeWatcherErrors",
      "metricNamespace": "YouTubeWatcher",
      "metricValue": "1"
    }
  ]
}
```

## 알림 설정

### 1. SNS 토픽 생성
```bash
# SNS 토픽 생성
aws sns create-topic --name youtube-watcher-alerts

# 이메일 구독 추가
aws sns subscribe \
  --topic-arn arn:aws:sns:REGION:ACCOUNT_ID:youtube-watcher-alerts \
  --protocol email \
  --notification-endpoint your-email@example.com
```

### 2. CloudWatch 알람 설정
```json
// error-alarm.json
{
  "AlarmName": "youtube-watcher-error-alarm",
  "AlarmDescription": "Alarm when YouTube watcher encounters errors",
  "MetricName": "YouTubeWatcherErrors",
  "Namespace": "YouTubeWatcher",
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

## 백업 및 복구

### 1. RDS 스냅샷 설정
```bash
# 매일 자동 스냅샷 생성
aws rds create-db-cluster-snapshot \
  --db-cluster-identifier youtube-watcher-db \
  --db-cluster-snapshot-identifier youtube-watcher-snapshot-$(date +%Y%m%d)
```

### 2. 복구 절차
```bash
# 최신 스냅샷 확인
aws rds describe-db-cluster-snapshots \
  --db-cluster-identifier youtube-watcher-db

# 스냅샷에서 복원
aws rds restore-db-cluster-from-snapshot \
  --db-cluster-identifier youtube-watcher-db-restored \
  --snapshot-identifier youtube-watcher-snapshot-YYYYMMDD \
  --engine aurora-postgresql
```

## 정책 준수

### 1. YouTube API 사용 정책
```typescript
// src/utils/rateLimiter.ts
export class RateLimiter {
  private static requests: { [key: string]: number[] } = {};

  static async checkLimit(accountId: string): Promise<boolean> {
    const now = Date.now();
    const window = 24 * 60 * 60 * 1000; // 24시간
    const maxRequests = 10000; // YouTube API 일일 할당량

    if (!this.requests[accountId]) {
      this.requests[accountId] = [];
    }

    // 24시간 이전의 요청 제거
    this.requests[accountId] = this.requests[accountId].filter(
      time => now - time < window
    );

    // 현재 요청 수 확인
    if (this.requests[accountId].length >= maxRequests) {
      return false;
    }

    this.requests[accountId].push(now);
    return true;
  }
}
```

### 2. 자동화 정책 준수
```typescript
// src/utils/policyCompliance.ts
export class PolicyCompliance {
  static async checkAutomationPolicy(videoId: string): Promise<boolean> {
    // YouTube 자동화 정책 확인
    const isCompliant = await this.verifyCompliance(videoId);
    
    if (!isCompliant) {
      console.warn('자동화 정책 위반 가능성 발견');
      return false;
    }
    
    return true;
  }

  private static async verifyCompliance(videoId: string): Promise<boolean> {
    // 정책 준수 여부 확인 로직
    // 예: 시청 시간, 상호작용 빈도 등 확인
    return true;
  }
}
```

### 3. 로깅 및 감사
```typescript
// src/utils/auditLogger.ts
export class AuditLogger {
  static async logAction(
    accountId: string,
    action: string,
    details: any
  ): Promise<void> {
    const logEntry = {
      timestamp: new Date(),
      accountId,
      action,
      details,
      ipAddress: await this.getIPAddress()
    };

    // CloudWatch Logs에 기록
    await this.writeToCloudWatch(logEntry);
  }

  private static async getIPAddress(): Promise<string> {
    // IP 주소 확인 로직
    return 'unknown';
  }

  private static async writeToCloudWatch(logEntry: any): Promise<void> {
    // CloudWatch Logs에 기록
  }
}
```

## 다음 단계
- 모든 설정이 완료되었습니다. 시스템을 시작하기 전에 [설치 및 환경 설정 가이드](../docs/01-installation-guide.md)를 다시 확인하세요. 