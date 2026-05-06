const targetByPlatform = new Map([
  ["linux", "linux"],
  ["darwin", "macos"],
  ["win32", "windows"],
]);

export const supportedPackageTargets = ["linux", "macos", "windows"];

export function isPackageTarget(input) {
  return supportedPackageTargets.includes(input);
}

export function normalizePackageTarget(input = targetByPlatform.get(process.platform)) {
  if (input === "darwin") {
    return "macos";
  }

  if (input === "win32") {
    return "windows";
  }

  if (isPackageTarget(input)) {
    return input;
  }

  throw new Error(`Unsupported package target: ${String(input)}`);
}

export function packageFolderName(target, arch = process.arch) {
  return `chronopic-${target}-${arch}`;
}
