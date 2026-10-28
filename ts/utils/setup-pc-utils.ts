import * as fs from "fs";
import {
  execSync,
  spawnSync,
  type ExecSyncOptionsWithBufferEncoding,
} from "child_process";
import * as os from "os";
import { logWithHeader, logWithHeaderAndSource, rgb } from "./log";
import type { SpawnOptions } from "bun";
import { normalizePath } from "./file-system";
import { spawn } from "bun";

export function runCommand(
  command: string,
  options?: Omit<ExecSyncOptionsWithBufferEncoding, "stdio"> & {
    cwd?: string;
    prefix?: string;
  },
) {
  logWithHeader("COMMAND", command, rgb(255, 255, 0), rgb(0, 180, 255));
  const { prefix, ...commandOptions } = options ?? {};
  if (commandOptions.cwd) {
    commandOptions.cwd = normalizePath(commandOptions.cwd);
  }

  if (!prefix) {
    execSync(command, { stdio: "inherit", ...commandOptions });
    return;
  }

  const result = spawnSync(command, {
    ...commandOptions,
    shell: true,
    encoding: "utf8",
    stdio: ["inherit", "pipe", "pipe"],
  });

  logPrefixedOutput(prefix, result.stdout);
  logPrefixedOutput(prefix, result.stderr);

  if (result.error) throw result.error;
  if (result.status !== 0) {
    throw new Error(`Command failed with exit code ${result.status}: ${command}`);
  }
}

function logPrefixedOutput(prefix: string, output: string | null) {
  if (!output) return;

  const lines = output.replace(/\r?\n$/, "").split(/\r?\n/);
  for (const line of lines) {
    logCommandOutput(prefix, line);
  }
}

function logCommandOutput(command: string, output: string) {
  logWithHeaderAndSource(
    "COMMAND",
    command,
    output,
    rgb(255, 255, 0),
    rgb(0, 180, 255),
    rgb(255, 255, 255),
  );
}

export async function getCommand(command: string[]) {
  logWithHeader(
    "GCOMMAND",
    command.join(" "),
    rgb(255, 255, 0),
    rgb(0, 180, 255),
  );
  const proc = spawn({
    cmd: command,
    stdout: "pipe",
    stderr: "pipe",
    // This option prevents Bun from throwing on non-zero exit codes
    onExit: (proc, exitCode, signal) => {
      // You could log or handle the exit code here if needed
    },
  });

  const stdout = await new Response(proc.stdout).text();
  const stderr = await new Response(proc.stderr).text();
  const exitCode = await proc.exited;

  return { stdout, stderr, exitCode: exitCode ?? -1, success: exitCode === 0 };
}

export function fireAndForget(command: string[]) {
  logWithHeader(
    "FCOMMAND",
    command.join(" "),
    rgb(255, 255, 0),
    rgb(0, 180, 255),
  );
  spawn({
    cmd: command,
    stdout: "pipe",
    stderr: "pipe",
    // This option prevents Bun from throwing on non-zero exit codes
    onExit: (proc, exitCode, signal) => {
      // You could log or handle the exit code here if needed
    },
  });
}

export function runCommandWithOutput(
  command: string,
  options?: Omit<ExecSyncOptionsWithBufferEncoding, "stdio"> & { cwd?: string },
): string {
  logWithHeader("COMMAND", command, rgb(255, 255, 0), rgb(0, 180, 255));
  if (options?.cwd) {
    options.cwd = normalizePath(options.cwd!);
  }
  return execSync(command, { encoding: "utf8" });
}

export async function runCommandWithStreaming(
  cmd: string[],
  options?: Pick<SpawnOptions.OptionsObject, "timeout" | "signal" | "cwd"> & {
    prefix?: string;
  },
  onChunk?: (text: string, isStdout: boolean) => void,
): Promise<{ stdout: string; stderr: string; exitCode: number }> {
  logWithHeader("COMMAND", cmd.join(" "), rgb(255, 255, 0), rgb(0, 180, 255));
  const { prefix, ...spawnOptions } = options ?? {};
  if (spawnOptions.cwd) {
    spawnOptions.cwd = normalizePath(spawnOptions.cwd);
  }
  const proc: Bun.Subprocess<any, "pipe", "pipe"> = Bun.spawn(cmd, {
    stdout: "pipe",
    stderr: "pipe",
    ...spawnOptions,
  } as const);

  const readStream = async (
    stream: ReadableStream<Uint8Array> | null,
    isStdout: boolean,
    _onChunk: (text: string) => void,
  ): Promise<string> => {
    if (!stream) return "";
    const reader = stream.getReader();
    const decoder = new TextDecoder();
    let result = "";
    let pendingLine = "";

    while (true) {
      const { done, value } = await reader.read();
      if (done) break;
      const text = decoder.decode(value, { stream: true });
      if (prefix) {
        const lines = `${pendingLine}${text}`.split(/\r?\n/);
        pendingLine = lines.pop() ?? "";
        for (const line of lines) {
          logCommandOutput(prefix, line);
        }
      } else {
        _onChunk(text);
      }
      onChunk?.(text, isStdout);
      result += text;
    }

    const finalText = decoder.decode();
    result += finalText;
    pendingLine += finalText;
    if (prefix && pendingLine) {
      logCommandOutput(prefix, pendingLine);
    } else if (!prefix && finalText) {
      _onChunk(finalText);
    }
    if (finalText) onChunk?.(finalText, isStdout);

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
