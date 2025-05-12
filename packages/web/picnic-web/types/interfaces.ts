// Auto-generated interfaces from Supabase types

export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[];

export type BoardStatusEnum = "pending" | "approved" | "rejected";

export type CandyHistoryType = "AD" | "VOTE" | "PURCHASE" | "GIFT" | "EXPIRED" | "VOTE_SHARE_BONUS" | "OPEN_COMPATIBILITY" | "MISSION";

export type CompatibilityStatus = "pending" | "completed" | "error";

export type PlatformEnum = "iOS" | "Android" | "Both";

export type PolicyLanguageEnum = "ko" | "en";

export type ProductTypeEnum = "consumable" | "non-consumable" | "subscription";

export type SupportedLanguage = "ko" | "en" | "ja" | "zh";

export type UserGenderEnum = "male" | "female" | "other";

export interface Activities {
  activityType: string
  description: string
  details: Json | null
  id: number
  ipAddress: string | null
  resourceId: string | null
  resourceType: string
  timestamp: string
  userAgent: string | null
  userId: string | null
}

export interface AdminPermissions {
  action: string
  createdAt: string | null
  description: string | null
  id: string
  resource: string
  updatedAt: string | null
}

export interface AdminRolePermissions {
  createdAt: string | null
  id: string
  permissionId: string
  roleId: string
  updatedAt: string | null
}

export interface AdminRoles {
  createdAt: string | null
  description: string | null
  id: string
  name: string
  updatedAt: string | null
}

export interface AdminUserRoles {
  createdAt: string | null
  id: string
  roleId: string
  updatedAt: string | null
  userId: string
}

export interface Album {
  createdAt: string | null
  deletedAt: string | null
  id: number | null
  title: string | null
  updatedAt: string | null
  userId: number | null
}

export interface AlbumImage {
  albumId: number | null
  imageId: number | null
}

export interface AlbumImageUser {
  imageId: number | null
  userId: number | null
}

export interface AppSplash {
  createdAt: string | null
  deletedAt: string | null
  duration: number | null
  endAt: string | null
  id: number
  image: Json | null
  startAt: string | null
  updatedAt: string | null
}

export interface Article {
  commentCount: number | null
  content: string | null
  createdAt: string | null
  deletedAt: string | null
  galleryId: number
  id: number
  titleEn: string | null
  titleKo: string | null
  updatedAt: string | null
}

export interface ArticleComment {
  articleId: number | null
  childrencount: number | null
  content: string | null
  createdAt: string | null
  deletedAt: string | null
  id: number | null
  likes: number | null
  parentId: number | null
  updatedAt: string | null
  userId: number | null
}

export interface ArticleCommentLike {
  commentId: number | null
  userId: number | null
}

export interface ArticleCommentReport {
  commentId: number | null
  userId: number | null
}

export interface ArticleImage {
  articleId: number
  createdAt: string | null
  deletedAt: string | null
  id: number
  image: string | null
  order: number | null
  titleEn: string | null
  titleKo: string | null
  updatedAt: string | null
}

export interface ArticleImageUser {
  imageId: number
  userId: string
}

export interface Artist {
  birthDate: string | null
  createdAt: string
  dd: number | null
  debutDate: string | null
  debutDd: number | null
  debutMm: number | null
  debutYy: number | null
  deletedAt: string | null
  gender: string | null
  groupId: number | null
  id: number
  image: string | null
  isKpop: boolean
  isMusical: boolean
  isSolo: boolean
  mm: number | null
  name: Json | null
  updatedAt: string
  yy: number | null
  artistGroup?: ArtistGroup;
  voteItem?: VoteItem[];
}

export interface ArtistGroup {
  createdAt: string
  debutDate: string | null
  debutDd: number | null
  debutMm: number | null
  debutYy: number | null
  deletedAt: string | null
  id: number
  image: string | null
  name: Json | null
  updatedAt: string
  artist?: Artist[];
  voteItem?: VoteItem[];
}

export interface ArtistUserBookmark {
  artistId: number | null
  createdAt: string
  deletedAt: string | null
  id: number
  updatedAt: string | null
  userId: string | null
}

export interface ArtistVote {
  category: string | null
  content: Json | null
  createdAt: string | null
  deletedAt: string | null
  id: number
  startAt: string | null
  stopAt: string | null
  title: Json | null
  updatedAt: string | null
  visibleAt: string | null
}

