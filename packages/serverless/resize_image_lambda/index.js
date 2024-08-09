const { S3Client, GetObjectCommand, PutObjectCommand } = require("@aws-sdk/client-s3");
const sharp = require("sharp");
const querystring = require("querystring");

const s3Client = new S3Client();

exports.handler = async (event) => {
  console.log('Event:', JSON.stringify(event));

  const { request, response } = event.Records[0].cf;
  const { uri, querystring: qs } = request;

  console.log('Processing URI:', uri);
  console.log('Query String:', qs);

  // Parse query parameters
  const params = querystring.parse(qs);

  const width = params.w ? parseInt(params.w, 10) : null;
  const height = params.h ? parseInt(params.h, 10) : null;
  const format = params.f ? params.f.toLowerCase() : null;
  const quality = params.q ? parseInt(params.q, 10) : 80;

  // If no transformation is requested, return the original image
  if (!width && !height && !format) {
    console.log('No transformation requested, returning original response');
    return response;
  }

  const bucket = "picnic-prod-cdn";
  const originalKey = uri.slice(1); // Remove leading '/'
  const transformedKey = `cache/${originalKey.replace(/\//g, '_')}_w${width || 'auto'}_h${height || 'auto'}_f${format || 'original'}_q${quality}`;

  console.log('Original Key:', originalKey);
  console.log('Transformed Key:', transformedKey);

  try {
    console.log('Checking if transformed image exists');
    try {
      await s3Client.send(new GetObjectCommand({ Bucket: bucket, Key: transformedKey }));
      console.log('Transformed image found, redirecting');
      response.status = "302";
      response.statusDescription = "Found";
      response.headers["location"] = [{ key: "Location", value: `/${transformedKey}` }];
      return response;
    } catch (error) {
      if (error.name !== "NoSuchKey") throw error;
      console.log('Transformed image not found, proceeding with transformation');
    }

    console.log('Fetching original image');
    let originalImage;
    try {
      originalImage = await s3Client.send(new GetObjectCommand({
        Bucket: bucket,
        Key: originalKey
      }));
    } catch (error) {
      if (error.name === "NoSuchKey") {
        console.error(`Original image not found: ${originalKey}`);
        response.status = "404";
        response.statusDescription = "Not Found";
        return response;
      }
      throw error;
    }

    console.log('Processing image');
    let processedImage = sharp(await originalImage.Body.transformToByteArray());

    if (width || height) {
      processedImage = processedImage.resize(width, height, {
        fit: "inside",
        withoutEnlargement: true
      });
    }

    if (format) {
      console.log(`Applying format conversion to ${format}`);
      processedImage = processedImage[format]({ quality });
    } else {
      // If no format is specified, maintain original format but apply quality
      const metadata = await processedImage.metadata();
      if (['jpeg', 'webp', 'png'].includes(metadata.format)) {
        processedImage = processedImage[metadata.format]({ quality });
      }
    }

    console.log('Generating buffer from processed image');
    const resizedImageBuffer = await processedImage.toBuffer();

    console.log('Uploading processed image to S3');
    await s3Client.send(new PutObjectCommand({
      Bucket: bucket,
      Key: transformedKey,
      Body: resizedImageBuffer,
      ContentType: format ? `image/${format}` : originalImage.ContentType
    }));

    console.log('Redirecting to processed image');
    response.status = "302";
    response.statusDescription = "Found";
    response.headers["location"] = [{ key: "Location", value: `/${transformedKey}` }];
    return response;

  } catch (error) {
    console.error("Error processing image:", error);
    console.error("Error stack:", error.stack);
    response.status = "500";
    response.statusDescription = "Internal Server Error";
    return response;
  }
};