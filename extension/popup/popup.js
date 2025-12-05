/**
 * EMRY Popup Script
 */

async function updateStatus() {
  try {
    const response = await chrome.runtime.sendMessage({ type: 'get_status' });

    const { server, stats } = response;

    // Update status indicator
    const statusDot = document.getElementById('statusDot');
    const statusText = document.getElementById('statusText');

    if (server.connected) {
      statusDot.className = 'status-dot connected';
      statusText.textContent = `Connected (Port ${server.port})`;
    } else {
      statusDot.className = 'status-dot disconnected';
      statusText.textContent = 'Disconnected - Start server';
    }

    // Update stats
    document.getElementById('sessionMessages').textContent = stats.messagesThisSession || 0;
    document.getElementById('totalMessages').textContent = stats.messagesTotal || 0;

    // Show content, hide loading
    document.getElementById('loading').style.display = 'none';
    document.getElementById('content').style.display = 'block';

  } catch (error) {
    console.error('Failed to get status:', error);
    document.getElementById('loading').innerHTML = `
      <p style="color: #ff4444;">Failed to load status</p>
      <button onclick="location.reload()" style="margin-top: 10px;">Retry</button>
    `;
  }
}

// Open memories folder
document.addEventListener('DOMContentLoaded', () => {
  updateStatus();

  // Refresh button
  document.getElementById('refreshStatus').addEventListener('click', () => {
    document.getElementById('loading').style.display = 'block';
    document.getElementById('content').style.display = 'none';
    updateStatus();
  });

  // Open memories folder button
  document.getElementById('openMemories').addEventListener('click', async () => {
    // Try to open the memories folder
    // First, get server URL
    const response = await chrome.runtime.sendMessage({ type: 'get_status' });
    if (response.server.connected) {
      const serverUrl = response.server.url;

      // Fetch config to get md_dir
      try {
        const configResponse = await fetch(`${serverUrl}/config`);
        const config = await configResponse.json();

        if (config.md_dir) {
          // We can't directly open local folders from extension
          // Instead, show instructions
          alert(`Memories are stored at:\n\n${config.md_dir}\n\nOpen this folder in your file explorer to view your memories.`);
        }
      } catch (error) {
        alert('Could not retrieve memories location. Make sure the server is running.');
      }
    } else {
      alert('EMRY server is not running. Please start the server first.');
    }
  });

  // Auto-refresh every 5 seconds
  setInterval(updateStatus, 5000);
});
