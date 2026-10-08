import { Plugin } from "@opencode/plugin";
import { $ } from "bun";

export default Plugin.define({
  id: "notifications",

  setup(ctx) {
    const controller = new AbortController();

    void (async () => {
      try {
        for await (const event of ctx.event.subscribe({
          signal: controller.signal,
        })) {
          if (event.type === "session.idle") {
            await $`osascript -e 'display notification "OpenCode cevap vermeye hazır" with title "OpenCode"'`;
          }
        }
      } catch (error) {
        if (!controller.signal.aborted) {
          console.error("Notification plugin error:", error);
        }
      }
    })();

    return () => controller.abort();
  },
});
