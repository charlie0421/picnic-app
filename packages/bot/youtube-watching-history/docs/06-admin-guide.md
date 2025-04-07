# 6. Admin UI 가이드

## 목차
1. [Admin UI 개요](#admin-ui-개요)
2. [기능 구현](#기능-구현)
3. [보안 설정](#보안-설정)
4. [모니터링 및 로깅](#모니터링-및-로깅)
5. [테스트 작성](#테스트-작성)

## Admin UI 개요

### 1. 주요 기능
- 계정 관리 (추가, 수정, 삭제)
- 시청 이력 조회 및 관리
- YouTube API 토큰 관리
- 시스템 상태 모니터링
- 설정 관리

### 2. 기술 스택
- Frontend: React, TypeScript, Material-UI
- Backend: Node.js, Express
- Database: Supabase
- Authentication: JWT

## 기능 구현

### 1. 계정 관리
```typescript
// src/pages/AccountManagement.tsx
import React, { useState, useEffect } from 'react';
import { Table, Button, Dialog, TextField } from '@mui/material';
import { createClient } from '@supabase/supabase-js';

export const AccountManagement: React.FC = () => {
  const [accounts, setAccounts] = useState([]);
  const [openDialog, setOpenDialog] = useState(false);
  const [newAccount, setNewAccount] = useState({ email: '', password: '' });

  useEffect(() => {
    fetchAccounts();
  }, []);

  const fetchAccounts = async () => {
    const { data, error } = await supabase
      .from('accounts')
      .select('*');
    
    if (!error) setAccounts(data);
  };

  const handleAddAccount = async () => {
    const { error } = await supabase
      .from('accounts')
      .insert([newAccount]);
    
    if (!error) {
      setOpenDialog(false);
      fetchAccounts();
    }
  };

  return (
    <div>
      <Button onClick={() => setOpenDialog(true)}>계정 추가</Button>
      <Table>
        {/* 계정 목록 표시 */}
      </Table>
      <Dialog open={openDialog}>
        <TextField
          label="이메일"
          value={newAccount.email}
          onChange={(e) => setNewAccount({ ...newAccount, email: e.target.value })}
        />
        <TextField
          label="비밀번호"
          type="password"
          value={newAccount.password}
          onChange={(e) => setNewAccount({ ...newAccount, password: e.target.value })}
        />
        <Button onClick={handleAddAccount}>저장</Button>
      </Dialog>
    </div>
  );
};
```

### 2. 시청 이력 관리
```typescript
// src/pages/WatchHistory.tsx
import React, { useState, useEffect } from 'react';
import { Table, TableHead, TableBody, TableRow, TableCell } from '@mui/material';

export const WatchHistory: React.FC = () => {
  const [watchHistory, setWatchHistory] = useState([]);

  useEffect(() => {
    fetchWatchHistory();
  }, []);

  const fetchWatchHistory = async () => {
    const { data, error } = await supabase
      .from('watch_logs')
      .select(`
        *,
        accounts (email)
      `)
      .order('watch_date', { ascending: false });
    
    if (!error) setWatchHistory(data);
  };

  return (
    <Table>
      <TableHead>
        <TableRow>
          <TableCell>계정</TableCell>
          <TableCell>동영상 ID</TableCell>
          <TableCell>시청 시간</TableCell>
          <TableCell>시청 날짜</TableCell>
        </TableRow>
      </TableHead>
      <TableBody>
        {watchHistory.map((log) => (
          <TableRow key={log.id}>
            <TableCell>{log.accounts.email}</TableCell>
            <TableCell>{log.video_id}</TableCell>
            <TableCell>{log.watch_duration}초</TableCell>
            <TableCell>{new Date(log.watch_date).toLocaleString()}</TableCell>
          </TableRow>
        ))}
      </TableBody>
    </Table>
  );
};
```

### 3. 시스템 상태 모니터링
```typescript
// src/pages/SystemStatus.tsx
import React, { useState, useEffect } from 'react';
import { Card, CardContent, Typography, Grid } from '@mui/material';

export const SystemStatus: React.FC = () => {
  const [metrics, setMetrics] = useState({
    activeAccounts: 0,
    totalWatchTime: 0,
    apiCalls: 0,
    errors: 0
  });

  useEffect(() => {
    fetchMetrics();
    const interval = setInterval(fetchMetrics, 60000);
    return () => clearInterval(interval);
  }, []);

  const fetchMetrics = async () => {
    // CloudWatch 메트릭 조회
    const metrics = await getCloudWatchMetrics();
    setMetrics(metrics);
  };

  return (
    <Grid container spacing={2}>
      <Grid item xs={3}>
        <Card>
          <CardContent>
            <Typography>활성 계정</Typography>
            <Typography variant="h4">{metrics.activeAccounts}</Typography>
          </CardContent>
        </Card>
      </Grid>
      {/* 다른 메트릭 카드들 */}
    </Grid>
  );
};
```

## 보안 설정

### 1. 인증 미들웨어
```typescript
// src/middleware/auth.ts
import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';

export const authenticate = (req: Request, res: Response, next: NextFunction) => {
  const token = req.headers.authorization?.split(' ')[1];
  
  if (!token) {
    return res.status(401).json({ error: '인증 토큰이 필요합니다.' });
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET!);
    req.user = decoded;
    next();
  } catch (error) {
    return res.status(401).json({ error: '유효하지 않은 토큰입니다.' });
  }
};
```

### 2. API 라우트 보호
```typescript
// src/routes/admin.ts
import express from 'express';
import { authenticate } from '../middleware/auth';

const router = express.Router();

router.use(authenticate);

router.get('/accounts', async (req, res) => {
  // 계정 목록 조회
});

router.post('/accounts', async (req, res) => {
  // 계정 추가
});

export default router;
```

## 모니터링 및 로깅

### 1. 사용자 활동 로깅
```typescript
// src/utils/adminLogger.ts
export class AdminLogger {
  static async logAdminAction(
    userId: string,
    action: string,
    details: any
  ): Promise<void> {
    const logEntry = {
      timestamp: new Date(),
      userId,
      action,
      details,
      ipAddress: await this.getIPAddress()
    };

    await supabase
      .from('admin_logs')
      .insert([logEntry]);
  }

  private static async getIPAddress(): Promise<string> {
    // IP 주소 확인 로직
    return 'unknown';
  }
}
```

### 2. 에러 모니터링
```typescript
// src/utils/errorHandler.ts
export const handleAdminError = (error: any) => {
  console.error('Admin Error:', error);
  
  // CloudWatch에 에러 로깅
  const logEntry = {
    timestamp: new Date(),
    error: error.message,
    stack: error.stack
  };

  // CloudWatch Logs에 기록
  writeToCloudWatch(logEntry);
};
```

## 테스트 작성

### 1. 계정 관리 테스트
```typescript
// tests/unit/AccountManagement.test.tsx
import { render, screen, fireEvent } from '@testing-library/react';
import { AccountManagement } from '../../src/pages/AccountManagement';

describe('AccountManagement', () => {
  it('계정을 추가할 수 있어야 함', async () => {
    render(<AccountManagement />);
    
    fireEvent.click(screen.getByText('계정 추가'));
    
    const emailInput = screen.getByLabelText('이메일');
    const passwordInput = screen.getByLabelText('비밀번호');
    
    fireEvent.change(emailInput, { target: { value: 'test@example.com' } });
    fireEvent.change(passwordInput, { target: { value: 'password123' } });
    
    fireEvent.click(screen.getByText('저장'));
    
    // 계정이 추가되었는지 확인
    expect(await screen.findByText('test@example.com')).toBeInTheDocument();
  });
});
```

### 2. 시청 이력 테스트
```typescript
// tests/unit/WatchHistory.test.tsx
import { render, screen } from '@testing-library/react';
import { WatchHistory } from '../../src/pages/WatchHistory';

describe('WatchHistory', () => {
  it('시청 이력을 표시해야 함', async () => {
    render(<WatchHistory />);
    
    // 시청 이력이 표시되는지 확인
    expect(await screen.findByText('동영상 ID')).toBeInTheDocument();
    expect(await screen.findByText('시청 시간')).toBeInTheDocument();
  });
});
```

## 다음 단계
- 모든 설정이 완료되었습니다. 시스템을 시작하기 전에 [설치 및 환경 설정 가이드](../docs/01-installation-guide.md)를 다시 확인하세요. 