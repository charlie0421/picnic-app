import dynamic from 'next/dynamic';
import type { GetStaticProps, NextPage } from 'next';

const HomePageClient = dynamic(
  () => import('../src/components/HomePageClient'),
  { ssr: false },
);

const HomePage: NextPage = () => {
  return <HomePageClient />;
};

export const getStaticProps: GetStaticProps = async () => {
  return {
    props: {},
  };
};

export default HomePage;
