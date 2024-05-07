FROM --platform=linux/arm64 node:16-alpine

ENV TZ Asia/Seoul
RUN	apk update && apk upgrade && \
    apk add --no-cache curl && \
	apk add --update tzdata && \
	cp /usr/share/zoneinfo/${TZ} /etc/localtime && \
	echo "${TZ}" > /etc/timezone

RUN yarn set version 4.2.1

WORKDIR /usr/src/app

COPY . .

EXPOSE 7100
