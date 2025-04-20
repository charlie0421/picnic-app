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

export interface activities {
  activity_type: string
  description: string
  details: Json | null
  id: number
  ip_address: string | null
  resource_id: string | null
  resource_type: string
  timestamp: string
  user_agent: string | null
  user_id: string | null
}

export interface admin_permissions {
  action: string
  created_at: string | null
  description: string | null
  id: string
  resource: string
  updated_at: string | null
}

export interface admin_role_permissions {
  created_at: string | null
  id: string
  permission_id: string
  role_id: string
  updated_at: string | null
}

export interface admin_roles {
  created_at: string | null
  description: string | null
  id: string
  name: string
  updated_at: string | null
}

export interface admin_user_roles {
  created_at: string | null
  id: string
  role_id: string
  updated_at: string | null
  user_id: string
}

export interface album {
  created_at: string | null
  deleted_at: string | null
  id: number | null
  title: string | null
  updated_at: string | null
  user_id: number | null
}

export interface album_image {
  album_id: number | null
  image_id: number | null
}

export interface album_image_user {
  image_id: number | null
  user_id: number | null
}

export interface app_splash {
  created_at: string | null
  deleted_at: string | null
  duration: number | null
  end_at: string | null
  id: number
  image: Json | null
  start_at: string | null
  updated_at: string | null
}

export interface article {
  comment_count: number | null
  content: string | null
  created_at: string | null
  deleted_at: string | null
  gallery_id: number
  id: number
  title_en: string | null
  title_ko: string | null
  updated_at: string | null
}

export interface article_comment {
  article_id: number | null
  childrencount: number | null
  content: string | null
  created_at: string | null
  deleted_at: string | null
  id: number | null
  likes: number | null
  parent_id: number | null
  updated_at: string | null
  user_id: number | null
}

export interface article_comment_like {
  comment_id: number | null
  user_id: number | null
}

export interface article_comment_report {
  comment_id: number | null
  user_id: number | null
}

export interface article_image {
  article_id: number
  created_at: string | null
  deleted_at: string | null
  id: number
  image: string | null
  order: number | null
  title_en: string | null
  title_ko: string | null
  updated_at: string | null
}

export interface article_image_user {
  image_id: number
  user_id: string
}

export interface artist {
  birth_date: string | null
  created_at: string
  dd: number | null
  debut_date: string | null
  debut_dd: number | null
  debut_mm: number | null
  debut_yy: number | null
  deleted_at: string | null
  gender: string | null
  group_id: number
  id: number
  image: string | null
  mm: number | null
  name: Json | null
  updated_at: string
  yy: number | null
}

export interface artist_group {
  created_at: string
  debut_date: string | null
  debut_dd: number | null
  debut_mm: number | null
  debut_yy: number | null
  deleted_at: string | null
  id: number
  image: string | null
  name: Json | null
  updated_at: string
}

export interface artist_user_bookmark {
  artist_id: number | null
  created_at: string
  deleted_at: string | null
  id: number
  updated_at: string | null
  user_id: string | null
}

export interface artist_vote {
  category: string | null
  content: Json | null
  created_at: string | null
  deleted_at: string | null
  id: number
  start_at: string | null
  stop_at: string | null
  title: Json | null
  updated_at: string | null
  visible_at: string | null
}

export interface artist_vote_item {
  artist_vote_id: number | null
  created_at: string | null
  deleted_at: string | null
  description: Json | null
  id: number
  title: Json | null
  updated_at: string | null
  vote_total: number | null
}

export interface awsdms_ddl_audit {
  c_ddlqry: string | null
  c_key: number
  c_name: string | null
  c_oid: number | null
  c_schema: string | null
  c_tag: string | null
  c_time: string | null
  c_txn: string | null
  c_user: string | null
}

export interface banner {
  celeb_id: number | null
  created_at: string | null
  deleted_at: string | null
  duration: number | null
  end_at: string | null
  id: number
  image: Json | null
  link: string | null
  location: string | null
  order: number | null
  start_at: string | null
  thumbnail: string | null
  title: Json
  updated_at: string | null
}

export interface batch_log {
  batch_name: string | null
  details: Json | null
  end_time: string | null
  id: number
  start_time: string | null
  status: string | null
}

export interface blocked_ips {
  blocked_at: string | null
  ip_address: string
  reason: string | null
}

export interface boards {
  artist_id: number
  board_id: string
  created_at: string
  creator_id: string | null
  deleted_at: string | null
  description: string | null
  features: string[] | null
  id: string
  is_official: boolean | null
  name: Json
  order: number | null
  parent_board_id: string | null
  request_message: string | null
  status: BoardStatusEnum
  updated_at: string
}

export interface bonus_expiry_log {
  created_at: string | null
  details: Json | null
  id: number
  operation: string | null
}

