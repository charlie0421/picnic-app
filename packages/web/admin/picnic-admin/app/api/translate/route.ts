import { NextResponse } from 'next/server';
import axios from 'axios';

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const { text, targetLang, sourceLang } = body;

    if (!text || !targetLang) {
      return NextResponse.json(
        { error: '텍스트와 대상 언어는 필수 항목입니다.' },
        { status: 400 },
      );
    }

    // DeepL API 키
    const apiKey = process.env.DEEPL_API_KEY;

    if (!apiKey) {
      return NextResponse.json(
        { error: 'DeepL API 키가 설정되지 않았습니다.' },
        { status: 500 },
      );
    }

    // DeepL API 호출
    const response = await axios.post(
      'https://api-free.deepl.com/v2/translate',
      {
        text: [text],
        target_lang: targetLang,
        ...(sourceLang && { source_lang: sourceLang }),
      },
      {
        headers: {
          Authorization: `DeepL-Auth-Key ${apiKey}`,
          'Content-Type': 'application/json',
        },
      },
    );

    // 번역 결과 반환
    if (
      response.data &&
      response.data.translations &&
      response.data.translations.length > 0
    ) {
      return NextResponse.json({
        text: response.data.translations[0].text,
        detectedSourceLanguage:
          response.data.translations[0].detected_source_language,
      });
    }

    return NextResponse.json(
      { error: '번역 결과가 올바르지 않습니다.' },
      { status: 500 },
    );
  } catch (error: any) {
    console.error('번역 API 오류:', error.message);
    return NextResponse.json(
      { error: `번역 중 오류가 발생했습니다: ${error.message}` },
      { status: 500 },
    );
  }
}
