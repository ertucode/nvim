import { getPlatformType } from "./platform";
import { getCommand } from "./setup-pc-utils";

const platform = getPlatformType();

export async function appExists(appName: string) {
  if (platform === "mac") return await appExistsMac(appName);

  throw new Error("Not implemented: " + platform);
}

async function appExistsMac(appName: string) {
  return await getCommand(["osascript", "-e", `id of app "${appName}"`]).then(
    (r) => r.success,
  );
}
