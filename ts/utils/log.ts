export function coloredLog(color: Color, message: string) {
  const reset = "\x1b[0m";
  console.log(`${color}${message}${reset}`);
}

export function coloredLogFromParts(...parts: (string | { c: Color })[]) {
  const joined = parts
    .map((part) => {
      if (typeof part === "string") {
        return part;
      }
      return part.c;
    })
    .join("");
  const reset = "\x1b[0m";
  console.log(`${joined}${reset}`);
}

export function logWithHeader(
  header: string,
  message: string,
  headerColor: Color,
  messageColor: Color,
) {
  coloredLogFromParts(
    headerColor,
    `${header.padEnd(8, " ")} |   `,
    messageColor,
    message,
  );
}

export function rgb(r: number, g: number, b: number): Color {
  return `\x1b[38;2;${r};${g};${b}m` as Color;
}

export function rgbBackground(r: number, g: number, b: number): Color {
  return `\x1b[48;2;${r};${g};${b}m` as Color;
}

export function c(color: ColorKey): Color {
  return colors[color] as Color;
}

export const colors = {
  blue: "\x1b[34m",
  blue2: "\x1b[94m",
  yellow: "\x1b[33m",
  reset: "\x1b[0m",
  cyan: "\x1b[36m",
} as const;

export type ColorKey = keyof typeof colors;

export type Color = string & { __brand: "Color" };
