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

// imageBuffer를 직접 받도록 수정
const processImage = async (imageBuffer, { width, height, format, quality }) => {
    const metadata = await sharp(imageBuffer).metadata();
    let processedImage;
    let outputFormat = format || metadata.format;

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

    return { processedImage, outputFormat };
};

// GIF 애니메이션 체크 함수는 동일
const isAnimatedGif = (buffer) => {
    if (buffer.length < 3 || buffer.toString('ascii', 0, 3) !== 'GIF') {
        return false;
    }

    let pos = 13;
    let frames = 0;

    try {
        const packedField = buffer[10];
        const globalColorTableSize = packedField & 0x07;
        if (packedField & 0x80) {
            pos += 3 * Math.pow(2, globalColorTableSize + 1);
        }

        while (pos < buffer.length) {
            const blockType = buffer[pos];

            if (blockType === 0x2C) {
                frames++;

                const localPackedField = buffer[pos + 9];
                if (localPackedField & 0x80) {
                    const localColorTableSize = localPackedField & 0x07;
                    pos += 3 * Math.pow(2, localColorTableSize + 1);
                }

                pos += 11;
                pos++;

                while (pos < buffer.length) {
                    const subBlockSize = buffer[pos];
                    if (subBlockSize === 0) break;
                    pos += subBlockSize + 1;
                }
            }
            else if (blockType === 0x21 && buffer[pos + 1] === 0xF9) {
                pos += 8;
            }
            else if (blockType === 0x21 && buffer[pos + 1] === 0xFF) {
                pos += 19;
            }
            else if (blockType === 0x21 && buffer[pos + 1] === 0xFE) {
                pos += 2;
                while (pos < buffer.length) {
                    const subBlockSize = buffer[pos];
                    if (subBlockSize === 0) break;
                    pos += subBlockSize + 1;
                }
                pos++;
            }
            else if (blockType === 0x3B) {
                break;
            }

            pos++;
        }

        return frames > 1;
    } catch (error) {
        logger.error("Error analyzing GIF structure:", error);
        return false;
    }
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
    const extension = format || parsedPath.ext.slice(1);

    // 애니메이션 GIF인 경우 원본 키 경로에 cache 접두사만 추가
    if (extension === 'gif') {
        return `cache/${originalKey}`;
    }

    // 일반 이미지의 경우 기존 변환 키 생성 로직 사용
    return `cache/${parsedPath.dir}/${parsedPath.name}_w${width || 'auto'}_h${height || 'auto'}_f${extension}_q${quality}.${extension}`;
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
        // Stream을 한 번만 변환
        const imageBuffer = await originalImage.Body.transformToByteArray();

        // GIF 파일인지 먼저 확인
        const isGif = imageBuffer.toString('ascii', 0, 3) === 'GIF';

        if (isGif) {
            // 애니메이션 GIF인지 확인
            const isAnimated = isAnimatedGif(imageBuffer);
            if (isAnimated) {
                logger.log('Animated GIF detected, returning original image', { key: originalKey });
                return response;
            }
        }

        // 일반 이미지나 정적 GIF 처리
        const { processedImage, outputFormat } = await processImage(imageBuffer, params);
        const transformedKey = generateTransformedKey(originalKey, {
            ...params,
            format: outputFormat
        });

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

        logger.log('Error occurred, falling back to original image');
        return response;
    }
};
