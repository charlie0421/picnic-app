'use client';

import { useEffect, useState } from 'react';
import { useParams } from 'next/navigation';

export default function DetailPage() {
  const { id } = useParams();
  const [data, setData] = useState<any>(null);

  useEffect(() => {
    // TODO: API 요청 처리
    const fetchData = async () => {
      console.log('요청 ID:', id);
      setData({ title: '임시 제목', description: '임시 설명' });
    };
    fetchData();
  }, [id]);

  if (!data) return <div>로딩 중...</div>;

  return (
    <div>
      <h1>{data.title}</h1>
      <p>{data.description}</p>
    </div>
  );
}
