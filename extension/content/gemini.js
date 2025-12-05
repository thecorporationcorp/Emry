/**
 * EMRY Gemini/Bard Capture
 * Handles gemini.google.com and bard.google.com
 */

(function() {
  'use strict';

  if (!window.EMRY) {
    console.error('[EMRY] Universal helper not loaded');
    return;
  }

  const EMRY = window.EMRY;
  EMRY.init('gemini');

  console.log('[EMRY] Gemini capture initialized');

  /**
   * Extract messages from Gemini's DOM
   */
  function captureMessages() {
    // Gemini uses Material Design components
    const messages = document.querySelectorAll([
      '.model-response-text',
      '.user-query',
      '[class*="message"]',
      '[class*="response"]',
      '[class*="query"]'
    ].join(','));

    messages.forEach(messageElement => {
      const classes = messageElement.className.toLowerCase();

      let role = 'unknown';

      if (classes.includes('user') || classes.includes('query')) {
        role = 'user';
      } else if (classes.includes('model') || classes.includes('response') || classes.includes('assistant')) {
        role = 'assistant';
      }

      const content = EMRY.extractText(messageElement);

      if (content && content.length > 10 && role !== 'unknown') {
        EMRY.queueMessage(role, content, {
          detector: 'gemini-primary',
          class_name: messageElement.className
        });
      }
    });
  }

  /**
   * Alternative detection for Gemini
   */
  function captureAlternative() {
    // Look for message containers with data attributes
    const containers = document.querySelectorAll([
      '[data-message-author]',
      '[data-role]',
      'message-node',
      '.conversation-message'
    ].join(','));

    containers.forEach(container => {
      let role = container.getAttribute('data-message-author') ||
                 container.getAttribute('data-role') ||
                 'unknown';

      role = role.toLowerCase();

      // Normalize role names
      if (role.includes('user') || role.includes('human')) {
        role = 'user';
      } else if (role.includes('model') || role.includes('bot') || role.includes('gemini') || role.includes('bard')) {
        role = 'assistant';
      }

      const content = EMRY.extractText(container);

      if (content && content.length > 10 && role !== 'unknown') {
        EMRY.queueMessage(role, content, {
          detector: 'gemini-fallback'
        });
      }
    });
  }

  /**
   * Chat balloon detection (visual structure)
   */
  function captureBalloons() {
    // Google often uses a left-right chat balloon pattern
    const allDivs = document.querySelectorAll('div[class*="conversation"], div[class*="chat"]');

    allDivs.forEach(div => {
      // Skip if too nested or too shallow
      const depth = getDepth(div);
      if (depth < 3 || depth > 20) return;

      const text = EMRY.extractText(div);
      if (!text || text.length < 15) return;

      // Check alignment (user typically right, assistant left in RTL, vice versa in LTR)
      const style = window.getComputedStyle(div);
      const align = style.textAlign || style.alignSelf || '';
      const position = style.justifyContent || '';

      let role = 'unknown';

      // Check for icons/avatars
      const hasUserIcon = div.querySelector('img[alt*="User"], [aria-label*="User"]');
      const hasModelIcon = div.querySelector('img[alt*="Gemini"], img[alt*="Bard"], [aria-label*="Gemini"]');

      if (hasUserIcon) {
        role = 'user';
      } else if (hasModelIcon) {
        role = 'assistant';
      } else {
        // Heuristic: user messages typically shorter
        role = text.length < 200 ? 'user' : 'assistant';
      }

      if (role !== 'unknown') {
        EMRY.queueMessage(role, text, {
          detector: 'gemini-balloon'
        });
      }
    });
  }

  function getDepth(element) {
    let depth = 0;
    let current = element;
    while (current && current.parentElement) {
      depth++;
      current = current.parentElement;
      if (depth > 50) break; // Safety limit
    }
    return depth;
  }

  /**
   * Start watching
   */
  function startWatching() {
    // Initial capture
    captureMessages();
    captureAlternative();
    captureBalloons();

    // Watch for changes
    EMRY.createObserver(() => {
      captureMessages();
      captureAlternative();
      captureBalloons();
    });

    // Periodic sweep
    setInterval(() => {
      captureMessages();
      captureAlternative();
    }, 2000);

    console.log('[EMRY] Gemini watching for messages');
  }

  // Start when ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', startWatching);
  } else {
    startWatching();
  }

})();
