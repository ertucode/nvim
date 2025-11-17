export async function showErrorOnTab(tabId: number, text: string) {
  try {
    await chrome.tabs.sendMessage(tabId, {
      type: "SHOW_ERROR",
      text,
    });
  } catch (e) {
    console.error("Failed to send error to content script", e);
  }
}
