export function getPlatformType() {
  const platform = process.platform;

  switch (platform) {
    case "linux":
      return "linux";
    case "win32":
      return "windows";
    case "darwin":
      return "mac";
    default:
      return "unknown";
  }
}
