import '@testing-library/jest-dom';
import { render, screen } from '@testing-library/react';
import {
  createMockRouter,
  createMockSearchParams,
  createMockParams,
  mockFetch,
  createMockNextApiResponse
} from './nextjs-mocks';

describe('Next.js 모킹 유틸리티', () => {
  describe('createMockRouter', () => {
    it('기본 라우터를 생성합니다', () => {
      const router = createMockRouter();
      
      expect(router.push).toBeDefined();
      expect(router.replace).toBeDefined();
      expect(router.back).toBeDefined();
      expect(router.forward).toBeDefined();
      expect(router.refresh).toBeDefined();
      expect(router.prefetch).toBeDefined();
    });
    
    it('커스텀 라우터 메소드를 오버라이드합니다', () => {
      const mockPush = jest.fn();
      const router = createMockRouter({
        push: mockPush
      });
      
      router.push('/test');
      expect(mockPush).toHaveBeenCalledWith('/test');
    });
  });
  
  describe('createMockSearchParams', () => {
    it('빈 검색 파라미터를 생성합니다', () => {
      const params = createMockSearchParams();
      
      expect(params.get('test')).toBeNull();
      expect(params.toString()).toBe('');
    });
    
    it('지정된 검색 파라미터를 생성합니다', () => {
      const params = createMockSearchParams({
        name: 'test',
        value: '123'
      });
      
      expect(params.get('name')).toBe('test');
      expect(params.get('value')).toBe('123');
      expect(params.has('name')).toBe(true);
      expect(params.has('invalid')).toBe(false);
      expect(params.toString()).toBe('name=test&value=123');
    });
    
    it('forEach 메소드를 테스트합니다', () => {
      const params = createMockSearchParams({
        name: 'test',
        value: '123'
      });
      
      const result: Record<string, string> = {};
      params.forEach((value, key) => {
        result[key] = value;
      });
      
      expect(result).toEqual({
        name: 'test',
        value: '123'
      });
    });
  });
  
  describe('createMockParams', () => {
    it('라우트 파라미터를 생성합니다', () => {
      const params = createMockParams({
        id: '123',
        slug: ['category', 'product']
      });
      
      expect(params.id).toBe('123');
      expect(params.slug).toEqual(['category', 'product']);
    });
  });
  
  describe('mockFetch', () => {
    it('성공 응답을 모킹합니다', async () => {
      const mockData = { success: true, data: [1, 2, 3] };
      mockFetch(mockData);
      
      const response = await fetch('/api/test');
      const data = await response.json();
      
      expect(response.ok).toBe(true);
      expect(response.status).toBe(200);
      expect(data).toEqual(mockData);
    });
    
    it('오류 응답을 모킹합니다', async () => {
      const mockData = { error: 'Not found' };
      mockFetch(mockData, { ok: false, status: 404 });
      
      const response = await fetch('/api/test');
      const data = await response.json();
      
      expect(response.ok).toBe(false);
      expect(response.status).toBe(404);
      expect(data).toEqual(mockData);
    });
  });
  
  describe('createMockNextApiResponse', () => {
    it('API 응답 객체를 생성합니다', () => {
      const res = createMockNextApiResponse();
      
      res.status(404);
      res.json({ error: 'Not found' });
      
      const result = res._getResult();
      expect(result.statusCode).toBe(404);
      expect(result.body).toEqual({ error: 'Not found' });
    });
    
    it('헤더를 설정합니다', () => {
      const res = createMockNextApiResponse();
      
      res.setHeader('Content-Type', 'application/json');
      
      const result = res._getResult();
      expect(result.headers.get('Content-Type')).toBe('application/json');
    });
    
    it('쿠키를 설정합니다', () => {
      const res = createMockNextApiResponse();
      
      res.setCookie('token', '123456');
      
      const result = res._getResult();
      expect(result.cookies.get('token')).toBe('123456');
    });
  });
}); 