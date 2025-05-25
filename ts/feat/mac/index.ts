import { setupOptionOverlay } from "./option-overlay";
import { setupDefaultApps } from "./setup-default-apps";

export async function setupMac() {
  // setupOptionOverlay();
  await setupDefaultApps();
}