export interface celeb {
  created_at: string | null
  deleted_at: string | null
  id: number
  name_en: string | null
  name_ko: string | null
  thumbnail: string | null
  updated_at: string | null
}

export interface celeb_bookmark_user {
  celeb_id: number
  user_id: string | null
}

export interface comment_likes {
  comment_id: string
  comment_like_id: string
  created_at: string
  deleted_at: string | null
  updated_at: string
  user_id: string
}

export interface comment_reports {
  comment_id: string | null
  comment_report_id: string
  created_at: string | null
  deleted_at: string | null
  reason: string | null
  updated_at: string
  user_id: string | null
}

export interface comments {
  comment_id: string
  content: Json | null
  created_at: string
  deleted_at: string | null
  is_hidden: boolean | null
  likes: number
  locale: string | null
  parent_comment_id: string | null
  post_id: string
  replies: number
  updated_at: string
  user_id: string | null
}

export interface compatibility_results {
  artist_id: number
  completed_at: string | null
  created_at: string
  details: Json | null
  error_message: string | null
  gender: UserGenderEnum | null
  id: string
  idol_birth_date: string
  is_ads: boolean | null
  is_paid: boolean
  paid_at: string | null
  score: number | null
  status: CompatibilityStatus
  tips: Json | null
  user_birth_date: string
  user_birth_time: string | null
  user_id: string
}

export interface compatibility_results_i18n {
  compatibility_id: string
  compatibility_summary: string | null
  created_at: string
  details: Json | null
  id: string
  language: SupportedLanguage
  score: number | null
  score_title: string | null
  tips: Json | null
  updated_at: string
}

export interface compatibility_score_descriptions {
  score: number | null
  summary_en: string
  summary_ja: string
  summary_ko: string
  summary_zh: string
  title_en: string | null
  title_ja: string | null
  title_ko: string | null
  title_zh: string | null
}

export interface config {
  created_at: string | null
  id: string | null
  key: string
  updated_at: string
  value: string | null
}

export interface country_info {
  country_code: string
  country_name: string
  gdp: number | null
  last_updated: string | null
  population: number | null
}

export interface cron_logs {
  created_at: string
  ended_at: string | null
  id: number
  job_name: string
  log_message: string | null
  started_at: string
  status: string | null
}

export interface custom_logs {
  details: Json | null
  log_id: number
  log_time: string | null
  operation: string | null
}

export interface debug_db_logs {
  detail: Json | null
  function_name: string
  id: number
  log_time: string | null
  step: string | null
}

export interface debug_logs {
  created_at: string | null
  id: number
  log_message: string | null
}

export interface device_bans {
  banned_at: string | null
  banned_by: string | null
  created_at: string | null
  device_id: string | null
  id: string
  reason: string | null
  unbanned_at: string | null
}

export interface devices {
  app_build_number: string | null
  app_version: string | null
  ban_reason: string | null
  banned_at: string | null
  created_at: string | null
  device_id: string
  device_info: Json | null
  is_banned: boolean | null
  last_ip: string | null
  last_seen: string | null
  last_updated: string | null
  user_id: string | null
}

export interface faqs {
  answer: string
  category: string | null
  created_at: string | null
  created_by: string | null
  id: number
  order_number: number | null
  question: string
  status: string | null
  updated_at: string | null
}

export interface fortune_batch_log {
  completed_at: string | null
  created_at: string | null
  failed_count: number | null
  id: number
  processed_count: number | null
  status: string | null
  total_artists: number | null
  year: number | null
}

export interface fortune_generation_log {
  artist_id: number | null
  created_at: string | null
  error_message: string | null
  id: number
  status: string | null
  year: number | null
}

export interface fortune_telling {
  advice: string[]
  artist_id: number
  aspects: Json
  created_at: string | null
  id: string
  lucky: Json
  monthly_fortunes: Json
  overall_luck: string
  updated_at: string | null
  year: number
}

export interface fortune_telling_i18n {
  advice: string[]
  artist_id: number
  aspects: Json
  created_at: string | null
  fortune_id: string
  id: string
  language: string
  lucky: Json
  monthly_fortunes: Json
  overall_luck: string
  updated_at: string | null
  year: number
}

export interface gallery {
  celeb_id: number
  cover: string | null
  created_at: string
  deleted_at: string | null
  id: number
  title: Json | null
  title_en: string | null
  title_ko: string | null
  updated_at: string
}

export interface gallery_user {
  gallery_id: number | null
  user_id: number | null
}

export interface ip_country_mapping {
  country_code: string
  id: number
  ip_range_end: number
  ip_range_start: number
  last_updated: string | null
}

export interface library {
  created_at: string | null
  deleted_at: string | null
  id: number | null
  title: string | null
  updated_at: string | null
  user_id: number | null
}

