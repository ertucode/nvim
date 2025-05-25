import { getCommand, runCommand } from "./setup-pc-utils";

export type BrewInstallOptions = {
  cli?: boolean;
};
export async function brewInstallIfNotInstalled(
  pkg: string,
  opts?: BrewInstallOptions,
) {
  const res = await checkInstalled(pkg, opts);
  if (res.exitCode !== 0) {
    runCommand(`brew install ${pkg}`);
  }
}

async function checkInstalled(pkg: string, opts?: BrewInstallOptions) {
  if (opts?.cli) return await getCommand(["which", pkg]);
  return await getCommand(["brew", "ls", "--versions", pkg]);
}
