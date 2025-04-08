'use client';

import { useEffect, useState } from 'react';
import { useParams } from 'next/navigation';

export default function EditPage() {
  const { id } = useParams();
  const [formData, setFormData] = useState<any>({});

  useEffect(() => {
    // TODO: API 요청 처리
    setFormData({ title: '기존 제목', description: '기존 설명' });
  }, [id]);

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target;
    setFormData((prev) => ({ ...prev, [name]: value }));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    // TODO: 수정 요청 처리
    console.log('수정 데이터:', formData);
  };

  return (
    <form onSubmit={handleSubmit}>
      <input name="title" value={formData.title} onChange={handleChange} />
      <input name="description" value={formData.description} onChange={handleChange} />
      <button type="submit">수정</button>
    </form>
  );
}
