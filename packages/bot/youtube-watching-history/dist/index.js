"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
const YouTubeBot_1 = require("./services/YouTubeBot");
require("dotenv/config");
const fs = __importStar(require("fs"));
const path = __importStar(require("path"));
async function main() {
    const bot = new YouTubeBot_1.YouTubeBot();
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
            const randomKeyword = keywords[Math.floor(Math.random() * keywords.length)];
            console.log(`\n새로운 검색 시작... ${randomKeyword}`);
            await bot.searchAndAnalyze(randomKeyword);
            // 다음 검색 전에 잠시 대기
            console.log("다음 검색을 위해 3초 대기...");
            await new Promise((resolve) => setTimeout(resolve, 3000));
        }
    }
    catch (error) {
        console.error("Error:", error);
    }
    finally {
        await bot.close();
    }
}
main();
