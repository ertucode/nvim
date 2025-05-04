import * as fs from "fs";
import {
  execSync,
  type ExecSyncOptionsWithBufferEncoding,
} from "child_process";
import * as os from "os";
import { logWithHeader, rgb } from "./log";
import type { SpawnOptions } from "bun";
import { normalizePath } from "./file-system";

export function link(source: string, destination: string) {
  const toParts = destination.split("/");
  if (toParts.length > 2) {
    const directory = toParts.slice(0, toParts.length - 1).join("/");
    runCommand(`mkdir -p ${directory}`);
  }

  runCommand(`ln -sf ${source} ${destination}`);
}

export function runCommand(
  command: string,
  options?: Omit<ExecSyncOptionsWithBufferEncoding, "stdio"> & { cwd?: string },
) {
  logWithHeader("COMMAND", command, rgb(255, 255, 0), rgb(0, 180, 255));
  if (options?.cwd) {
    options.cwd = normalizePath(options.cwd!);
  }
  execSync(command, { stdio: "inherit", ...options });
}

export async function runCommandWithStreaming(
  cmd: string[],
  options?: Pick<SpawnOptions.OptionsObject, "timeout" | "signal" | "cwd">,
  onChunk?: (text: string, isStdout: boolean) => void,
): Promise<{ stdout: string; stderr: string; exitCode: number }> {
  logWithHeader("COMMAND", cmd.join(" "), rgb(255, 255, 0), rgb(0, 180, 255));
  if (options?.cwd) {
    options.cwd = normalizePath(options.cwd!);
  }
  const proc: Bun.Subprocess<any, "pipe", "pipe"> = Bun.spawn(cmd, {
    stdout: "pipe",
    stderr: "pipe",
    ...options,
  } as const);

  const decoder = new TextDecoder();

  const readStream = async (
    stream: ReadableStream<Uint8Array> | null,
    isStdout: boolean,
    _onChunk: (text: string) => void,
  ): Promise<string> => {
    if (!stream) return "";
    const reader = stream.getReader();
    let result = "";

    while (true) {
      const { done, value } = await reader.read();
      if (done) break;
      const text = decoder.decode(value);
      _onChunk(text);
      onChunk?.(text, isStdout);
      result += text;
    }

    return result;
  };

  const stdoutPromise = readStream(proc.stdout, true, (text) =>
    process.stdout.write(text),
  );
  const stderrPromise = readStream(proc.stderr, false, (text) =>
    process.stderr.write(text),
  );

  const [stdoutResult, stderrResult] = await Promise.all([
    stdoutPromise,
    stderrPromise,
  ]);

  const exitCode = await proc.exited;

  return {
    stdout: stdoutResult,
    stderr: stderrResult,
    exitCode,
  };
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

  logWithHeader("WRITE", normalizedPath, rgb(255, 255, 0), rgb(0, 180, 255));
  fs.writeFileSync(normalizedPath, result.join("\n"), "utf8");
}
