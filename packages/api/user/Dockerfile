FROM --platform=linux/arm64 node:20-alpine

ENV TZ Asia/Seoul
RUN	apk update && apk upgrade && \
    apk add --no-cache curl && \
	apk add --update tzdata && \
	cp /usr/share/zoneinfo/${TZ} /etc/localtime && \
	echo "${TZ}" > /etc/timezone \
    apk add --no-cache qemu-user-static && \
    apk add --no-cache libc6-compat


WORKDIR /usr/src/app

COPY . .

EXPOSE 7100
