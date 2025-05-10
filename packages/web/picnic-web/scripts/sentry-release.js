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
execSync(`sentry-cli releases set-commits ${release} --auto`, { stdio: "inherit" });
execSync(
  `sentry-cli releases files ${release} upload-sourcemaps .next --url-prefix '~/_next' --rewrite`,
  { stdio: "inherit" }
);
execSync(`sentry-cli releases finalize ${release}`, { stdio: "inherit" });