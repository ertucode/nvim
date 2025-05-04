import { checkIfFolderExists } from "./file-system";
import { runCommand } from "./setup-pc-utils";

export function cloneRepo({ repo, path }: { repo: string; path: string }) {
  runCommand(`git clone ${repo} ${path}`);
}

export function pullRepo({ path }: { path: string }) {
  runCommand(`cd ${path} && git pull`);
}

export function cloneOrPullRepo({
  repo,
  path,
}: {
  repo: string;
  path: string;
}) {
  if (checkIfFolderExists(path)) {
    pullRepo({ path });
  } else {
    cloneRepo({ repo, path });
  }
}
