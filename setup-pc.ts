import * as fs from "fs";
import { execSync } from "child_process";
import * as os from "os";

execSync("ln -sf ~/.config/nvim/starsip.toml ~/.config/starship.toml", {
  stdio: "inherit",
});

execSync("mkdir -p ~/.config/alacritty", { stdio: "inherit" });
execSync(
  "ln -sf ~/.config/nvim/alacritty.toml ~/.config/alacritty/alacritty.toml",
  { stdio: "inherit" },
);

execSync("ln -sf ~/.config/nvim/ideavimrc ~/.ideavimrc", { stdio: "inherit" });

ensureLinesInFile({
  lines: ["source ~/.config/nvim/helpers.zshrc"],
  filePath: "~/.zshrc",
});

function ensureLinesInFile({
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
