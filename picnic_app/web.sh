#!/bin/bash

set -e

ENV=$1
TARGET_DIR="custom_build/web"

if [ "$ENV" == "prod" ]; then
  echo "Production build"
  flutter build web
elif [ "$ENV" == "dev" ]; then
  echo "Development build"
  flutter build web
else
  echo "Please specify the environment: dev or prod"
  exit 1
fi

# 빌드 결과물을 custom_build/web 디렉터리로 이동
mkdir -p $TARGET_DIR
rm -rf $TARGET_DIR/*
cp -r build/web/* $TARGET_DIR/

# Vercel 배포
if [ "$ENV" == "prod" ]; then
  echo "Production deploy"
  vercel --prod --cwd custom_build/web
elif [ "$ENV" == "dev" ]; then
  echo "Development deploy"
  vercel --cwd $TARGET_DIR
fi