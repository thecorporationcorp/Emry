/**
 * EMRY Universal Helper - Shared utilities for all content scripts
 */

window.EMRY = window.EMRY || {};

(function() {
  'use strict';

  // Configuration
  const EMRY = window.EMRY;
  EMRY.VERSION = '2.0.0';
  EMRY.serverPort = 8766;
  EMRY.serverHost = '127.0.0.1';
  EMRY.serverUrl = null;
  EMRY.isConnected = false;
  EMRY.platform = 'unknown';

  // Message tracking
  EMRY.seenMessages = new Set();
  EMRY.messageQueue = [];
  EMRY.isProcessing = false;

  /**
   * Find active server by probing ports
   */
  EMRY.discoverServer = async function() {
    if (EMRY.serverUrl && EMRY.isConnected) {
      return EMRY.serverUrl;
    }

    // Try ports 8766-8799
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
            EMRY.serverUrl = url;
            EMRY.serverPort = port;
            EMRY.isConnected = true;
            console.log(`[EMRY] Connected to server at ${url}`);
            return url;
          }
        }
      } catch (e) {
        // Port not available, continue
      }
    }

    EMRY.isConnected = false;
    console.warn('[EMRY] Server not found. Make sure EMRY server is running.');
    return null;
  };

  /**
   * Send message to EMRY server
   */
  EMRY.captureMessage = async function(role, content, metadata = {}) {
    if (!content || !content.trim()) {
      return false;
    }

    content = content.trim();

    // Check if already seen
    const contentHash = EMRY.hashString(content);
    if (EMRY.seenMessages.has(contentHash)) {
      return false;
    }

    // Discover server if not connected
    const serverUrl = await EMRY.discoverServer();
    if (!serverUrl) {
      console.warn('[EMRY] Cannot capture - server not available');
      return false;
    }

    try {
      const payload = {
        role: role.toLowerCase(),
        content: content,
        platform: EMRY.platform,
        url: window.location.href,
        metadata: {
          ...metadata,
          page_title: document.title,
          captured_at: new Date().toISOString(),
          user_agent: navigator.userAgent
        }
      };

      const response = await fetch(`${serverUrl}/capture`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(payload)
      });

      if (response.ok) {
        const result = await response.json();
        if (result.ok) {
          EMRY.seenMessages.add(contentHash);
          console.log(`[EMRY] Captured ${role} message (${content.length} chars)`);

          // Notify background script
          chrome.runtime.sendMessage({
            type: 'message_captured',
            role: role,
            platform: EMRY.platform
          });

          return true;
        }
      }
    } catch (error) {
      console.error('[EMRY] Capture error:', error);
      EMRY.isConnected = false;
      EMRY.serverUrl = null;
    }

    return false;
  };

  /**
   * Simple string hash for deduplication
   */
  EMRY.hashString = function(str) {
    let hash = 0;
    for (let i = 0; i < str.length; i++) {
      const char = str.charCodeAt(i);
      hash = ((hash << 5) - hash) + char;
      hash = hash & hash;
    }
    return hash.toString(36);
  };

  /**
   * Extract clean text from element
   */
  EMRY.extractText = function(element) {
    if (!element) return '';

    // Clone to avoid modifying DOM
    const clone = element.cloneNode(true);

    // Remove script and style elements
    clone.querySelectorAll('script, style, button, svg').forEach(el => el.remove());

    // Get text content
    let text = clone.textContent || clone.innerText || '';

    // Clean up whitespace
    text = text.replace(/\s+/g, ' ').trim();

    return text;
  };

  /**
   * Create mutation observer for dynamic content
   */
  EMRY.createObserver = function(callback, options = {}) {
    const config = {
      childList: true,
      subtree: true,
      ...options
    };

    const observer = new MutationObserver((mutations) => {
      callback(mutations);
    });

    observer.observe(document.body, config);
    return observer;
  };

  /**
   * Debounce function for performance
   */
  EMRY.debounce = function(func, wait) {
    let timeout;
    return function executedFunction(...args) {
      const later = () => {
        clearTimeout(timeout);
        func(...args);
      };
      clearTimeout(timeout);
      timeout = setTimeout(later, wait);
    };
  };

  /**
   * Queue-based message processing to avoid race conditions
   */
  EMRY.queueMessage = function(role, content, metadata) {
    EMRY.messageQueue.push({ role, content, metadata });
    EMRY.processQueue();
  };

  EMRY.processQueue = EMRY.debounce(async function() {
    if (EMRY.isProcessing || EMRY.messageQueue.length === 0) {
      return;
    }

    EMRY.isProcessing = true;

    while (EMRY.messageQueue.length > 0) {
      const message = EMRY.messageQueue.shift();
      await EMRY.captureMessage(message.role, message.content, message.metadata);
      await new Promise(resolve => setTimeout(resolve, 100)); // Small delay between messages
    }

    EMRY.isProcessing = false;
  }, 500);

  /**
   * Generic message detector (fallback)
   */
  EMRY.detectMessages = function() {
    console.log('[EMRY] Using generic message detection');

    const observer = EMRY.createObserver(() => {
      // Look for common chat message patterns
      const candidates = document.querySelectorAll([
        '[role="article"]',
        '[data-message-author-role]',
        '.message',
        '.chat-message',
        '.conversation-turn'
      ].join(','));

      candidates.forEach(element => {
        // Try to determine role
        const roleAttr = element.getAttribute('data-message-author-role');
        const classList = element.className.toLowerCase();

        let role = 'unknown';
        if (roleAttr) {
          role = roleAttr;
        } else if (classList.includes('user')) {
          role = 'user';
        } else if (classList.includes('assistant') || classList.includes('bot') || classList.includes('ai')) {
          role = 'assistant';
        }

        const content = EMRY.extractText(element);
        if (content && content.length > 10) {
          EMRY.queueMessage(role, content, {
            detector: 'generic',
            element_class: element.className
          });
        }
      });
    });

    return observer;
  };

  /**
   * Initialize EMRY on page load
   */
  EMRY.init = function(platform) {
    EMRY.platform = platform;
    console.log(`[EMRY] Initializing for platform: ${platform}`);

    // Discover server immediately
    EMRY.discoverServer();

    // Check connection periodically
    setInterval(() => {
      if (!EMRY.isConnected) {
        EMRY.discoverServer();
      }
    }, 5000);
  };

  console.log('[EMRY] Universal helper loaded');

})();