export interface ArtistVoteItem {
  artistVoteId: number | null
  createdAt: string | null
  deletedAt: string | null
  description: Json | null
  id: number
  title: Json | null
  updatedAt: string | null
  voteTotal: number | null
}

export interface AwsdmsDdlAudit {
  cDdlqry: string | null
  cKey: number
  cName: string | null
  cOid: number | null
  cSchema: string | null
  cTag: string | null
  cTime: string | null
  cTxn: string | null
  cUser: string | null
}

export interface Banner {
  celebId: number | null
  createdAt: string | null
  deletedAt: string | null
  duration: number | null
  endAt: string | null
  id: number
  image: Json | null
  link: string | null
  location: string | null
  order: number | null
  startAt: string | null
  thumbnail: string | null
  title: Json
  updatedAt: string | null
}

export interface BatchLog {
  batchName: string | null
  details: Json | null
  endTime: string | null
  id: number
  startTime: string | null
  status: string | null
}

export interface BlockedIps {
  blockedAt: string | null
  ipAddress: string
  reason: string | null
}

export interface Boards {
  artistId: number
  boardId: string
  createdAt: string
  creatorId: string | null
  deletedAt: string | null
  description: string | null
  features: string[] | null
  id: string
  isOfficial: boolean | null
  name: Json
  order: number | null
  parentBoardId: string | null
  requestMessage: string | null
  status: BoardStatusEnum
  updatedAt: string
}

export interface BonusExpiryLog {
  createdAt: string | null
  details: Json | null
  id: number
  operation: string | null
}

export interface Celeb {
  createdAt: string | null
  deletedAt: string | null
  id: number
  nameEn: string | null
  nameKo: string | null
  thumbnail: string | null
  updatedAt: string | null
}

export interface CelebBookmarkUser {
  celebId: number
  userId: string | null
}

export interface CommentLikes {
  commentId: string
  commentLikeId: string
  createdAt: string
  deletedAt: string | null
  updatedAt: string
  userId: string
}

export interface CommentReports {
  commentId: string | null
  commentReportId: string
  createdAt: string | null
  deletedAt: string | null
  reason: string | null
  updatedAt: string
  userId: string | null
}

export interface Comments {
  commentId: string
  content: Json | null
  createdAt: string
  deletedAt: string | null
  isHidden: boolean | null
  likes: number
  locale: string | null
  parentCommentId: string | null
  postId: string
  replies: number
  updatedAt: string
  userId: string | null
}

export interface CompatibilityResults {
  artistId: number
  completedAt: string | null
  createdAt: string
  details: Json | null
  errorMessage: string | null
  gender: UserGenderEnum | null
  id: string
  idolBirthDate: string
  isAds: boolean | null
  isPaid: boolean
  paidAt: string | null
  score: number | null
  status: CompatibilityStatus
  tips: Json | null
  userBirthDate: string
  userBirthTime: string | null
  userId: string
}

export interface CompatibilityResultsI18n {
  compatibilityId: string
  compatibilitySummary: string | null
  createdAt: string
  details: Json | null
  id: string
  language: SupportedLanguage
  score: number | null
  scoreTitle: string | null
  tips: Json | null
  updatedAt: string
}

export interface CompatibilityScoreDescriptions {
  score: number | null
  summaryEn: string
  summaryJa: string
  summaryKo: string
  summaryZh: string
  titleEn: string | null
  titleJa: string | null
  titleKo: string | null
  titleZh: string | null
}

export interface Config {
  createdAt: string | null
  id: string | null
  key: string
  updatedAt: string
  value: string | null
}

export interface CountryInfo {
  countryCode: string
  countryName: string
  gdp: number | null
  lastUpdated: string | null
  population: number | null
}

export interface CronLogs {
  createdAt: string
  endedAt: string | null
  id: number
  jobName: string
  logMessage: string | null
  startedAt: string
  status: string | null
}

export interface CustomLogs {
  details: Json | null
  logId: number
  logTime: string | null
  operation: string | null
}

export interface DebugDbLogs {
  detail: Json | null
  functionName: string
  id: number
  logTime: string | null
  step: string | null
}

export interface DebugLogs {
  createdAt: string | null
  id: number
  logMessage: string | null
}

export interface DeviceBans {
  bannedAt: string | null
  bannedBy: string | null
  createdAt: string | null
  deviceId: string | null
  id: string
  reason: string | null
  unbannedAt: string | null
}

