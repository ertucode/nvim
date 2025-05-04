import { runCommand } from "../utils/setup-pc-utils";

export function configureGit() {
  const lines = [
    `git config --global alias.cb '!git commit -m "$(git symbolic-ref --short HEAD)"'`,
    `git config --global alias.rd '!git fetch origin && git rebase origin/develop'`,
    `git config --global alias.ca '!git commit --amend --no-edit'`,
    `git config --global push.autoSetupRemote true`,
    `git config --global branch.sort -committerdate`,
  ];

  for (const line of lines) {
    runCommand(line);
  }
}
