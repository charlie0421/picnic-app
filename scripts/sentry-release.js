require('dotenv').config({ path: '.env.local' }); // ✅ 여기가 핵심

const { execSync } = require("child_process");
const pkg = require("../package.json");

const sha =
  process.env.VERCEL_GIT_COMMIT_SHA ||
  execSync("git rev-parse --short HEAD").toString().trim();

const date = new Date().toISOString().split("T")[0];
const release = `${pkg.name}@${pkg.version}-${date}-${sha}`;

console.log(`📦 Sentry Release: ${release}`);
console.log("SENTRY_AUTH_TOKEN:", process.env.SENTRY_AUTH_TOKEN); // 이 줄 추가

execSync(`sentry-cli releases new ${release}`, { stdio: "inherit" });

const repo = process.env.VERCEL_GIT_REPO_OWNER && process.env.VERCEL_GIT_REPO_SLUG
  ? `${process.env.VERCEL_GIT_REPO_OWNER}/${process.env.VERCEL_GIT_REPO_SLUG}`
  : null;

if (repo && process.env.VERCEL_GIT_COMMIT_SHA) {
  execSync(`sentry-cli releases set-commits ${release} --commit \"${repo}@${sha}\"`, { stdio: "inherit" });
} else {
  try {
    execSync(`sentry-cli releases set-commits ${release} --auto`, { stdio: "inherit" });
  } catch (e) {
    console.warn('set-commits 실패: git 저장소가 없을 수 있습니다. 무시하고 계속 진행합니다.');
  }
}

execSync(
  `sentry-cli releases files ${release} upload-sourcemaps .next --url-prefix '~/_next' --rewrite`,
  { stdio: "inherit" }
);
execSync(`sentry-cli releases finalize ${release}`, { stdio: "inherit" });