import type { ZodType } from "zod";
import z, { ZodError } from "zod";

export function getProcessArgs<T>(schema: ZodType<T>): T {
  const args = process.argv.slice(2);

  const result: any = {};
  let key: string | undefined = undefined;

  for (const arg of args) {
    if (arg.startsWith("--")) {
      if (key) {
        result[key] = true;
      }
      if (arg.includes("=")) {
        const [_key, value] = arg.split("=");
        result[_key.slice(2)] = value;
        key = undefined;
        continue;
      }
      key = arg.slice(2);
    } else if (key) {
      result[key] = arg;
      key = undefined;
    }
  }

  if (key) {
    result[key] = true;
  }

  try {
    return schema.parse(result);
  } catch (e) {
    if (e instanceof ZodError) {
      const error = new Error(JSON.stringify(z.treeifyError(e), null, 2));
      Error.captureStackTrace(error, getProcessArgs);
      throw error;
    }
    throw e;
  }
}
