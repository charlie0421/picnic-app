import OpenAI from 'openai';

export class OpenAIService {
  private openai: OpenAI;

  constructor() {
    if (!process.env.OPENAI_API_KEY) {
      throw new Error('OPENAI_API_KEY 환경 변수가 설정되지 않았습니다.');
    }
    this.openai = new OpenAI({
      apiKey: process.env.OPENAI_API_KEY,
    });
  }

  async generateComment(videoDescription: string): Promise<string> {
    try {
      const completion = await this.openai.chat.completions.create({
        messages: [
          {
            role: "system",
            content: "당신은 유튜브 댓글을 작성하는 전문가입니다. 주어진 동영상 설명을 바탕으로 자연스럽고 긍정적인 댓글을 작성해주세요."
          },
          {
            role: "user",
            content: `다음 동영상 설명을 바탕으로 자연스럽고 긍정적인 댓글을 작성해주세요:\n\n${videoDescription}`
          }
        ],
        model: "gpt-3.5-turbo",
        temperature: 0.7,
        max_tokens: 100,
      });

      return completion.choices[0]?.message?.content || "좋은 영상이네요!";
    } catch (error) {
      console.error('OpenAI API 호출 중 오류 발생:', error);
      return "좋은 영상이네요!";
    }
  }
} 