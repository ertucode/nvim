import * as fs from "fs";
import * as os from "os";
import { runCommand } from "./setup-pc-utils";

export function checkIfFolderExists(path: string): boolean {
  try {
    // Check if the folder exists by checking if it's a directory
    const stats = fs.statSync(normalizePath(path));
    return stats.isDirectory();
  } catch (error) {
    // If the folder doesn't exist, an error will be thrown
    return false;
  }
}

export function normalizePath(path: string): string {
  return path.replace("~", os.homedir());
}

export function writeFile(path: string, content: string) {
  ensureDirectoryForFile(path);

  const normalizedPath = normalizePath(path);
  fs.writeFileSync(normalizedPath, content, "utf8");
}

export function ensureDirectoryForFile(destination: string) {
  const toParts = destination.split("/");
  if (toParts.length > 2) {
    const directory = toParts.slice(0, toParts.length - 1).join("/");
    runCommand(`mkdir -p ${directory}`);
  }
}

export function link(
  source: string,
  destination: string,
  options: { replaceDirectory?: boolean } = {},
) {
  const normalizedSource = normalizePath(source);
  const normalizedDestination = normalizePath(destination);

  if (!fs.existsSync(normalizedSource)) {
    throw new Error(`Cannot link missing source: ${normalizedSource}`);
  }

  ensureDirectoryForFile(destination);

  try {
    const destinationStats = fs.lstatSync(normalizedDestination);

    if (destinationStats.isDirectory()) {
      if (!options.replaceDirectory) {
        throw new Error(
          `Refusing to replace directory without replaceDirectory: ${normalizedDestination}`,
        );
      }

      fs.rmSync(normalizedDestination, { recursive: true });
    } else {
      fs.unlinkSync(normalizedDestination);
    }
  } catch (error) {
    if (!(error instanceof Error && "code" in error && error.code === "ENOENT")) {
      throw error;
    }
  }

  fs.symlinkSync(normalizedSource, normalizedDestination);
}
