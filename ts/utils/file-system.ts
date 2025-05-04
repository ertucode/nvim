import * as fs from "fs";
import * as os from "os";

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
