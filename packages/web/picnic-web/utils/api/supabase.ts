import { createClient } from '@supabase/supabase-js'

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || ''
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || ''

// Supabase 클라이언트 생성
export const supabase = createClient(supabaseUrl, supabaseAnonKey, {
  auth: {
    autoRefreshToken: true,
    persistSession: true,
  },
})

// 로그인 상태 확인 
export const isUserLoggedIn = async () => {
  const { data: { session } } = await supabase.auth.getSession()
  return !!session
}

// 사용자 정보 가져오기
export const getCurrentUser = async () => {
  const { data: { user } } = await supabase.auth.getUser()
  return user
}

// 사용자 프로필 정보 가져오기
export const getUserProfile = async (userId: string) => {
  const { data, error } = await supabase
    .from('user_profiles')
    .select('*')
    .eq('id', userId)
    .single()
  
  if (error) throw error
  return data
}

// 스토리지 URL 생성
export const getStorageUrl = (bucket: string, path: string) => {
  return `${supabaseUrl}/storage/v1/object/public/${bucket}/${path}`
}

// 이미지 URL 생성 (CDN 사용)
export const getCdnUrl = (path: string) => {
  const cdnUrl = process.env.NEXT_PUBLIC_CDN_URL || ''
  return `${cdnUrl}/${path}`
}

// 파일 업로드
export const uploadFile = async (bucket: string, path: string, file: File) => {
  const { data, error } = await supabase.storage
    .from(bucket)
    .upload(path, file, {
      upsert: true,
      cacheControl: '3600'
    })
  
  if (error) throw error
  return data
} 