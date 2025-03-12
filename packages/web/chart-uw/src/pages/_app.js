import { Noto_Sans_KR } from 'next/font/google';

const notoSansKR = Noto_Sans_KR({
  subsets: ['latin'],
  weight: ['400', '700', '900'], // 필요한 폰트 두께 추가
});

function MyApp({ Component, pageProps }) {
  return (
    <main className={`${notoSansKR.className}`}>
      <Component {...pageProps} />
    </main>
  );
}

export default MyApp;
