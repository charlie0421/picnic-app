'use client';

/**
 * 클라이언트 컴포넌트 인덱스
 * 
 * 이 파일은 클라이언트 컴포넌트를 다른 파일에서 쉽게 임포트할 수 있도록 합니다.
 * 새로운 클라이언트 컴포넌트가 추가될 때마다 이 파일에도 추가해야 합니다.
 */

// 클라이언트 컴포넌트 내보내기
// 예: export { default as DataGrid } from './DataGrid'; 
export { default as LoadingSpinner } from './LoadingSpinner';
export { default as VoteListClient } from './VoteListClient';
export { default as VoteItems } from './VoteItems';
export { default as RetryButton } from './RetryButton';
export { default as VoteClientComponent } from './VoteClientComponent';
// 공유 컴포넌트에서 클라이언트 컴포넌트 가져오기
export { default as VoteDetailClient } from '../shared/VoteDetail/VoteDetailClient';
