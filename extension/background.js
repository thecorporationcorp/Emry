/**
 * EMRY Background Service Worker
 * Manages connection status and coordinates extension activities
 */

let serverStatus = {
  connected: false,
  url: null,
  port: null,
  lastCheck: null
};

let captureStats = {
  messagesTotal: 0,
  messagesThisSession: 0,
  lastCapture: null,
  byPlatform: {}
};

/**
 * Check if server is running
 */
async function checkServer() {
  for (let port = 8766; port <= 8799; port++) {
    try {
      const url = `http://127.0.0.1:${port}`;
      const response = await fetch(`${url}/health`, {
        method: 'GET',
        cache: 'no-store',
        signal: AbortSignal.timeout(1000)
      });

      if (response.ok) {
        const data = await response.json();
        if (data.ok) {
          serverStatus.connected = true;
          serverStatus.url = url;
          serverStatus.port = port;
          serverStatus.lastCheck = new Date().toISOString();

          updateBadge(true);
          return true;
        }
      }
    } catch (e) {
      // Continue trying other ports
    }
  }

  serverStatus.connected = false;
  serverStatus.url = null;
  serverStatus.lastCheck = new Date().toISOString();

  updateBadge(false);
  return false;
}

/**
 * Update extension badge to show status
 */
function updateBadge(connected) {
  if (connected) {
    chrome.action.setBadgeText({ text: '●' });
    chrome.action.setBadgeBackgroundColor({ color: [0, 200, 0, 255] });
    chrome.action.setTitle({ title: 'EMRY - Connected and capturing' });
  } else {
    chrome.action.setBadgeText({ text: '●' });
    chrome.action.setBadgeBackgroundColor({ color: [220, 0, 0, 255] });
    chrome.action.setTitle({ title: 'EMRY - Disconnected (server not running)' });
  }
}

/**
 * Handle messages from content scripts
 */
chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  if (message.type === 'message_captured') {
    captureStats.messagesThisSession++;
    captureStats.messagesTotal++;
    captureStats.lastCapture = new Date().toISOString();

    const platform = message.platform || 'unknown';
    captureStats.byPlatform[platform] = (captureStats.byPlatform[platform] || 0) + 1;

    // Animate badge briefly
    chrome.action.setBadgeText({ text: '✓' });
    setTimeout(() => {
      updateBadge(serverStatus.connected);
    }, 1000);

    console.log(`[EMRY] Message captured from ${platform}`);
  }

  if (message.type === 'get_status') {
    sendResponse({
      server: serverStatus,
      stats: captureStats
    });
  }

  if (message.type === 'check_server') {
    checkServer().then(connected => {
      sendResponse({ connected });
    });
    return true; // Async response
  }

  return false;
});

/**
 * Initialize on install/update
 */
chrome.runtime.onInstalled.addListener((details) => {
  console.log('[EMRY] Extension installed/updated');
  checkServer();

  if (details.reason === 'install') {
    // Show welcome page
    chrome.tabs.create({
      url: chrome.runtime.getURL('popup/welcome.html')
    });
  }
});

/**
 * Check server on startup
 */
chrome.runtime.onStartup.addListener(() => {
  console.log('[EMRY] Browser started, checking server');
  checkServer();
});

/**
 * Periodic server check
 */
setInterval(() => {
  checkServer();
}, 10000); // Check every 10 seconds

/**
 * Initial check
 */
checkServer();

console.log('[EMRY] Background service worker initialized');
