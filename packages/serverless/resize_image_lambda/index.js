const { S3Client, GetObjectCommand, PutObjectCommand } = require("@aws-sdk/client-s3");
const sharp = require("sharp");
const querystring = require("querystring");
const path = require("path");

const s3Client = new S3Client();

exports.handler = async (event) => {
  console.log('Lambda function invoked');
  console.log('Full event object:', JSON.stringify(event, null, 2));

  const { request, response } = event.Records[0].cf;
  const { uri, querystring: qs } = request;

  console.log('Request details:');
  console.log('  Method:', request.method);
  console.log('  URI:', uri);
  console.log('  QueryString:', qs);

  // Parse query parameters
  const params = querystring.parse(qs);

  const width = params.w ? parseInt(params.w, 10) : null;
  const height = params.h ? parseInt(params.h, 10) : null;
  const format = params.f ? params.f.toLowerCase() : null;
  const quality = params.q ? parseInt(params.q, 10) : 80;

  // If no transformation is requested, return the original image
  if (!width && !height && !format && !params.q) {
    console.log('No transformation requested, returning original response');
    return response;
  }

  const bucket = "picnic-prod-cdn";
  const originalKey = uri.startsWith('/') ? uri.slice(1) : uri;
  const parsedPath = path.parse(originalKey);
  const transformedKey = `cache/${parsedPath.dir}/${parsedPath.name}_w${width || 'auto'}_h${height || 'auto'}_f${format || 'original'}_q${quality}${parsedPath.ext}`;

  console.log('Original Key:', originalKey);
  console.log('Transformed Key:', transformedKey);

  try {
    console.log('Fetching original image');
    let originalImage;
    try {
      originalImage = await s3Client.send(new GetObjectCommand({
        Bucket: bucket,
        Key: originalKey
      }));
    } catch (error) {
      console.error('Error fetching original image:', error);
      if (error.name === "NoSuchKey") {
        console.error(`Original image not found: ${originalKey}`);
        response.status = "404";
        response.statusDescription = "Not Found";
        return response;
      }
      throw error;
    }

    if (!originalImage || !originalImage.Body) {
      throw new Error('Failed to retrieve original image data');
    }

    console.log('Processing image');
    let processedImage = sharp(await originalImage.Body.transformToByteArray());

    if (width || height) {
      processedImage = processedImage.resize(width, height, {
        fit: "inside",
        withoutEnlargement: true
      });
    }

    const metadata = await processedImage.metadata();
    const outputFormat = format || metadata.format;

    if (outputFormat === 'jpeg' || outputFormat === 'webp' || outputFormat === 'png') {
      processedImage = processedImage[outputFormat]({ quality });
    } else if (outputFormat === 'gif') {
      processedImage = processedImage.gif();
    } else {
      // For unsupported formats, default to JPEG
      processedImage = processedImage.jpeg({ quality });
    }

    console.log('Generating buffer from processed image');
    const resizedImageBuffer = await processedImage.toBuffer();

    console.log('Uploading processed image to S3');
    await s3Client.send(new PutObjectCommand({
      Bucket: bucket,
      Key: transformedKey,
      Body: resizedImageBuffer,
      ContentType: `image/${outputFormat}`
    }));

    console.log('Redirecting to processed image');
    response.status = "302";
    response.statusDescription = "Found";
    const finalRedirectUrl = `/${transformedKey}`;
    console.log('Final Redirect URL:', finalRedirectUrl);
    response.headers["location"] = [{ key: "Location", value: finalRedirectUrl }];
    return response;

  } catch (error) {
    console.error("Error processing image:", error);
    console.error("Error stack:", error.stack);
    response.status = "500";
    response.statusDescription = "Internal Server Error";
    response.body = "An error occurred while processing the image.";
    return response;
  }
};