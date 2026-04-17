#!/bin/bash

# [핵심 교정]: 어떤 경로에서 실행하든 프로젝트 루트로 강제 이동
SITE_DIR="/home/ubuntu/k_life/site"
cd "$SITE_DIR" || { echo "❌ Directory not found"; exit 1; }

echo "🚀 Starting Clean Deployment Process in $(pwd)..."

# [v85.1 Editor's Patch]: 빌드 전 리소스 캐시 강제 삭제
echo "🧹 Clearing Hugo resource cache..."
rm -rf resources/_gen

# 1. 빌드 성공 여부 사전 체크
# [교정]: 특정 경로(/snap/bin/...)에 의존하지 않고 시스템 PATH의 hugo를 호출합니다.
if ! HUGO_ENV=production hugo --gc --minify --cleanDestinationDir; then
    echo "❌ [ERROR] Hugo build failed! Deployment aborted to save your files."
    exit 1
fi

# 2. CNAME 복구
echo "klifehack.com" > docs/CNAME

echo "📦 Preparing for GitHub push..."

# 3. GitHub 전송 준비 및 동기화 (CRITICAL)
# [v94.1 추가]: 푸시 전 원격의 변경사항을 먼저 가져와 충돌을 방지합니다.
git pull --rebase origin main

git add .
# 변경사항이 없을 때 에러로 멈추지 않게 처리
git commit -m "Update site content: $(date +'%Y-%m-%d %H:%M:%S')" || echo "[-] No changes to commit."

# 4. GitHub으로 안전하게 푸시
# [교정]: 강제 푸시(-f)는 데이터 유실 위험이 크므로 일반 push를 권장합니다.
echo "📤 Pushing to GitHub..."
if git push origin main; then
    echo "✅ Deployment Complete! Your updates are now live."
else
    echo "❌ [ERROR] Git push failed. Checking for remote conflicts..."
    # 마지막 수단으로 한 번 더 리베이스 후 재시도
    git pull --rebase origin main
    git push origin main
fi