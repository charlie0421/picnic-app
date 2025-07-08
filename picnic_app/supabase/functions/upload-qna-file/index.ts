import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { S3Client, PutObjectCommand } from "https://esm.sh/@aws-sdk/client-s3@3.x"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // AWS S3 설정
    const s3Client = new S3Client({
      region: 'ap-northeast-2',
      credentials: {
        accessKeyId: Deno.env.get('AWS_ACCESS_KEY_ID')!,
        secretAccessKey: Deno.env.get('AWS_SECRET_ACCESS_KEY')!,
      },
    })

    const bucketName = 'picnic-dev-cdn' // 또는 환경변수로 설정
    
    // 요청에서 파일 데이터 추출
    const formData = await req.formData()
    const file = formData.get('file') as File
    const userId = formData.get('userId') as string
    
    if (!file) {
      return new Response(
        JSON.stringify({ error: 'No file provided' }),
        { 
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    if (!userId) {
      return new Response(
        JSON.stringify({ error: 'User ID required' }),
        { 
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    // 파일 확장자 확인 (이미지 및 일반 문서만 허용)
    const allowedExtensions = ['jpg', 'jpeg', 'png', 'gif', 'pdf', 'doc', 'docx', 'txt']
    const fileExtension = file.name.split('.').pop()?.toLowerCase()
    
    if (!fileExtension || !allowedExtensions.includes(fileExtension)) {
      return new Response(
        JSON.stringify({ 
          error: 'Invalid file type. Allowed: ' + allowedExtensions.join(', ')
        }),
        { 
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    // 파일 크기 확인 (10MB 제한)
    if (file.size > 10 * 1024 * 1024) {
      return new Response(
        JSON.stringify({ error: 'File size too large. Maximum 10MB allowed.' }),
        { 
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    // 고유한 파일명 생성
    const timestamp = Date.now()
    const randomStr = Math.random().toString(36).substring(2, 15)
    const fileName = `qna/${userId}/${timestamp}_${randomStr}.${fileExtension}`

    // 파일을 ArrayBuffer로 변환
    const fileBuffer = await file.arrayBuffer()

    // S3에 업로드
    const uploadCommand = new PutObjectCommand({
      Bucket: bucketName,
      Key: fileName,
      Body: new Uint8Array(fileBuffer),
      ContentType: file.type,
      Metadata: {
        'original-name': file.name,
        'user-id': userId,
        'upload-time': new Date().toISOString(),
      },
    })

    await s3Client.send(uploadCommand)

    // 업로드된 파일의 URL 생성
    const fileUrl = `https://${bucketName}.s3.ap-northeast-2.amazonaws.com/${fileName}`

    return new Response(
      JSON.stringify({
        success: true,
        url: fileUrl,
        originalName: file.name,
        size: file.size,
        type: file.type,
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    )

  } catch (error) {
    console.error('File upload error:', error)
    return new Response(
      JSON.stringify({ 
        error: 'Internal server error',
        message: error.message 
      }),
      { 
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )
  }
}) 