export interface Devices {
  appBuildNumber: string | null
  appVersion: string | null
  banReason: string | null
  bannedAt: string | null
  createdAt: string | null
  deviceId: string
  deviceInfo: Json | null
  isBanned: boolean | null
  lastIp: string | null
  lastSeen: string | null
  lastUpdated: string | null
  userId: string | null
}

export interface Faqs {
  answer: Json
  category: string | null
  createdAt: string | null
  createdBy: string | null
  id: number
  orderNumber: number | null
  question: Json
  status: string | null
  updatedAt: string | null
}

export interface FortuneBatchLog {
  completedAt: string | null
  createdAt: string | null
  failedCount: number | null
  id: number
  processedCount: number | null
  status: string | null
  totalArtists: number | null
  year: number | null
}

export interface FortuneGenerationLog {
  artistId: number | null
  createdAt: string | null
  errorMessage: string | null
  id: number
  status: string | null
  year: number | null
}

export interface FortuneTelling {
  advice: string[]
  artistId: number
  aspects: Json
  createdAt: string | null
  id: string
  lucky: Json
  monthlyFortunes: Json
  overallLuck: string
  updatedAt: string | null
  year: number
}

export interface FortuneTellingI18n {
  advice: string[]
  artistId: number
  aspects: Json
  createdAt: string | null
  fortuneId: string
  id: string
  language: string
  lucky: Json
  monthlyFortunes: Json
  overallLuck: string
  updatedAt: string | null
  year: number
}

export interface Gallery {
  celebId: number
  cover: string | null
  createdAt: string
  deletedAt: string | null
  id: number
  title: Json | null
  titleEn: string | null
  titleKo: string | null
  updatedAt: string
}

export interface GalleryUser {
  galleryId: number | null
  userId: number | null
}

export interface IpCountryMapping {
  countryCode: string
  id: number
  ipRangeEnd: number
  ipRangeStart: number
  lastUpdated: string | null
}

export interface Library {
  createdAt: string | null
  deletedAt: string | null
  id: number | null
  title: string | null
  updatedAt: string | null
  userId: number | null
}

export interface LibraryImage {
  imageId: number | null
  libraryId: number | null
}

export interface Media {
  createdAt: string
  deletedAt: string | null
  id: number
  thumbnailUrl: string | null
  title: Json | null
  updatedAt: string
  videoId: string | null
  videoUrl: string | null
}

export interface Notices {
  content: Json
  createdAt: string | null
  createdBy: string | null
  id: number
  isPinned: boolean | null
  status: string | null
  title: Json
  updatedAt: string | null
}

export interface PartitionCreationLog {
  createdAt: string | null
  id: number
  message: string | null
}

export interface Permissions {
  action: string
  createdAt: string | null
  description: string | null
  id: string
  resource: string
  updatedAt: string | null
}

export interface PicVote {
  area: string | null
  createdAt: string
  deletedAt: string | null
  id: number
  mainImage: string | null
  order: number | null
  resultImage: string | null
  startAt: string | null
  stopAt: string | null
  title: Json | null
  updatedAt: string
  visibleAt: string | null
  voteCategory: string | null
  voteContent: string | null
  waitImage: string | null
}

export interface PicVoteItem {
  artistId: number | null
  createdAt: string | null
  deletedAt: string | null
  groupId: number | null
  id: number
  updatedAt: string | null
  voteId: number | null
  voteTotal: number | null
}

export interface PicVotePick {
  amount: number | null
  createdAt: string | null
  deletedAt: string | null
  id: number
  updatedAt: string | null
  userId: string | null
  voteId: number | null
  voteItemId: number
}

export interface PicVoteReward {
  rewardId: number
  voteId: number
}

export interface Policy {
  content: string
  createdAt: string
  deletedAt: string | null
  id: number
  language: PolicyLanguageEnum | null
  type: string | null
  updatedAt: string
  version: string
}

export interface Popup {
  content: Json | null
  createdAt: string | null
  deletedAt: string | null
  id: number
  image: Json | null
  platform: string | null
  startAt: string | null
  stopAt: string | null
  title: Json | null
  updatedAt: string | null
}

export interface PostAttachments {
  attachmentId: string
  fileName: string
  filePath: string
  fileSize: number
  fileType: string
  postId: string | null
}

export interface PostReports {
  createdAt: string | null
  deletedAt: string | null
  postId: string | null
  postReportId: string
  reason: string | null
  updatedAt: string
  userId: string | null
}

export interface PostScraps {
  createdAt: string | null
  deletedAt: string | null
  postId: string | null
  postScrapId: string
  updatedAt: string
  userId: string
}

