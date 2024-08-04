const sharp = require('sharp');
const AWS = require('aws-sdk');
const { createClient } = require('@supabase/supabase-js');
const s3 = new AWS.S3({
  accessKeyId: process.env.AWS_ACCESS_KEY_ID,
  secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
  region: process.env.AWS_REGION
});
const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_SERVICE_KEY;
const supabase = createClient(supabaseUrl, supabaseKey);
exports.handler = async (event, context)=>{
  const { bucket, key, width, height, format, quality } = JSON.parse(event.body);
  try {
    const s3Params = {
      Bucket: bucket,
      Key: key
    };
    const s3Object = await s3.getObject(s3Params).promise();
    const imageBuffer = s3Object.Body;
    let image = sharp(imageBuffer).resize(parseInt(width), parseInt(height));
    if (format) {
      image = image.toFormat(format, {
        quality: parseInt(quality) || 80
      });
    }
    const resizedImageBuffer = await image.toBuffer();
    const resizedKey = `${key.split('.')[0]}-${width}x${height}.${format || 'jpg'}`;
    const uploadParams = {
      Bucket: bucket,
      Key: resizedKey,
      Body: resizedImageBuffer,
      ContentType: `image/${format || 'jpeg'}`
    };
    await s3.upload(uploadParams).promise();
    const cloudFrontUrl = `https://d2eeeaspe3yjlb.cloudfront.net/${resizedKey}`;
    return {
      statusCode: 200,
      body: JSON.stringify({
        url: cloudFrontUrl
      })
    };
  } catch (error) {
    console.error(error);
    return {
      statusCode: 500,
      body: JSON.stringify({
        error: error.message
      })
    };
  }
};
