import * as fs from "fs";
import { execSync } from "child_process";
import * as os from "os";
import { logWithHeader, rgb } from "./log";

export function link(source: string, destination: string) {
  const toParts = destination.split("/");
  if (toParts.length > 2) {
    const directory = toParts.slice(0, toParts.length - 1).join("/");
    runCommand(`mkdir -p ${directory}`);
  }

  runCommand(`ln -sf ${source} ${destination}`);
}

export function runCommand(command: string) {
  logWithHeader("COMMAND", command, rgb(255, 255, 0), rgb(0, 180, 255));
  execSync(command, { stdio: "inherit" });
}

export function ensureLinesInFile({
  lines,
  filePath,
}: {
  lines: string[];
  filePath: string;
}) {
  const normalizedPath = filePath.replace("~", os.homedir());
  if (!fs.existsSync(normalizedPath)) {
    console.error(`File ${normalizedPath} does not exist`);
    return;
  }
  const outLines = fs.readFileSync(normalizedPath, "utf8").split("\n");

  const result = [];
  let insideBlock = false;

  const key = "setup-pc.ts";
  const wrappedKey = `##### ${key} ######`;
  for (let i = 0; i < outLines.length; i++) {
    const trimmedLine = outLines[i].trim();

    if (trimmedLine === wrappedKey) {
      if (!insideBlock) {
        insideBlock = true;
      } else {
        insideBlock = false;
      }
      continue;
    }

    if (!insideBlock) {
      result.push(outLines[i]);
    }
  }

  while (result.length > 0 && result[result.length - 1].trim() === "") {
    result.pop();
  }

  if (result.length > 0) {
    result.push("");
  }

  result.push(wrappedKey);
  result.push(...lines);
  result.push(wrappedKey);
  result.push("");

  fs.writeFileSync(normalizedPath, result.join("\n"), "utf8");
}
