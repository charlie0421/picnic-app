import React, { Suspense } from 'react';
import Link from 'next/link';
import { 
  LoadingState, 
  ParallelDataFetching, 
  NestedDataFetching,
  ServerClientBoundary,
  VoteDataExample 
} from '@/components/server';

/**
 * 서버 컴포넌트 데이터 페칭 데모 페이지
 * 
 * 이 페이지는 다양한 서버 컴포넌트 데이터 페칭 패턴을 보여줍니다.
 */
export default function ServerComponentsDemo() {
  return (
    <div className="container mx-auto px-4 py-8">
      <h1 className="text-3xl font-bold mb-8">서버 컴포넌트 데이터 페칭 패턴</h1>
      
      <div className="grid grid-cols-1 md:grid-cols-2 gap-8 mb-12">
        <DemoCard 
          title="병렬 데이터 페칭"
          description="여러 독립적인 데이터를 동시에 로드하는 패턴입니다. 각 데이터는 독립된 Suspense 경계를 가집니다."
          link="/streaming-example"
          component={
            <div className="mt-4 p-4 bg-gray-100 rounded-lg">
              <Suspense fallback={<LoadingState message="병렬 데이터 로딩 중..." size="small" />}>
                <ParallelDataFetching />
              </Suspense>
            </div>
          }
        />
        
        <DemoCard 
          title="중첩된 Suspense와 계층적 데이터 로딩"
          description="중요한 데이터부터 순차적으로 로드하는 패턴입니다. 우선순위가 높은 데이터가 먼저 표시됩니다."
          link="/streaming-example"
          component={
            <div className="mt-4 p-4 bg-gray-100 rounded-lg">
              <Suspense fallback={<LoadingState message="중첩 데이터 로딩 중..." size="small" />}>
                <NestedDataFetching voteId="1" />
              </Suspense>
            </div>
          }
        />
      </div>
      
      <div className="grid grid-cols-1 md:grid-cols-2 gap-8 mb-12">
        <DemoCard 
          title="서버-클라이언트 경계 패턴"
          description="서버에서 데이터를 가져와 클라이언트 컴포넌트로 전달하는 패턴입니다."
          link="/streaming-example"
          component={
            <div className="mt-4 p-4 bg-gray-100 rounded-lg">
              <Suspense fallback={<LoadingState message="서버-클라이언트 데이터 로딩 중..." size="small" />}>
                <ServerClientBoundary />
              </Suspense>
            </div>
          }
        />
        
        <DemoCard 
          title="서버 컴포넌트 오류 처리"
          description="서버 컴포넌트에서 오류가 발생했을 때 처리하는 패턴입니다."
          link="/vote/999" // 존재하지 않는 ID로 notFound 테스트
          component={
            <div className="mt-4 p-4 bg-gray-100 rounded-lg">
              <Suspense fallback={<LoadingState message="투표 데이터 로딩 중..." size="small" />}>
                <VoteDataExample id="1" />
              </Suspense>
            </div>
          }
        />
      </div>
      
      <div className="bg-white shadow-md rounded-lg p-6 mb-8">
        <h2 className="text-xl font-bold mb-4">다음 단계</h2>
        <p className="mb-4">
          서버 컴포넌트를 실제 프로젝트에 적용하려면 다음 단계로 넘어가세요:
        </p>
        <ul className="list-disc pl-5 space-y-2">
          <li>기존 클라이언트 컴포넌트를 서버 컴포넌트로 리팩토링</li>
          <li>서버 컴포넌트와 클라이언트 컴포넌트 간의 적절한 경계 설정</li>
          <li>데이터 페칭 로직 최적화</li>
          <li>Suspense 경계 최적화</li>
        </ul>
        <div className="mt-6">
          <Link 
            href="/streaming-example" 
            className="px-4 py-2 bg-primary text-white rounded hover:bg-primary/80 transition-colors"
          >
            스트리밍 데이터 예제 보기
          </Link>
        </div>
      </div>
    </div>
  );
}

/**
 * 데모 카드 컴포넌트
 */
function DemoCard({ 
  title, 
  description, 
  link, 
  component 
}: { 
  title: string; 
  description: string; 
  link: string;
  component: React.ReactNode;
}) {
  return (
    <div className="bg-white shadow-md rounded-lg p-6">
      <h2 className="text-xl font-bold">{title}</h2>
      <p className="mt-2 text-gray-600">{description}</p>
      {component}
      <div className="mt-4 text-right">
        <Link 
          href={link} 
          className="text-primary hover:underline"
        >
          자세히 보기 →
        </Link>
      </div>
    </div>
  );
} 