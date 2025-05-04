import { checkIfFolderExists } from "./file-system";
import { runCommand, runCommandWithStreaming } from "./setup-pc-utils";

export function cloneRepo({ repo, path }: { repo: string; path: string }) {
  runCommand(`git clone ${repo} ${path}`);
}

export async function pullRepo({ path }: { path: string }) {
  const res = await runCommandWithStreaming(["git", "pull"], { cwd: path });

  return res.stdout.includes("Already up to date.");
}

export async function cloneOrPullRepo({
  repo,
  path,
}: {
  repo: string;
  path: string;
}): Promise<{
  alreadyUpToDate: boolean;
}> {
  if (checkIfFolderExists(path)) {
    return {
      alreadyUpToDate: await pullRepo({ path }),
    };
  } else {
    cloneRepo({ repo, path });
    return {
      alreadyUpToDate: false,
    };
  }
}
