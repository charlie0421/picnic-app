const { S3Client, GetObjectCommand, PutObjectCommand } = require("@aws-sdk/client-s3");
const sharp = require("sharp");
const querystring = require("querystring");
const path = require("path");

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

const s3Client = new S3Client({
    region: 'ap-northeast-2',
    endpoint: 'https://s3.ap-northeast-2.amazonaws.com'
});

const CONFIG = {
    BUCKETS: {
        'picnic': {
            source: 'picnic-prod-cdn',
            destination: 'picnic-prod-cdn'
        },
        'ttja': {
            source: 'ttja-prod-cdn',
            destination: 'ttja-prod-cdn'
        }
    },
    DEFAULT_SERVICE: 'picnic',
    DEFAULT_QUALITY: 80,
    SUPPORTED_FORMATS: ['jpeg', 'webp', 'png', 'gif'],
    MAX_BUFFER_SIZE: 50 * 1024 * 1024
};

const getBucketForRequest = (uri) => {
    let service = CONFIG.DEFAULT_SERVICE;
    let pathPrefix = '/picnic/';

    const pathParts = uri.split('/').filter(Boolean);
    if (pathParts.length > 0) {
        const firstPart = pathParts[0];
        if (CONFIG.BUCKETS[firstPart]) {
            service = firstPart;
            pathPrefix = `/${firstPart}/`;
        }
    }

    return {
        source: CONFIG.BUCKETS[service].source,
        destination: CONFIG.BUCKETS[service].destination,
        pathPrefix: pathPrefix,
        service: service
    };
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

const fetchOriginalImage = async (key, bucket) => {
    try {
        const command = new GetObjectCommand({
            Bucket: bucket,
            Key: key
        });
        const originalImage = await s3Client.send(command);

        if (!originalImage || !originalImage.Body) {
            throw new Error('Failed to retrieve original image data');
        }

        const contentLength = originalImage.ContentLength;
        if (contentLength > CONFIG.MAX_BUFFER_SIZE) {
            throw new Error(`Image size ${contentLength} bytes exceeds maximum allowed size of ${CONFIG.MAX_BUFFER_SIZE} bytes`);
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

const processImage = async (imageBuffer, { width, height, format, quality }) => {
    try {
        const metadata = await sharp(imageBuffer).metadata();
        let processedImage = sharp(imageBuffer, {
            failOnError: false,
            density: 300
        });
        let outputFormat = format || metadata.format;

        if (width || height) {
            processedImage = processedImage.resize(width, height, {
                fit: "inside",
                withoutEnlargement: true
            });
        }

        if (CONFIG.SUPPORTED_FORMATS.includes(outputFormat)) {
            processedImage = processedImage[outputFormat]({
                quality,
                progressive: true,
                optimizeScans: true
            });
        } else {
            processedImage = processedImage.toFormat(metadata.format, {
                quality,
                progressive: true,
                optimizeScans: true
            });
            outputFormat = metadata.format;
        }

        return { processedImage, outputFormat };
    } catch (error) {
        logger.error("Error in image processing:", error);
        throw new Error(`Image processing failed: ${error.message}`);
    }
};

const generateTransformedKey = (originalKey, { width, height, format, quality }) => {
    const parsedPath = path.parse(originalKey);
    const extension = format || parsedPath.ext.slice(1);

    if (extension === 'gif') {
        return `cache/${originalKey}`;
    }

    return `cache/${parsedPath.dir}/${parsedPath.name}_w${width || 'auto'}_h${height || 'auto'}_f${extension}_q${quality}.${extension}`;
};

const uploadProcessedImage = async (processedImage, key, outputFormat, bucket) => {
    try {
        const resizedImageBuffer = await processedImage.toBuffer();

        if (resizedImageBuffer.length > CONFIG.MAX_BUFFER_SIZE) {
            throw new Error(`Processed image size ${resizedImageBuffer.length} bytes exceeds maximum allowed size of ${CONFIG.MAX_BUFFER_SIZE} bytes`);
        }

        await s3Client.send(new PutObjectCommand({
            Bucket: bucket,
            Key: key,
            Body: resizedImageBuffer,
            ContentType: `image/${outputFormat}`,
            CacheControl: 'max-age=31536000'
        }));
    } catch (error) {
        logger.error("Error uploading processed image:", error);
        throw error;
    }
};

exports.handler = async (event) => {
    logger.log('Lambda function invoked', { event });

    if (!event.Records?.[0]?.cf) {
        throw new Error('Invalid event structure');
    }

    const request = event.Records[0].cf.request;
    const { uri, querystring: qs } = request;

    const defaultResponse = {
        status: "200",
        statusDescription: "OK",
        headers: {},
    };

    try {
        const bucketConfig = getBucketForRequest(uri);

        // 서비스 prefix를 제거하고 실제 이미지 경로 추출
        let originalKey = uri;
        if (uri.startsWith(bucketConfig.pathPrefix)) {
            originalKey = uri.slice(bucketConfig.pathPrefix.length);
        } else if (uri.startsWith('/')) {
            originalKey = uri.slice(1);
        }

        const originalImage = await fetchOriginalImage(originalKey, bucketConfig.source);
        const imageBuffer = await originalImage.Body.transformToByteArray();

        // GIF 체크
        const isGif = imageBuffer.toString('ascii', 0, 3) === 'GIF';
        if (isGif) {
            const transformedKey = `cache/${originalKey}`;

            await s3Client.send(new PutObjectCommand({
                Bucket: bucketConfig.destination,
                Key: transformedKey,
                Body: imageBuffer,
                ContentType: 'image/gif',
                CacheControl: 'max-age=31536000',
                ...originalImage.Metadata
            }));

            return {
                status: "302",
                statusDescription: "Found",
                headers: {
                    location: [{
                        key: "Location",
                        value: `${bucketConfig.pathPrefix}${transformedKey}`
                    }]
                }
            };
        }

        const params = parseQueryParams(qs);
        if (!params.width && !params.height && !params.format && !params.quality) {
            logger.log('No transformation requested, returning original response');
            return defaultResponse;
        }

        const { processedImage, outputFormat } = await processImage(imageBuffer, params);
        const transformedKey = generateTransformedKey(originalKey, {
            ...params,
            format: outputFormat
        });

        await uploadProcessedImage(processedImage, transformedKey, outputFormat, bucketConfig.destination);

        logger.log('Redirecting to processed image', { transformedKey });
        return {
            status: "302",
            statusDescription: "Found",
            headers: {
                location: [{
                    key: "Location",
                    value: `${bucketConfig.pathPrefix}${transformedKey}`
                }]
            }
        };

    } catch (error) {
        logger.error("Error processing image:", error);

        if (error.statusCode === 404) {
            return {
                status: "404",
                statusDescription: "Not Found",
                headers: defaultResponse.headers
            };
        }

        if (error.message.includes('Image processing failed')) {
            return {
                status: "502",
                statusDescription: "Bad Gateway",
                headers: defaultResponse.headers
            };
        }

        logger.log('Error occurred, falling back to original image');
        return defaultResponse;
    }
};
