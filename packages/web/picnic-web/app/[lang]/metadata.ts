import type {Metadata} from "next";

const defaultMetadata: Metadata = {
  title: "Picnic - 아티스트와 팬이 함께하는 피크닠!",
  description:
    "순위 투표와 차트, 아티스트와 함께 촬영하는 포토프레임 서비스까지 내 최애 아티스트와 함께 피크닉하는 공간, 피크닠입니다.",
  keywords: [
    "picnic",
    "피크닉",
    "피크닠",
    "아티스트",
    "K-pop",
    "투표",
    "차트",
    "포토프레임",
  ],
  authors: [{ name: "Picnic Team" }],
  creator: "Picnic",
  publisher: "Picnic",
  formatDetection: {
    email: false,
    telephone: false,
    address: false,
  },
  icons: {
    icon: [
      { url: "/favicon/favicon.ico" },
      { url: "/favicon/favicon-16x16.png", sizes: "16x16", type: "image/png" },
      { url: "/favicon/favicon-32x32.png", sizes: "32x32", type: "image/png" },
    ],
    apple: [
      {
        url: "/favicon/apple-touch-icon.png",
        sizes: "180x180",
        type: "image/png",
      },
    ],
    other: [
      {
        rel: "mask-icon",
        url: "/favicon/safari-pinned-tab.svg",
        color: "#4F46E5",
      },
    ],
  },
  openGraph: {
    title: "Picnic - 아티스트와 팬이 함께하는 피크닠!",
    description:
      "순위 투표와 차트, 아티스트와 함께 촬영하는 포토프레임 서비스까지 내 최애 아티스트와 함께 피크닉하는 공간, 피크닠입니다.",
    url: "https://picnic.social",
    siteName: "Picnic",
    locale: "ko_KR",
    type: "website",
    images: [
      {
        url: "/images/og-image.jpg",
        width: 1200,
        height: 630,
        alt: "Picnic 로고 이미지",
      },
    ],
  },
  twitter: {
    card: "summary_large_image",
    title: "Picnic - 아티스트와 팬이 함께하는 피크닠!",
    description:
      "순위 투표와 차트, 아티스트와 함께 촬영하는 포토프레임 서비스까지 내 최애 아티스트와 함께 피크닉하는 공간, 피크닠입니다.",
    images: ["/images/twitter-image.jpg"],
  },
  robots: {
    index: true,
    follow: true,
  },
  viewport: {
    width: "device-width",
    initialScale: 1,
    maximumScale: 1,
  },
  manifest: "/manifest.json",
};

export const metadata: Metadata = defaultMetadata;
