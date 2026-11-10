import * as fs from "fs";

export const sharedScriptsPath = "/Users/Shared/scripts";
const refreshSharedConfigsScriptPath = `${sharedScriptsPath}/refresh-configs.sh`;

const refreshSharedConfigsScript = `#!/bin/sh
set -eu

# Karabiner restarts its own process, so install the MPV agent first.
/bin/sh /Users/Shared/scripts/setup-mpv.sh
/bin/sh /Users/Shared/scripts/setup-karabiner.sh
`;

export function writeSharedFile(
  destination: string,
  content: string,
  mode: number,
) {
  const temporaryFile = `${destination}.${process.pid}-${Date.now()}.tmp`;

  try {
    fs.writeFileSync(temporaryFile, content, { encoding: "utf8", mode });
    fs.chmodSync(temporaryFile, mode);
    fs.renameSync(temporaryFile, destination);
  } finally {
    fs.rmSync(temporaryFile, { force: true });
  }
}

export function writeRefreshSharedConfigsScript() {
  writeSharedFile(
    refreshSharedConfigsScriptPath,
    refreshSharedConfigsScript,
    0o755,
  );
}
