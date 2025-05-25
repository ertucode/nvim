import { appExists } from "../../utils/app";
import { brewInstallIfNotInstalled } from "../../utils/brew";
import { runCommand } from "../../utils/setup-pc-utils";

export async function setupDefaultApps() {
  if (!(await appExists("Neovide")))
    throw new Error("Neovide is not installed");

  await brewInstallIfNotInstalled("duti", { cli: true });

  const types = ["txt", "json", "csv", "geojson", "har"];

  for (const type of types) {
    runCommand(`duti -s com.neovide.neovide ${type} all`);
  }
}
