'use client';

import { useState } from 'react';
import { createBrowserSupabaseClient } from '@/utils/supabase';

export default function Contact() {
  const [supabase] = useState(() => createBrowserSupabaseClient());
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    message: ''
  });
  const [status, setStatus] = useState<'idle' | 'loading' | 'success' | 'error'>('idle');
  const [errorMessage, setErrorMessage] = useState('');

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: value
    }));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setStatus('loading');
    setErrorMessage('');

    try {
      // Supabase를 사용하여 문의 데이터 저장
      const { error } = await supabase
        .from('qnas')
        .insert([
          {
            question: formData.message,
            title: formData.name,
            created_by: formData.email,
            created_at: new Date().toISOString()
          }
        ]);

      if (error) throw error;

      // 성공 시 폼 초기화 및 상태 업데이트
      setFormData({ name: '', email: '', message: '' });
      setStatus('success');
    } catch (error) {
      console.error('문의 제출 오류:', error);
      setStatus('error');
      setErrorMessage('문의 제출 중 오류가 발생했습니다. 나중에 다시 시도해주세요.');
    }
  };

  return (
    <div className="container mx-auto px-4 py-8">
      <h1 className="text-3xl font-bold mb-6">문의하기</h1>

      <div className="bg-white rounded-lg shadow-md p-6 mb-8">
        <p className="text-gray-700 mb-6">
          궁금하신 점이나 문의사항이 있으시면 아래 양식을 통해 연락해 주세요.
          빠른 시일 내에 답변 드리겠습니다.
        </p>

        {status === 'success' && (
          <div className="mb-6 p-4 bg-green-100 text-green-700 rounded-md">
            문의가 성공적으로 전송되었습니다. 곧 연락드리겠습니다.
          </div>
        )}

        {status === 'error' && (
          <div className="mb-6 p-4 bg-red-100 text-red-700 rounded-md">
            {errorMessage}
          </div>
        )}

        <form onSubmit={handleSubmit}>
          <div className="mb-4">
            <label htmlFor="name" className="block text-gray-700 font-medium mb-2">
              이름
            </label>
            <input
              type="text"
              id="name"
              name="name"
              value={formData.name}
              onChange={handleChange}
              className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              required
            />
          </div>

          <div className="mb-4">
            <label htmlFor="email" className="block text-gray-700 font-medium mb-2">
              이메일
            </label>
            <input
              type="email"
              id="email"
              name="email"
              value={formData.email}
              onChange={handleChange}
              className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              required
            />
          </div>

          <div className="mb-6">
            <label htmlFor="message" className="block text-gray-700 font-medium mb-2">
              메시지
            </label>
            <textarea
              id="message"
              name="message"
              value={formData.message}
              onChange={handleChange}
              rows={5}
              className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
              required
            ></textarea>
          </div>

          <button
            type="submit"
            disabled={status === 'loading'}
            className={`px-6 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 ${
              status === 'loading' ? 'opacity-70 cursor-not-allowed' : ''
            }`}
          >
            {status === 'loading' ? '제출 중...' : '문의 제출'}
          </button>
        </form>
      </div>

      <div className="bg-white rounded-lg shadow-md p-6">
        <h2 className="text-2xl font-semibold mb-4">연락처 정보</h2>
        <div className="space-y-3">
          <p className="flex items-center text-gray-700">
            <span className="font-medium mr-2">주소:</span> 서울시 강남구 테헤란로 123
          </p>
          <p className="flex items-center text-gray-700">
            <span className="font-medium mr-2">이메일:</span> contact@picnic.com
          </p>
          <p className="flex items-center text-gray-700">
            <span className="font-medium mr-2">전화:</span> 02-123-4567
          </p>
        </div>
      </div>
    </div>
  );
} 