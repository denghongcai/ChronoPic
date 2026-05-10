#!/usr/bin/env node
import fs from 'node:fs';
import path from 'node:path';

const outDir = process.argv[2];
const expectedPhotoCount = Number(process.env.EXPECTED_ANDROID_E2E_PHOTOS ?? '2');

if (!outDir) {
  console.error('Usage: assert_android_deep_e2e_artifacts.mjs <output-dir>');
  process.exit(2);
}

const resolvedOutDir = path.resolve(outDir);
const checkedArtifacts = [];

function artifactPath(relativePath) {
  return path.join(resolvedOutDir, relativePath);
}

function fail(message) {
  console.error(`[android-deep-e2e-artifacts] ${message}`);
  process.exit(1);
}

function readArtifact(relativePath) {
  const filePath = artifactPath(relativePath);
  let stat;
  try {
    stat = fs.statSync(filePath);
  } catch {
    fail(`missing artifact: ${relativePath}`);
  }
  if (!stat.isFile() || stat.size === 0) {
    fail(`empty artifact: ${relativePath}`);
  }
  checkedArtifacts.push(relativePath);
  return fs.readFileSync(filePath, 'utf8');
}

function requireFile(relativePath) {
  const filePath = artifactPath(relativePath);
  let stat;
  try {
    stat = fs.statSync(filePath);
  } catch {
    fail(`missing artifact: ${relativePath}`);
  }
  if (!stat.isFile() || stat.size === 0) {
    fail(`empty artifact: ${relativePath}`);
  }
  checkedArtifacts.push(relativePath);
}

function requireContains(relativePath, expected) {
  const contents = readArtifact(relativePath);
  if (!contents.includes(expected)) {
    fail(`artifact ${relativePath} does not contain expected text: ${expected}`);
  }
}

function requireJson(relativePath) {
  const contents = readArtifact(relativePath);
  try {
    return JSON.parse(contents);
  } catch (error) {
    fail(`artifact ${relativePath} is not valid JSON: ${error.message}`);
  }
}

function assertBackupPhotoCount(relativePath) {
  const backup = requireJson(relativePath);
  const photos = Array.isArray(backup.photos) ? backup.photos : null;
  if (!photos) {
    fail(`${relativePath} does not contain a photos array`);
  }
  if (photos.length !== expectedPhotoCount) {
    fail(`${relativePath} contains ${photos.length} photos; expected ${expectedPhotoCount}`);
  }
}

requireFile('01-first-run.png');
requireContains('01-first-run.xml', 'Choose Photos');

requireFile('02-denied.png');
requireContains('02-denied.xml', 'Photo library permission denied. Open settings to grant access.');

requireFile('03-full-access.png');
requireContains(
  '03-full-access.xml',
  `Photo library scan complete: ${expectedPhotoCount} imported, 0 updated, 0 skipped, 0 errors, 0 missing`,
);

requireFile('04-limited-access.png');
requireContains(
  '04-limited-access.xml',
  `Limited photo access: ${expectedPhotoCount} imported, 0 updated, 0 skipped, 0 errors, 0 missing`,
);
requireContains('04-permissions.txt', 'android.permission.READ_MEDIA_VISUAL_USER_SELECTED: granted=true');
requireContains('04-permissions.txt', 'android.permission.READ_MEDIA_IMAGES: granted=false');

requireFile('05-restart.png');
requireContains('05-restart.xml', 'Select');

requireFile('06-restore.png');
requireContains('06-restore.xml', 'Select');
requireContains('06-restore.xml', `${expectedPhotoCount} items`);
assertBackupPhotoCount('backup.json');

const summaryPath = artifactPath('summary.json');
if (fs.existsSync(summaryPath)) {
  const summary = requireJson('summary.json');
  if (summary.status !== 'passed') {
    fail(`summary.json status is ${JSON.stringify(summary.status)}; expected "passed"`);
  }
}

console.log(
  JSON.stringify(
    {
      ok: true,
      outDir: resolvedOutDir,
      expectedPhotoCount,
      checkedArtifacts: [...new Set(checkedArtifacts)].sort(),
    },
    null,
    2,
  ),
);
