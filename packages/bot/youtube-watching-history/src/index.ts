import { YouTubeBot } from "./services/YouTubeBot";
import "dotenv/config";
import * as fs from "fs";
import * as path from "path";

async function main() {
  const bot = new YouTubeBot();

  try {
    console.log("YouTubeBot 초기화 시작");
    await bot.init();
    console.log("YouTubeBot 초기화 완료");
    console.log("로그인 시작");
    await bot.login();
    console.log("로그인 완료");

    // keywords.json 파일에서 키워드 배열 읽기
    const keywordsPath = path.join(__dirname, "keywords.json");
    const keywords = JSON.parse(fs.readFileSync(keywordsPath, "utf-8"));

    while (true) {
      const randomKeyword =
        keywords[Math.floor(Math.random() * keywords.length)];
      console.log(`\n새로운 검색 시작... ${randomKeyword}`);
      await bot.searchAndAnalyze(randomKeyword);

      // 다음 검색 전에 잠시 대기
      console.log("다음 검색을 위해 3초 대기...");
      await new Promise((resolve) => setTimeout(resolve, 3000));
    }
  } catch (error) {
    console.error("Error:", error);
  } finally {
    await bot.close();
  }
}

main();