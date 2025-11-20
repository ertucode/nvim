import { showErrorOnTab } from "./lib/showErrorOnTab";

// Most recently active tab first
let tabHistory: number[] = [];
let historyCursor = 0; // points to current tab in history
let isCommand = false;

// Called whenever a tab becomes active
chrome.tabs.onActivated.addListener(({ tabId }) => {
  if (isCommand) {
    isCommand = false;
    return;
  }
  const currentIndex = tabHistory.indexOf(tabId);

  if (currentIndex === -1) {
    // New tab, insert at front
    tabHistory.unshift(tabId);
  } else {
    // Tab already in history: move it to the front
    tabHistory.splice(currentIndex, 1);
    tabHistory.unshift(tabId);
  }

  // Reset cursor to the front (current tab)
  historyCursor = 0;

  // Limit history size
  if (tabHistory.length > 50) tabHistory.pop();
});

// Remove closed tabs from history
chrome.tabs.onRemoved.addListener((tabId) => {
  const index = tabHistory.indexOf(tabId);
  if (index !== -1) tabHistory.splice(index, 1);

  // Adjust cursor if necessary
  if (historyCursor >= tabHistory.length) {
    historyCursor = tabHistory.length - 1;
  }
});

// Navigate back through history
chrome.commands.onCommand.addListener(async (command) => {
  if (command === "last_tab") {
    if (tabHistory.length < 2 || historyCursor >= tabHistory.length - 1) {
      if (tabHistory.length === 0) return;
      showErrorOnTab(tabHistory[0], "Last Tab");
      return;
    }

    historyCursor += 1;
    const nextTabId = tabHistory[historyCursor];

    try {
      isCommand = true;
      await chrome.tabs.update(nextTabId, { active: true });
    } catch (e) {
      // Skip invalid tabs
      tabHistory.splice(historyCursor, 1);
      historyCursor -= 1;
    }
  } else if (command === "forward_tab") {
    if (historyCursor <= 0) {
      if (tabHistory.length === 0) return;
      showErrorOnTab(tabHistory.at(-1)!, "Last Tab");
      return;
    }
    historyCursor -= 1;
    const nextTabId = tabHistory[historyCursor];

    try {
      isCommand = true;
      await chrome.tabs.update(nextTabId, { active: true });
    } catch (e) {
      console.error("Failed to switch tab:", e);
      tabHistory.splice(historyCursor, 1);
    }
  } else if (command.startsWith("open_")) {
    try {
      const targetUrl = getSiteToOpen(command);
      // Get the current active tab in the current window
      const [currentTab] = await chrome.tabs.query({
        active: true,
        currentWindow: true,
      });

      // Check if the current tab is "empty"
      const isEmptyTab =
        currentTab?.url === "chrome://newtab/" ||
        currentTab?.url === "about:blank";

      if (isEmptyTab && currentTab?.id) {
        // Reuse current tab
        await chrome.tabs.update(currentTab.id, { url: targetUrl });
        return;
      }
      // Check if the site is already open in any tab
      const tabs = await chrome.tabs.query({});
      const existingTab = tabs.find((tab) => tab.url?.startsWith(targetUrl));

      if (existingTab && existingTab.id) {
        // Focus the existing tab
        await chrome.tabs.update(existingTab.id, { active: true });
        await chrome.windows.update(existingTab.windowId, { focused: true });
      } else {
        // Open a new tab
        await chrome.tabs.create({ url: targetUrl });
      }
    } catch (e) {
      console.error("Failed to open site:", e);
    }
  }
});

function getSiteToOpen(command: string) {
  if (command === "open_2") {
    return "https://chatgpt.com";
  }
  if (command === "open_1") {
    return "https://www.youtube.com";
  }
  if (command === "open_3") {
    return "https://www.reddit.com";
  }
  if (command === "open_4") {
    return "https://x.com";
  }
  if (command === "open_5") {
    return "https://admin.blupaymenkul.com/backoffice/f";
  }
  if (command === "open_6") {
    return "https://admin-pre-prod.blupaymenkul.com/backoffice/f";
  }
  showErrorOnTab(tabHistory[0], "Unknown command");
  throw new Error("Unknown command");
}
