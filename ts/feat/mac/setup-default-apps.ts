import { appExists } from "../../utils/app";
import { brewInstallIfNotInstalled } from "../../utils/brew";
import { runCommand } from "../../utils/setup-pc-utils";

export async function setupDefaultApps() {
  await brewInstallIfNotInstalled("duti", { cli: true });
  return Promise.all([setupNeovide(), setupLibreOffice(), setupMpv()]);
}

function setupLibreOffice() {
  return brewInstallIfNotInstalled("libreoffice", { cask: true });
}

function setupMpv() {
  const types = [
    "mp4",
    "mkv",
    "mov",
    "avi",
    "flv",
    "wmv",
    "webm",
    "m4v",
    "mpg",
    "mpeg",
    "ts",
    "vob",
    "ogv",
    "qt",
  ];
  for (const type of types) {
    runCommand(`duti -s io.mpv ${type} all`);
  }
}

async function setupNeovide() {
  if (!(await appExists("Neovide")))
    throw new Error("Neovide is not installed");

  const types = ["txt", "json", "csv", "geojson"];

  for (const type of types) {
    runCommand(`duti -s com.neovide.neovide ${type} all`);
  }
}
