import type { ZodType } from "zod";
import z, { ZodError } from "zod";
import { kebabCaseToCamelCase } from "./string-utils";

export type ProcessArgsOptions = {
  autoCamelCase?: boolean;
};
export function getProcessArgs<T>(
  schema: ZodType<T>,
  opts?: ProcessArgsOptions,
): T {
  const args = process.argv.slice(2);

  const result = processArgsToObject(args, opts);

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

function processArgsToObject(args: string[], opts?: ProcessArgsOptions) {
  const result: any = {};
  let key: ArgKey | undefined = undefined;

  for (const arg of args) {
    if (arg.startsWith("--")) {
      if (key) {
        result[key.getValue()] = true;
      }
      if (arg.includes("=")) {
        const [_key, value] = arg.split("=");
        result[new ArgKey(_key, opts).getValue()] = getValue(value);
        key = undefined;
        continue;
      }
      key = new ArgKey(arg.slice(2), opts);
    } else if (key) {
      result[key.getValue()] = getValue(arg);
      key = undefined;
    }
  }

  if (key) {
    result[key.getValue()] = true;
  }

  return result;
}

function getValue(value: string): string | boolean {
  if (value === "true") return true;
  if (value === "false") return false;
  return value;
}

class ArgKey {
  constructor(
    private key: string,
    private opts: ProcessArgsOptions | undefined,
  ) {}

  getValue() {
    if (this.key.startsWith("--")) {
      this.key = this.key.slice(2);
    }

    if (this.opts?.autoCamelCase === false) {
      return this.key;
    }

    return kebabCaseToCamelCase(this.key);
  }
}

if (import.meta.main) {
  const result = getProcessArgs(
    z.object({
      testObj: z.boolean(),
    }),
  );

  if (result.testObj) {
    const cases: { input: string[]; obj: any; opts?: ProcessArgsOptions }[] = [
      {
        input: ["--test=true"],
        obj: { test: true },
      },
      {
        input: ["--test=false"],
        obj: { test: false },
      },
      {
        input: ["--test"],
        obj: { test: true },
      },
      {
        input: ["--test=true", "--test=false"],
        obj: { test: false },
      },
      {
        input: ["--test-obj", "true"],
        obj: { testObj: true },
      },
      {
        input: ["--a", "--b", "--c"],
        obj: { a: true, b: true, c: true },
      },
      {
        input: ["--a", "--b=3"],
        obj: { a: true, b: "3" },
      },
      {
        input: ["--hello-world=3"],
        obj: { "hello-world": "3" },
        opts: { autoCamelCase: false },
      },
    ];

    for (const { input, obj, opts } of cases) {
      const resultObj = processArgsToObject(input, opts);

      if (JSON.stringify(resultObj) !== JSON.stringify(obj)) {
        throw new Error(
          `processArgsToObject(${JSON.stringify(
            input,
          )}) should be ${JSON.stringify(obj)} but got ${JSON.stringify(
            resultObj,
          )}`,
        );
      }
    }

    console.log("All tests passed");
  }
}
