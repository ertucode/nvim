import { getPlatformType } from "./platform";
import { getCommand } from "./setup-pc-utils";

const platform = getPlatformType();

export async function appExists(appName: string) {
  if (platform === "mac") return await appExistsMac(appName);

  throw new Error("Not implemented: " + platform);
}

async function appExistsMac(appName: string) {
  return await getCommand([
    "sh",
    "-c",
    `[ -e /Applications/${appName}.app ]`,
  ]).then((r) => r.success);
}
