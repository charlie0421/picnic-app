'use client';

import { useState } from 'react';

export default function CreatePage() {
  const [formData, setFormData] = useState({});

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target;
    setFormData((prev) => ({ ...prev, [name]: value }));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    // TODO: API 요청 처리
    console.log('제출 데이터:', formData);
  };

  return (
    <form onSubmit={handleSubmit}>
      <input name="title" placeholder="제목" onChange={handleChange} />
      <input name="description" placeholder="설명" onChange={handleChange} />
      <button type="submit">저장</button>
    </form>
  );
}
