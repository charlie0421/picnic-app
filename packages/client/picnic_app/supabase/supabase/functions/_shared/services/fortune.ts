import { getSupabaseClient } from '../database.ts';
import { generateCompletion } from '../ai/completion.ts';
import { translateBatch } from '../ai/deepl.ts';
import { PromptService } from './prompt.ts';
import type { Artist, FortuneTelling } from '../types/fortune.ts';
import { SupportedLanguage } from '../types/openai.ts';

export class FortuneService {
    private supabase;
    private promptService;

    constructor() {
        this.supabase = getSupabaseClient();
        this.promptService = PromptService.getInstance();
    }

    async getOrGenerateFortune(
        artistId: number,
        year: number,
    ): Promise<FortuneTelling> {
        const startTime = Date.now();

        try {
            // 기존 운세 확인
            const { data: existingFortune, error: fetchError } = await this.supabase
                .from('fortune_telling')
                .select('*')
                .eq('artist_id', artistId)
                .eq('year', year)
                .single();

            if (fetchError && fetchError.code !== 'PGRST116') {
                throw fetchError;
            }

            let fortune: FortuneTelling;

            if (existingFortune) {
                fortune = existingFortune;
                // i18n 테이블의 누락된 번역 데이터 확인 및 생성
                await this.checkAndGenerateTranslations(fortune);
            } else {
                console.log('Generating new fortune...');

                // 아티스트 정보 조회
                const { data: artist, error: artistError } = await this.supabase
                    .from('artist')
                    .select('name, yy, mm, dd, gender')
                    .eq('id', artistId)
                    .maybeSingle();

                if (artistError || !artist) {
                    throw new Error('Artist not found');
                }

                // 새로운 운세 생성
                fortune = await this.generateNewFortune(
                    artistId,
                    artist.name['ko'],
                    artist.yy,
                    artist.mm,
                    artist.dd,
                    artist.gender,
                    year,
                );

                // 운세 저장
                const { data: savedFortune, error: saveError } = await this.supabase
                    .from('fortune_telling')
                    .insert(fortune)
                    .select()
                    .single();

                if (saveError) {
                    throw saveError;
                }

                fortune = savedFortune;

                // 새로운 운세의 번역 데이터 생성
                await this.checkAndGenerateTranslations(fortune);
            }

            const executionTime = Date.now() - startTime;
            console.log(`Fortune process completed in ${executionTime}ms`);

            return fortune;
        } catch (error) {
            console.error('Error in getOrGenerateFortune:', error);
            throw error;
        }
    }

    async getTranslatedFortune(
        fortuneId: string,
        language: SupportedLanguage,
    ): Promise<FortuneTelling | null> {
        if (language === 'ko') {
            const { data: fortune } = await this.supabase
                .from('fortune_telling')
                .select('*')
                .eq('id', fortuneId)
                .single();
            return fortune;
        }

        const { data: translation } = await this.supabase
            .from('fortune_telling_i18n')
            .select('*')
            .eq('fortune_id', fortuneId)
            .eq('language', language)
            .single();

        return translation;
    }

    private async checkAndGenerateTranslations(fortune: FortuneTelling): Promise<void> {
        const languages: SupportedLanguage[] = ['en', 'ja', 'zh'];

        // 각 언어별로 번역 데이터 존재 여부 확인
        for (const lang of languages) {
            try {
                const { data: existingTranslation } = await this.supabase
                    .from('fortune_telling_i18n')
                    .select('id')
                    .eq('fortune_id', fortune.id)
                    .eq('language', lang)
                    .single();

                if (!existingTranslation) {
                    console.log(`Generating missing translation for language: ${lang}`);

                    // 번역 생성
                    const translatedFortune = await this.translateFortune(fortune, lang);

                    // 번역 데이터 저장
                    const { error: insertError } = await this.supabase
                        .from('fortune_telling_i18n')
                        .insert({
                            fortune_id: fortune.id,
                            artist_id: fortune.artist_id,
                            year: fortune.year,
                            language: lang,
                            overall_luck: translatedFortune.overall_luck,
                            monthly_fortunes: translatedFortune.monthly_fortunes,
                            aspects: translatedFortune.aspects,
                            lucky: translatedFortune.lucky,
                            advice: translatedFortune.advice,
                        });

                    if (insertError) {
                        throw insertError;
                    }

                    console.log(`Translation generated and saved for ${lang}`);
                }
            } catch (error) {
                console.error(`Error handling translation for ${lang}:`, error);
                // 개별 언어 처리 실패 시 다음 언어 처리 계속 진행
            }
        }
    }

