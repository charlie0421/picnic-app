import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

// Define Json type
export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[];

// Define enums directly
export type BoardStatusEnum = "pending" | "approved" | "rejected";

export type CandyHistoryType =
  | "AD"
  | "VOTE"
  | "PURCHASE"
  | "GIFT"
  | "EXPIRED"
  | "VOTE_SHARE_BONUS"
  | "OPEN_COMPATIBILITY"
  | "MISSION";

export type CompatibilityStatus = "pending" | "completed" | "error";

export type PlatformEnum = "iOS" | "Android" | "Both";

export type PolicyLanguageEnum = "ko" | "en";

export type ProductTypeEnum = "consumable" | "non-consumable" | "subscription";

export type SupportedLanguage = "ko" | "en" | "ja" | "zh";

export type UserGenderEnum = "male" | "female" | "other";

function log(message: string) {
  process.stdout.write(message + '\n');
}

function toCamelCase(str: string): string {
  return str
    .split('_')
    .map((word, index) => {
      if (index === 0) return word;
      return word.charAt(0).toUpperCase() + word.slice(1);
    })
    .join('');
}

function toPascalCase(str: string): string {
  return str
    .split('_')
    .map(word => word.charAt(0).toUpperCase() + word.slice(1))
    .join('');
}

function generateInterfaces() {
  const __filename = fileURLToPath(import.meta.url);
  const __dirname = path.dirname(__filename);

  log('🔍 Supabase 타입 파일을 읽는 중...');
  const fileContent = fs.readFileSync(path.join(__dirname, '../types/supabase.ts'), 'utf-8');
  const interfaces: string[] = [];

  log('📝 Json 타입 정의 추가 중...');
  // Add Json type definition
  interfaces.push(`export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[];`);

  log('📝 Enum 타입 정의 추가 중...');
  // Add enum type definitions
  interfaces.push(`export type BoardStatusEnum = "pending" | "approved" | "rejected";`);
  interfaces.push(`export type CandyHistoryType = "AD" | "VOTE" | "PURCHASE" | "GIFT" | "EXPIRED" | "VOTE_SHARE_BONUS" | "OPEN_COMPATIBILITY" | "MISSION";`);
  interfaces.push(`export type CompatibilityStatus = "pending" | "completed" | "error";`);
  interfaces.push(`export type PlatformEnum = "iOS" | "Android" | "Both";`);
  interfaces.push(`export type PolicyLanguageEnum = "ko" | "en";`);
  interfaces.push(`export type ProductTypeEnum = "consumable" | "non-consumable" | "subscription";`);
  interfaces.push(`export type SupportedLanguage = "ko" | "en" | "ja" | "zh";`);
  interfaces.push(`export type UserGenderEnum = "male" | "female" | "other";`);

  log('🔍 테이블 인터페이스 생성 중...');
  // Extract table names and their Row types
  const tableRegex = /(\w+): {\s*Row: {([^}]*)}/g;
  let match;
  let tableCount = 0;

  // 외래키 관계 정의
  const foreignKeyRelations: Record<string, Array<{table: string, isArray: boolean}>> = {
    'VoteItem': [
      {table: 'Vote', isArray: false},
      {table: 'Artist', isArray: false},
      {table: 'ArtistGroup', isArray: false}
    ],
    'Vote': [
      {table: 'VoteItem', isArray: true},
      {table: 'VotePick', isArray: true},
      {table: 'VoteComment', isArray: true},
      {table: 'VoteReward', isArray: true},
      {table: 'VoteShareBonus', isArray: true},
      {table: 'VoteAchieve', isArray: true}
    ],
    'Artist': [
      {table: 'ArtistGroup', isArray: false},
      {table: 'VoteItem', isArray: true}
    ],
    'ArtistGroup': [
      {table: 'Artist', isArray: true},
      {table: 'VoteItem', isArray: true}
    ],
    'VotePick': [
      {table: 'Vote', isArray: false},
      {table: 'VoteItem', isArray: false},
      {table: 'UserProfiles', isArray: false}
    ],
    'VoteComment': [
      {table: 'Vote', isArray: false},
      {table: 'UserProfiles', isArray: false},
      {table: 'VoteCommentLike', isArray: true},
      {table: 'VoteCommentReport', isArray: true}
    ],
    'VoteCommentLike': [
      {table: 'VoteComment', isArray: false},
      {table: 'UserProfiles', isArray: false}
    ],
    'VoteCommentReport': [
      {table: 'VoteComment', isArray: false},
      {table: 'UserProfiles', isArray: false}
    ],
    'VoteReward': [
      {table: 'Vote', isArray: false},
      {table: 'Reward', isArray: false}
    ],
    'VoteShareBonus': [
      {table: 'Vote', isArray: false},
      {table: 'UserProfiles', isArray: false}
    ],
    'VoteAchieve': [
      {table: 'Vote', isArray: false},
      {table: 'Reward', isArray: false}
    ],
    'UserProfiles': [
      {table: 'VotePick', isArray: true},
      {table: 'VoteComment', isArray: true},
      {table: 'VoteCommentLike', isArray: true},
      {table: 'VoteCommentReport', isArray: true},
      {table: 'VoteShareBonus', isArray: true}
    ],
    'Reward': [
      {table: 'VoteReward', isArray: true},
      {table: 'VoteAchieve', isArray: true}
    ]
  };

  while ((match = tableRegex.exec(fileContent)) !== null) {
    const tableName = match[1];
    const pascalCaseTableName = toPascalCase(tableName);
    const rowContent = match[2];
    tableCount++;
    
    log(`📦 ${pascalCaseTableName} 테이블 인터페이스 생성 중 (${tableCount}번째)...`);
    
    // Parse fields
    const fields = rowContent
      .split('\n')
      .map(line => line.trim())
      .filter(line => line.length > 0)
      .map(line => {
        const [name, type] = line.split(':').map(s => s.trim());
        const camelCaseName = toCamelCase(name);
        // Replace Database enum references with our local type definitions
        const processedType = type
          .replace(/Database\["public"\]\["Enums"\]\["board_status_enum"\]/g, 'BoardStatusEnum')
          .replace(/Database\["public"\]\["Enums"\]\["candy_history_type"\]/g, 'CandyHistoryType')
          .replace(/Database\["public"\]\["Enums"\]\["compatibility_status"\]/g, 'CompatibilityStatus')
          .replace(/Database\["public"\]\["Enums"\]\["platform_enum"\]/g, 'PlatformEnum')
          .replace(/Database\["public"\]\["Enums"\]\["policy_language_enum"\]/g, 'PolicyLanguageEnum')
          .replace(/Database\["public"\]\["Enums"\]\["product_type_enum"\]/g, 'ProductTypeEnum')
          .replace(/Database\["public"\]\["Enums"\]\["supported_language"\]/g, 'SupportedLanguage')
          .replace(/Database\["public"\]\["Enums"\]\["user_gender_enum"\]/g, 'UserGenderEnum')
          .replace(/\s*$/g, '');
        return `  ${camelCaseName}: ${processedType}`;
      });

    // Generate interface
    let allFields = [...fields];
    const pascalCaseKey = toPascalCase(tableName);
    if (foreignKeyRelations[pascalCaseKey]) {
      foreignKeyRelations[pascalCaseKey].forEach(({table, isArray}) => {
        const pascalCaseRelatedTable = toPascalCase(table);
        const fieldName = pascalCaseRelatedTable.charAt(0).toLowerCase() + pascalCaseRelatedTable.slice(1);
        allFields.push(`  ${fieldName}?: ${pascalCaseRelatedTable}${isArray ? '[]' : ''};`);
      });
    }
    const interfaceContent = `export interface ${pascalCaseTableName} {\n${allFields.join('\n')}\n}`;
    interfaces.push(interfaceContent);
  }

  log(`✅ 총 ${tableCount}개의 테이블 인터페이스 생성 완료`);
  log('📝 인터페이스 파일 작성 중...');

  // Write to file
  const output = '// Auto-generated interfaces from Supabase types\n\n' + interfaces.join('\n\n');
  fs.writeFileSync(path.join(__dirname, '../types/interfaces.ts'), output);
  log('✨ 인터페이스 파일 작성 완료');
}

log('🚀 인터페이스 생성 시작');
generateInterfaces();
log('✨ 인터페이스 생성 완료'); 