export interface PostViews {
  postId: string
  userId: string
  viewedAt: string | null
}

export interface Posts {
  attachments: string[] | null
  boardId: string | null
  content: Json[] | null
  createdAt: string
  deletedAt: string | null
  id: string
  isAnonymous: boolean
  isHidden: boolean | null
  isTemporary: boolean
  postId: string
  replyCount: number
  title: string
  updatedAt: string | null
  userId: string
  viewCount: number
}

export interface Products {
  createdAt: string | null
  description: Json | null
  endAt: string | null
  id: string
  paypalLink: string | null
  platform: PlatformEnum
  price: number | null
  productName: string
  productType: ProductTypeEnum
  starCandy: number | null
  starCandyBonus: number | null
  startAt: string | null
}

export interface PromptUsageLogs {
  createdAt: string | null
  error: string | null
  executionTimeMs: number | null
  id: string
  promptId: string | null
  response: Json
  tokenCount: number | null
  variables: Json
}

export interface Prompts {
  category: string
  createdAt: string | null
  createdBy: string
  description: string | null
  id: string
  isActive: boolean | null
  modelConfig: Json
  name: string
  tags: string[] | null
  template: string
  updatedAt: string | null
  variables: string[]
  version: number
}

export interface Qnas {
  answer: string | null
  answeredAt: string | null
  answeredBy: string | null
  createdAt: string | null
  createdBy: string | null
  isPrivate: boolean | null
  qnaId: number
  question: string
  status: string | null
  title: string
  updatedAt: string | null
}

export interface Receipts {
  createdAt: string | null
  environment: string | null
  id: number
  platform: string
  productId: string | null
  receiptData: string
  receiptHash: string | null
  status: string
  userId: string | null
  verificationData: Json | null
}

export interface Reward {
  createdAt: string
  deletedAt: string | null
  id: number
  location: Json | null
  locationImages: string[] | null
  order: number | null
  overviewImages: string[] | null
  sizeGuide: Json | null
  sizeGuideImages: string[] | null
  thumbnail: string | null
  title: Json | null
  updatedAt: string
  voteReward?: VoteReward[];
  voteAchieve?: VoteAchieve[];
}

export interface RolePermissions {
  createdAt: string | null
  id: string
  permissionId: string
  roleId: string
  updatedAt: string | null
}

export interface RoleUsers {
  createdAt: string | null
  id: string
  roleId: string
  updatedAt: string | null
  userId: string
}

export interface Roles {
  createdAt: string | null
  description: string | null
  id: string
  name: string
  updatedAt: string | null
}

export interface StarCandyBonusHistory {
  amount: number | null
  createdAt: string
  deletedAt: string | null
  expiredDt: string | null
  id: number
  parentId: number | null
  remainAmount: number
  transactionId: string | null
  type: CandyHistoryType | null
  updatedAt: string
  userId: string
  votePickId: number | null
}

export interface StarCandyHistory {
  amount: number | null
  createdAt: string
  deletedAt: string | null
  id: number
  parentId: number | null
  transactionId: string | null
  type: CandyHistoryType | null
  updatedAt: string
  userId: string
  votePickId: number | null
}

export interface TransactionAdmob {
  adNetwork: string | null
  createdAt: string
  deletedAt: string | null
  keyId: string | null
  rewardAmount: number | null
  rewardType: string | null
  signature: string | null
  transactionId: string
  updatedAt: string
  userId: string | null
}

export interface TransactionPangle {
  adNetwork: string | null
  createdAt: string
  deletedAt: string | null
  keyId: string | null
  platform: string | null
  rewardAmount: number | null
  rewardName: string | null
  rewardType: string | null
  signature: string | null
  transactionId: string
  updatedAt: string
  userId: string | null
}

export interface TransactionPincrux {
  adNetwork: string | null
  appKey: string | null
  appTitle: string | null
  commission: number | null
  createdAt: string
  deletedAt: string | null
  menuCategory1: string | null
  pubKey: number | null
  rewardAmount: number | null
  rewardType: string | null
  signature: string | null
  transactionId: string
  updatedAt: string
  usrKey: string | null
}

export interface TransactionTapjoy {
  createdAt: string
  id: number
  platform: string | null
  rewardAmount: number
  rewardType: string | null
  transactionId: string
  userId: string
  verifier: string | null
}

export interface TransactionUnity {
  adNetwork: string | null
  createdAt: string
  deletedAt: string | null
  hmac: string
  rewardAmount: number | null
  rewardType: string | null
  transactionId: string
  updatedAt: string
  userId: string
}