    private async generateNewFortune(
        artistId: number,
        artistName: string,
        artistYY: number,
        artistMM: number,
        artistDD: number,
        artistGender: string,
        year: number,
    ): Promise<FortuneTelling> {
        try {
            // 프롬프트 조회
            const prompt = await this.promptService.getActivePrompt('fortune_telling');

            let tokenCount: number | undefined;

            // 프롬프트 실행
            const response = await generateCompletion(prompt.name, {
                ...prompt.model_config,
                onTokenCount: (totalTokens: number | undefined) => {
                    tokenCount = totalTokens;
                },
                variables: {
                    artist_name: artistName,
                    artist_yy: artistYY.toString(),
                    artist_mm: artistMM.toString(),
                    artist_dd: artistDD.toString(),
                    artist_gender: artistGender,
                    year: year.toString(),
                },
            });

            // 결과 파싱 및 검증
            const result = JSON.parse(response.replaceAll('`', '').replace('json', ''));

            if (!this.validateFortuneResult(result)) {
                throw new Error('Invalid fortune result format');
            }

            // 프롬프트 사용 로깅
            await this.promptService.logPromptUsage({
                prompt_id: prompt.id,
                variables: { artist_name: artistName, year },
                response: result,
                token_count: tokenCount,
            });

            // 운세 객체 생성
            const fortune: FortuneTelling = {
                id: result.id,
                artist_id: artistId,
                year,
                overall_luck: result.overall_luck,
                monthly_fortunes: result.monthly_fortunes,
                aspects: result.aspects,
                lucky: result.lucky,
                advice: result.advice,
            };

            return fortune;
        } catch (error) {
            console.error('Error generating fortune:', error);
            throw error;
        }
    }

    private async generateTranslations(fortune: FortuneTelling): Promise<void> {
        const languages: SupportedLanguage[] = ['en', 'ja', 'zh'];

        console.log('Starting translations for fortune:', fortune.id);

        for (const lang of languages) {
            try {
                // 기존 번역이 있는지 확인
                const { data: existingTranslation, error: checkError } = await this.supabase
                    .from('fortune_telling_i18n')
                    .select('*')
                    .eq('fortune_id', fortune.id)
                    .eq('language', lang)
                    .single();

                if (!checkError && existingTranslation) {
                    console.log(`Translation for ${lang} already exists`);
                    continue;
                }

                console.log(`Generating translation for ${lang}...`);

                // 번역 생성
                const translatedFortune = await this.translateFortune(fortune, lang);

                // 번역 데이터 준비
                const translationData = {
                    fortune_id: fortune.id,
                    artist_id: fortune.artist_id,
                    year: fortune.year,
                    language: lang,
                    overall_luck: translatedFortune.overall_luck,
                    monthly_fortunes: translatedFortune.monthly_fortunes,
                    aspects: translatedFortune.aspects,
                    lucky: translatedFortune.lucky,
                    advice: translatedFortune.advice,
                };

                // 번역 저장
                const { error: saveError } = await this.supabase
                    .from('fortune_telling_i18n')
                    .insert(translationData);

                if (saveError) {
                    throw saveError;
                }

                console.log(`Translation completed for ${lang}`);
            } catch (error) {
                console.error(`Error generating translation for ${lang}:`, error);
                // 개별 언어의 번역 실패는 다른 언어의 번역을 중단시키지 않음
            }
        }

        console.log('All translations completed');
    }

    private async translateFortune(
        fortune: FortuneTelling,
        language: SupportedLanguage,
    ): Promise<Omit<FortuneTelling, 'id' | 'created_at' | 'updated_at'>> {
        const translatedMonthly = await Promise.all(
            fortune.monthly_fortunes.map(async (monthly) => ({
                month: monthly.month,
                summary: await this.translateSingle(monthly.summary, language),
                love: await this.translateSingle(monthly.love, language),
                career: await this.translateSingle(monthly.career, language),
                health: await this.translateSingle(monthly.health, language),
            })),
        );

        const translatedAspects = {
            career: await this.translateSingle(fortune.aspects.career, language),
            love: await this.translateSingle(fortune.aspects.love, language),
            health: await this.translateSingle(fortune.aspects.health, language),
            relationships: await this.translateSingle(fortune.aspects.relationships, language),
            finances: await this.translateSingle(fortune.aspects.finances, language),
        };

        const translatedLucky = {
            colors: await this.translateArray(fortune.lucky.colors, language),
            numbers: fortune.lucky.numbers,
            days: await this.translateArray(fortune.lucky.days, language),
            directions: await this.translateArray(fortune.lucky.directions, language),
        };

        return {
            artist_id: fortune.artist_id,
            year: fortune.year,
            overall_luck: await this.translateSingle(fortune.overall_luck, language),
            monthly_fortunes: translatedMonthly,
            aspects: translatedAspects,
            lucky: translatedLucky,
            advice: await this.translateArray(fortune.advice, language),
        };
    }

    private async translateSingle(text: string, language: SupportedLanguage): Promise<string> {
        const translated = await translateBatch([text], language);
        return translated[0] ?? text;
    }

    private async translateArray(texts: string[], language: SupportedLanguage): Promise<string[]> {
        try {
            const translated = await translateBatch(texts, language);
            return translated.map((t, i) => t ?? texts[i]);
        } catch (error) {
            console.error('Translation error:', error);
            return texts;
        }
    }

    private validateFortuneResult(result: any): boolean {
        return (
            result &&
            typeof result.overall_luck === 'string' &&
            Array.isArray(result.monthly_fortunes) &&
            result.monthly_fortunes.length === 12 &&
            typeof result.aspects === 'object' &&
            typeof result.lucky === 'object' &&
            Array.isArray(result.advice) &&
            result.advice.length === 3
        );
    }
}
