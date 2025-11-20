import { getCommand, runCommand } from "./setup-pc-utils";

// Cleanupta permission hatası alırsan. sudo chown -R $(whoami) /opt/homebrew
export type BrewInstallOptions = {
  cli?: boolean;
  cask?: boolean;
};
export async function brewInstallIfNotInstalled(
  pkg: string,
  opts?: BrewInstallOptions,
) {
  const res = await checkInstalled(pkg, opts);
  if (res.exitCode !== 0) {
    let command = "brew install";
    if (opts?.cask) command += " --cask";
    command += ` ${pkg}`;
    runCommand(command);
  }
}

async function checkInstalled(pkg: string, opts?: BrewInstallOptions) {
  if (opts?.cli) return await getCommand(["which", pkg]);
  return await getCommand(["brew", "ls", "--versions", pkg]);
}
