const { S3Client, GetObjectCommand, PutObjectCommand } = require("@aws-sdk/client-s3");
const sharp = require("sharp");
const querystring = require("querystring");
const path = require("path");

const s3Client = new S3Client({
    region: 'ap-northeast-2',
    endpoint: 'https://s3.ap-northeast-2.amazonaws.com'
});

const CONFIG = {
    BUCKET: "picnic-prod-cdn",
    DEFAULT_QUALITY: 80,
    SUPPORTED_FORMATS: ['jpeg', 'webp', 'png', 'gif'],
};

const logger = {
    log: (message, data) => console.log(message, JSON.stringify(data, null, 2)),
    error: (message, error) => {
        console.error(message);
        console.error("Error name:", error.name);
        console.error("Error message:", error.message);
        console.error("Error stack:", error.stack);
        if (error.code) console.error("Error code:", error.code);
        if (error.$metadata) console.error("Error metadata:", JSON.stringify(error.$metadata));
        if (error.context) console.error("Error context:", JSON.stringify(error.context));
    }
};

const parseQueryParams = (qs) => {
    const params = querystring.parse(qs);
    return {
        width: params.w ? parseInt(params.w, 10) : null,
        height: params.h ? parseInt(params.h, 10) : null,
        format: params.f ? params.f.toLowerCase() : null,
        quality: params.q ? parseInt(params.q, 10) : CONFIG.DEFAULT_QUALITY,
    };
};

const fetchOriginalImage = async (key) => {
    try {
        const originalImage = await s3Client.send(new GetObjectCommand({
            Bucket: CONFIG.BUCKET,
            Key: key
        }));
        if (!originalImage || !originalImage.Body) {
            throw new Error('Failed to retrieve original image data');
        }
        return originalImage;
    } catch (error) {
        if (error.name === "NoSuchKey") {
            logger.error(`Original image not found: ${key}`, error);
            const notFoundError = new Error('Image not found');
            notFoundError.statusCode = 404;
            throw notFoundError;
        }
        throw error;
    }
};

const isAnimatedGif = async (imageBuffer) => {
    try {
        const metadata = await sharp(imageBuffer).metadata();
        // GIF이고 페이지(프레임)가 1개 이상인 경우 애니메이션 GIF로 판단
        return metadata.format === 'gif' && metadata.pages > 1;
    } catch (error) {
        logger.error("Error checking if image is animated GIF:", error);
        return false;
    }
};

const processImage = async (originalImage, { width, height, format, quality }) => {
    const imageBuffer = await originalImage.Body.transformToByteArray();
    const metadata = await sharp(imageBuffer).metadata();
    let processedImage;
    let outputFormat = format || metadata.format;

    // 애니메이션 GIF 체크
    const isAnimated = await isAnimatedGif(imageBuffer);

    if (isAnimated) {
        logger.log('Animated GIF detected, preserving original format');
        // 애니메이션 GIF는 원본 포맷 유지 (webp 변환 건너뛰기)
        processedImage = sharp(imageBuffer, { animated: true });
        outputFormat = 'gif';

        if (width || height) {
            processedImage = processedImage.resize(width, height, {
                fit: "inside",
                withoutEnlargement: true
            });
        }
    } else {
        // 일반 이미지 처리 (정적 GIF 포함)
        processedImage = sharp(imageBuffer);
        if (width || height) {
            processedImage = processedImage.resize(width, height, {
                fit: "inside",
                withoutEnlargement: true
            });
        }

        if (CONFIG.SUPPORTED_FORMATS.includes(outputFormat)) {
            processedImage = processedImage[outputFormat]({ quality });
        } else {
            processedImage = processedImage.toFormat(metadata.format);
            outputFormat = metadata.format;
        }
    }

    return { processedImage, outputFormat };
};

const uploadProcessedImage = async (processedImage, key, outputFormat) => {
    const resizedImageBuffer = await processedImage.toBuffer();
    await s3Client.send(new PutObjectCommand({
        Bucket: CONFIG.BUCKET,
        Key: key,
        Body: resizedImageBuffer,
        ContentType: `image/${outputFormat}`
    }));
};

const generateTransformedKey = (originalKey, { width, height, format, quality }) => {
    const parsedPath = path.parse(originalKey);
    return `cache/${parsedPath.dir}/${parsedPath.name}_w${width || 'auto'}_h${height || 'auto'}_f${format}_q${quality}.${format}`;
};

exports.handler = async (event) => {
    logger.log('Lambda function invoked', { event });

    const { request, response } = event.Records[0].cf;
    const { uri, querystring: qs } = request;

    logger.log('Request details', { method: request.method, uri, qs });

    const params = parseQueryParams(qs);

    if (!params.width && !params.height && !params.format && !params.quality) {
        logger.log('No transformation requested, returning original response');
        return response;
    }

    const originalKey = uri.startsWith('/') ? uri.slice(1) : uri;

    try {
        const originalImage = await fetchOriginalImage(originalKey);
        const { processedImage, outputFormat } = await processImage(originalImage, params);
        const transformedKey = generateTransformedKey(originalKey, { ...params, format: outputFormat });

        await uploadProcessedImage(processedImage, transformedKey, outputFormat);

        logger.log('Redirecting to processed image', { transformedKey });
        response.status = "302";
        response.statusDescription = "Found";
        response.headers["location"] = [{ key: "Location", value: `/${transformedKey}` }];
        return response;

    } catch (error) {
        logger.error("Error processing image:", error);
        logger.log('Error details', { uri, qs, params, originalKey });

        if (error.statusCode === 404) {
            response.status = "404";
            response.statusDescription = "Not Found";
            return response;
        }

        // Fallback to original image for other errors
        logger.log('Error occurred, falling back to original image');
        return response;
    }
};
