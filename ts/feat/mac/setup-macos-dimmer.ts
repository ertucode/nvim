import * as fs from "fs";
import * as os from "os";
import { runCommand } from "../../utils/setup-pc-utils";

const macOSDimmerSourcePath = `${os.homedir()}/.config/nvim/apps/macOS Dimmer`;
const macOSDimmerAppPath = `${os.homedir()}/Applications/macOS Dimmer.app`;

export function setupMacOSDimmer() {
  runCommand("/usr/bin/swift build -c release", {
    cwd: macOSDimmerSourcePath,
  });

  runCommand(
    "/usr/bin/pkill -TERM -x MacOSDimmer 2>/dev/null || true; " +
      "attempt=0; " +
      "while /usr/bin/pgrep -x MacOSDimmer >/dev/null && [ $attempt -lt 50 ]; do " +
      "/bin/sleep 0.1; attempt=$((attempt + 1)); " +
      "done; " +
      "/usr/bin/pkill -KILL -x MacOSDimmer 2>/dev/null || true",
  );

  const temporaryAppPath = `${macOSDimmerAppPath}.${process.pid}.tmp`;
  const contentsPath = `${temporaryAppPath}/Contents`;
  const executablePath = `${contentsPath}/MacOS/MacOSDimmer`;

  try {
    fs.rmSync(temporaryAppPath, { recursive: true, force: true });
    fs.mkdirSync(`${contentsPath}/MacOS`, { recursive: true, mode: 0o755 });
    fs.copyFileSync(
      `${macOSDimmerSourcePath}/.build/release/MacOSDimmer`,
      executablePath,
    );
    fs.chmodSync(executablePath, 0o755);
    fs.copyFileSync(
      `${macOSDimmerSourcePath}/Info.plist`,
      `${contentsPath}/Info.plist`,
    );

    runCommand(`/usr/bin/codesign --force --sign - "${temporaryAppPath}"`);
    fs.rmSync(macOSDimmerAppPath, { recursive: true, force: true });
    fs.renameSync(temporaryAppPath, macOSDimmerAppPath);
  } finally {
    fs.rmSync(temporaryAppPath, { recursive: true, force: true });
  }

  runCommand(
    `/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "${macOSDimmerAppPath}"`,
  );
  runCommand(`/usr/bin/open -g "${macOSDimmerAppPath}"`);
}

if (import.meta.main) {
  setupMacOSDimmer();
}
