import React from 'react';
import Head from 'next/head';
export default function Home() {
  return (
    <div>
      <Head>
        <title>TTJA 웹</title>
        <meta name='description' content='TTJA 웹 애플리케이션' />
        <link rel='icon' href='/favicon.ico' />
      </Head>
      <main>
        <h1>TTJA 웹 애플리케이션</h1>
        <p>이 페이지는 독립적으로 실행될 때 보이는 페이지입니다.</p>
      </main>
    </div>
  );
}