export interface UserAgreement {
  createdAt: string | null
  deletedAt: string | null
  id: string
  privacy: string | null
  terms: string | null
  updatedAt: string | null
}

export interface UserBlocks {
  blockedUserId: string
  createdAt: string
  deletedAt: string | null
  id: string
  userId: string
}

export interface UserCommentLike {
  commentId: number | null
  createdAt: string | null
  deletedAt: string | null
  id: number | null
  updatedAt: string | null
  userId: number | null
}

export interface UserCommentReport {
  commentId: number | null
  createdAt: string | null
  deletedAt: string | null
  id: number | null
  updatedAt: string | null
  userId: number | null
}

export interface UserProfiles {
  avatarUrl: string | null
  birthDate: string | null
  birthTime: string | null
  createdAt: string
  deletedAt: string | null
  email: string | null
  gender: UserGenderEnum | null
  id: string
  isAdmin: boolean
  nickname: string | null
  openAges: boolean
  openGender: boolean
  starCandy: number
  starCandyBonus: number
  updatedAt: string
  votePick?: VotePick[];
  voteComment?: VoteComment[];
  voteCommentLike?: VoteCommentLike[];
  voteCommentReport?: VoteCommentReport[];
  voteShareBonus?: VoteShareBonus[];
}

export interface UserRoles {
  createdAt: string | null
  id: string
  roleId: string
  updatedAt: string | null
  userId: string
}

export interface Version {
  android: Json | null
  createdAt: string
  deletedAt: string | null
  id: number
  ios: Json | null
  linux: Json | null
  macos: Json | null
  updatedAt: string
  windows: Json | null
}

export interface Vote {
  area: string
  createdAt: string
  deletedAt: string | null
  id: number
  mainImage: string | null
  order: number | null
  resultImage: string | null
  startAt: string | null
  stopAt: string | null
  title: Json | null
  updatedAt: string
  visibleAt: string | null
  voteCategory: string | null
  voteContent: string | null
  voteSubCategory: string | null
  waitImage: string | null
  voteItem?: VoteItem[];
  votePick?: VotePick[];
  voteComment?: VoteComment[];
  voteReward?: VoteReward[];
  voteShareBonus?: VoteShareBonus[];
  voteAchieve?: VoteAchieve[];
}

export interface VoteAchieve {
  amount: number | null
  id: number | null
  order: number | null
  rewardId: number | null
  voteId: number | null
  vote?: Vote;
  reward?: Reward;
}

export interface VoteComment {
  childrencount: number | null
  content: string | null
  createdAt: string | null
  deletedAt: string | null
  id: number | null
  likes: number | null
  parentId: number | null
  updatedAt: string | null
  userId: number | null
  voteId: number | null
  vote?: Vote;
  userProfiles?: UserProfiles;
  voteCommentLike?: VoteCommentLike[];
  voteCommentReport?: VoteCommentReport[];
}

export interface VoteCommentLike {
  commentId: number | null
  userId: number | null
  voteComment?: VoteComment;
  userProfiles?: UserProfiles;
}

export interface VoteCommentReport {
  commentId: number | null
  userId: number | null
  voteComment?: VoteComment;
  userProfiles?: UserProfiles;
}

export interface VoteItem {
  artistId: number | null
  createdAt: string | null
  deletedAt: string | null
  groupId: number
  id: number
  updatedAt: string | null
  voteId: number | null
  voteTotal: number | null
  vote?: Vote;
  artist?: Artist;
  artistGroup?: ArtistGroup;
}

export interface VotePick {
  amount: number | null
  createdAt: string | null
  deletedAt: string | null
  id: number
  updatedAt: string | null
  userId: string | null
  voteId: number | null
  voteItemId: number
  vote?: Vote;
  voteItem?: VoteItem;
  userProfiles?: UserProfiles;
}

export interface VoteReward {
  rewardId: number
  voteId: number
  vote?: Vote;
  reward?: Reward;
}

export interface VoteShareBonus {
  amount: number
  createdAt: string
  id: number
  updatedAt: string
  userId: string
  voteId: number
  vote?: Vote;
  userProfiles?: UserProfiles;
}

export interface ViewTransactionAll {
  adNetwork: string | null
  commission: number | null
  createdAt: string | null
  platform: string | null
  rewardAmount: number | null
  rewardName: string | null
  rewardType: string | null
  source: string | null
  transactionId: string | null
  userId: string | null
}