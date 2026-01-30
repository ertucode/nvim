chrome.runtime.onMessage.addListener((message) => {
  if (message.type === "SHOW_ERROR") {
    showErrorModal(message.text);
  }
});

function showErrorModal(text: string) {
  // Remove existing modal if any
  const existing = document.getElementById("extension-error-modal");
  if (existing) existing.remove();

  // Create overlay
  const overlay = document.createElement("div");

  overlay.id = "extension-error-modal";
  overlay.style.position = "fixed";
  overlay.style.bottom = "20px";
  overlay.style.right = "20px";
  overlay.style.transform = "translateX(-50%)";
  overlay.style.background = "red"; // red background
  overlay.style.color = "white"; // white text
  overlay.style.padding = "12px 20px";
  overlay.style.borderRadius = "6px";
  overlay.style.boxShadow = "0 2px 10px rgba(0,0,0,0.3)";
  overlay.style.zIndex = "999999";
  overlay.style.fontFamily = "sans-serif";
  overlay.style.fontSize = "14px";
  overlay.style.textAlign = "center";
  overlay.style.opacity = "0";
  overlay.style.transition = "opacity 0.3s ease-in-out";
  overlay.innerText = text;

  document.body.appendChild(overlay);

  // Fade in
  requestAnimationFrame(() => {
    overlay.style.opacity = "1";
  });

  // Auto-remove after 5 seconds
  setTimeout(() => {
    overlay.style.opacity = "0";
    overlay.addEventListener("transitionend", () => overlay.remove());
  }, 5000);
}