export interface library_image {
  image_id: number | null
  library_id: number | null
}

export interface media {
  created_at: string
  deleted_at: string | null
  id: number
  thumbnail_url: string | null
  title: Json | null
  updated_at: string
  video_id: string | null
  video_url: string | null
}

export interface notices {
  content: string
  created_at: string | null
  created_by: string | null
  id: number
  is_pinned: boolean | null
  status: string | null
  title: string
  updated_at: string | null
}

export interface partition_creation_log {
  created_at: string | null
  id: number
  message: string | null
}

export interface permissions {
  action: string
  created_at: string | null
  description: string | null
  id: string
  resource: string
  updated_at: string | null
}

export interface pic_vote {
  created_at: string
  deleted_at: string | null
  id: number
  main_image: string | null
  order: number | null
  result_image: string | null
  start_at: string | null
  stop_at: string | null
  title: Json | null
  updated_at: string
  visible_at: string | null
  vote_category: string | null
  vote_content: string | null
  wait_image: string | null
}

export interface pic_vote_item {
  artist_id: number | null
  created_at: string | null
  deleted_at: string | null
  group_id: number | null
  id: number
  updated_at: string | null
  vote_id: number | null
  vote_total: number | null
}

export interface pic_vote_pick {
  amount: number | null
  created_at: string | null
  deleted_at: string | null
  id: number
  updated_at: string | null
  user_id: string | null
  vote_id: number | null
  vote_item_id: number
}

export interface pic_vote_reward {
  reward_id: number
  vote_id: number
}

export interface policy {
  content: string
  created_at: string
  deleted_at: string | null
  id: number
  language: PolicyLanguageEnum | null
  type: string | null
  updated_at: string
  version: string
}

export interface post_attachments {
  attachment_id: string
  file_name: string
  file_path: string
  file_size: number
  file_type: string
  post_id: string | null
}

export interface post_reports {
  created_at: string | null
  deleted_at: string | null
  post_id: string | null
  post_report_id: string
  reason: string | null
  updated_at: string
  user_id: string | null
}

export interface post_scraps {
  created_at: string | null
  deleted_at: string | null
  post_id: string | null
  post_scrap_id: string
  updated_at: string
  user_id: string
}

export interface post_views {
  post_id: string
  user_id: string
  viewed_at: string | null
}

export interface posts {
  attachments: string[] | null
  board_id: string | null
  content: Json[] | null
  created_at: string
  deleted_at: string | null
  id: string
  is_anonymous: boolean
  is_hidden: boolean | null
  is_temporary: boolean
  post_id: string
  reply_count: number
  title: string
  updated_at: string | null
  user_id: string
  view_count: number
}

export interface products {
  created_at: string | null
  description: Json | null
  end_at: string | null
  id: string
  paypal_link: string | null
  platform: PlatformEnum
  price: number | null
  product_name: string
  product_type: ProductTypeEnum
  star_candy: number | null
  star_candy_bonus: number | null
  start_at: string | null
}

export interface prompt_usage_logs {
  created_at: string | null
  error: string | null
  execution_time_ms: number | null
  id: string
  prompt_id: string | null
  response: Json
  token_count: number | null
  variables: Json
}

export interface prompts {
  category: string
  created_at: string | null
  created_by: string
  description: string | null
  id: string
  is_active: boolean | null
  model_config: Json
  name: string
  tags: string[] | null
  template: string
  updated_at: string | null
  variables: string[]
  version: number
}

export interface qnas {
  answer: string | null
  answered_at: string | null
  answered_by: string | null
  created_at: string | null
  created_by: string | null
  is_private: boolean | null
  qna_id: number
  question: string
  status: string | null
  title: string
  updated_at: string | null
}

export interface receipts {
  created_at: string | null
  environment: string | null
  id: number
  platform: string
  product_id: string | null
  receipt_data: string
  receipt_hash: string | null
  status: string
  user_id: string | null
  verification_data: Json | null
}

export interface reward {
  created_at: string
  deleted_at: string | null
  id: number
  location: Json | null
  location_images: string[] | null
  order: number | null
  overview_images: string[] | null
  size_guide: Json | null
  size_guide_images: string[] | null
  thumbnail: string | null
  title: Json | null
  updated_at: string
}

export interface role_permissions {
  created_at: string | null
  id: string
  permission_id: string
  role_id: string
  updated_at: string | null
}

export interface role_users {
  created_at: string | null
  id: string
  role_id: string
  updated_at: string | null
  user_id: string
}

export interface roles {
  created_at: string | null
  description: string | null
  id: string
  name: string
  updated_at: string | null
}

export interface star_candy_bonus_history {
  amount: number | null
  created_at: string
  deleted_at: string | null
  expired_dt: string | null
  id: number
  parent_id: number | null
  remain_amount: number
  transaction_id: string | null
  type: CandyHistoryType | null
  updated_at: string
  user_id: string
  vote_pick_id: number | null
}

export interface star_candy_history {
  amount: number | null
  created_at: string
  deleted_at: string | null
  id: number
  parent_id: number | null
  transaction_id: string | null
  type: CandyHistoryType | null
  updated_at: string
  user_id: string
  vote_pick_id: number | null
}

export interface transaction_admob {
  ad_network: string | null
  created_at: string
  deleted_at: string | null
  key_id: string | null
  reward_amount: number | null
  reward_type: string | null
  signature: string | null
  transaction_id: string
  updated_at: string
  user_id: string | null
}

export interface transaction_pangle {
  ad_network: string | null
  created_at: string
  deleted_at: string | null
  key_id: string | null
  platform: string | null
  reward_amount: number | null
  reward_name: string | null
  reward_type: string | null
  signature: string | null
  transaction_id: string
  updated_at: string
  user_id: string | null
}

export interface transaction_pincrux {
  ad_network: string | null
  app_key: string | null
  app_title: string | null
  commission: number | null
  created_at: string
  deleted_at: string | null
  menu_category1: string | null
  pub_key: number | null
  reward_amount: number | null
  reward_type: string | null
  signature: string | null
  transaction_id: string
  updated_at: string
  usr_key: string | null
}

export interface transaction_tapjoy {
  created_at: string
  id: number
  platform: string | null
  reward_amount: number
  reward_type: string | null
  transaction_id: string
  user_id: string
  verifier: string | null
}

export interface transaction_unity {
  ad_network: string | null
  created_at: string
  deleted_at: string | null
  hmac: string
  reward_amount: number | null
  reward_type: string | null
  transaction_id: string
  updated_at: string
  user_id: string
}

export interface user_agreement {
  created_at: string | null
  deleted_at: string | null
  id: string
  privacy: string | null
  terms: string | null
  updated_at: string | null
}

export interface user_blocks {
  blocked_user_id: string
  created_at: string
  deleted_at: string | null
  id: string
  user_id: string
}

export interface user_comment_like {
  comment_id: number | null
  created_at: string | null
  deleted_at: string | null
  id: number | null
  updated_at: string | null
  user_id: number | null
}

export interface user_comment_report {
  comment_id: number | null
  created_at: string | null
  deleted_at: string | null
  id: number | null
  updated_at: string | null
  user_id: number | null
}

export interface user_profiles {
  avatar_url: string | null
  birth_date: string | null
  birth_time: string | null
  created_at: string
  deleted_at: string | null
  email: string | null
  gender: UserGenderEnum | null
  id: string
  is_admin: boolean
  nickname: string | null
  open_ages: boolean
  open_gender: boolean
  star_candy: number
  star_candy_bonus: number
  updated_at: string
}

export interface user_roles {
  created_at: string | null
  id: string
  role_id: string
  updated_at: string | null
  user_id: string
}

export interface version {
  android: Json | null
  created_at: string
  deleted_at: string | null
  id: number
  ios: Json | null
  linux: Json | null
  macos: Json | null
  updated_at: string
  windows: Json | null
}

export interface vote {
  created_at: string
  deleted_at: string | null
  id: number
  main_image: string | null
  order: number | null
  result_image: string | null
  start_at: string | null
  stop_at: string | null
  title: Json | null
  updated_at: string
  visible_at: string | null
  vote_category: string | null
  vote_content: string | null
  vote_sub_category: string | null
  wait_image: string | null
}

export interface vote_achieve {
  amount: number | null
  id: number | null
  order: number | null
  reward_id: number | null
  vote_id: number | null
}

export interface vote_comment {
  childrencount: number | null
  content: string | null
  created_at: string | null
  deleted_at: string | null
  id: number | null
  likes: number | null
  parent_id: number | null
  updated_at: string | null
  user_id: number | null
  vote_id: number | null
}

export interface vote_comment_like {
  comment_id: number | null
  user_id: number | null
}

export interface vote_comment_report {
  comment_id: number | null
  user_id: number | null
}

export interface vote_item {
  artist_id: number | null
  created_at: string | null
  deleted_at: string | null
  group_id: number | null
  id: number
  updated_at: string | null
  vote_id: number | null
  vote_total: number | null
}

export interface vote_pick {
  amount: number | null
  created_at: string | null
  deleted_at: string | null
  id: number
  updated_at: string | null
  user_id: string | null
  vote_id: number | null
  vote_item_id: number
}

export interface vote_reward {
  reward_id: number
  vote_id: number
}

export interface vote_share_bonus {
  amount: number
  created_at: string
  id: number
  updated_at: string
  user_id: string
  vote_id: number
}