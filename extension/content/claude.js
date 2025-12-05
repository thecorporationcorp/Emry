/**
 * EMRY Claude Capture
 * Handles claude.ai
 */

(function() {
  'use strict';

  if (!window.EMRY) {
    console.error('[EMRY] Universal helper not loaded');
    return;
  }

  const EMRY = window.EMRY;
  EMRY.init('claude');

  console.log('[EMRY] Claude capture initialized');

  /**
   * Extract messages from Claude's DOM
   */
  function captureMessages() {
    // Claude uses different selectors - we need to be adaptive

    // Try primary selector pattern
    const messages = document.querySelectorAll('[data-test-render-count]');

    messages.forEach(messageElement => {
      // Determine role by checking parent structure or content
      let role = 'unknown';

      // Claude often wraps user messages differently from assistant
      const parentClasses = messageElement.parentElement?.className || '';

      if (parentClasses.includes('user') || messageElement.querySelector('[alt*="user"]')) {
        role = 'user';
      } else if (parentClasses.includes('assistant') || messageElement.querySelector('[alt*="assistant"]')) {
        role = 'assistant';
      }

      // Alternative: check for specific markers
      if (role === 'unknown') {
        const hasUserMarker = messageElement.textContent.startsWith('Human:') ||
                             messageElement.textContent.startsWith('You:');
        const hasAssistantMarker = messageElement.textContent.startsWith('Assistant:') ||
                                  messageElement.textContent.startsWith('Claude:');

        if (hasUserMarker) role = 'user';
        else if (hasAssistantMarker) role = 'assistant';
      }

      const content = EMRY.extractText(messageElement);

      if (content && content.length > 10 && role !== 'unknown') {
        EMRY.queueMessage(role, content, {
          detector: 'claude-primary'
        });
      }
    });
  }

  /**
   * Alternative detection (more generic)
   */
  function captureAlternative() {
    // Look for the main conversation container
    const conversationElements = document.querySelectorAll([
      '[class*="message"]',
      '[class*="chat"]',
      '[class*="turn"]',
      'div[class*="font-claude"]'
    ].join(','));

    conversationElements.forEach(element => {
      const text = element.textContent || '';
      const classes = element.className.toLowerCase();

      let role = 'unknown';

      // Heuristic detection
      if (classes.includes('user') || classes.includes('human')) {
        role = 'user';
      } else if (classes.includes('assistant') || classes.includes('claude') || classes.includes('ai')) {
        role = 'assistant';
      }

      // Check for avatar/icon indicators
      const hasUserIcon = element.querySelector('img[alt*="user"], [aria-label*="user"]');
      const hasAssistantIcon = element.querySelector('img[alt*="assistant"], img[alt*="claude"], [aria-label*="assistant"]');

      if (hasUserIcon) role = 'user';
      else if (hasAssistantIcon) role = 'assistant';

      const content = EMRY.extractText(element);

      if (content && content.length > 10 && role !== 'unknown') {
        EMRY.queueMessage(role, content, {
          detector: 'claude-fallback'
        });
      }
    });
  }

  /**
   * Advanced detection using DOM tree analysis
   */
  function captureAdvanced() {
    // Claude often uses a consistent DOM structure
    // Find the main chat container
    const mainContent = document.querySelector('main, [role="main"], .conversation');

    if (!mainContent) return;

    // Look for message groups
    const messageGroups = mainContent.querySelectorAll('div[class*="group"], div[class*="flex"]');

    messageGroups.forEach(group => {
      // Skip if too small
      const text = EMRY.extractText(group);
      if (!text || text.length < 20) return;

      // Analyze structure to determine role
      const depth = getDepth(group);
      const hasCode = group.querySelector('code, pre') !== null;
      const isLongForm = text.length > 100;

      // Assistant messages typically longer and have code
      let role = (isLongForm || hasCode) ? 'assistant' : 'user';

      // Look for definitive markers
      if (group.querySelector('[aria-label*="user"]')) role = 'user';
      if (group.querySelector('[aria-label*="assistant"]') || group.querySelector('[aria-label*="claude"]')) role = 'assistant';

      EMRY.queueMessage(role, text, {
        detector: 'claude-advanced',
        has_code: hasCode,
        depth: depth
      });
    });
  }

  function getDepth(element) {
    let depth = 0;
    let current = element;
    while (current.parentElement) {
      depth++;
      current = current.parentElement;
    }
    return depth;
  }

  /**
   * Start watching for messages
   */
  function startWatching() {
    // Initial capture with all methods
    captureMessages();
    captureAlternative();
    captureAdvanced();

    // Watch for changes
    EMRY.createObserver(() => {
      captureMessages();
      captureAlternative();
      captureAdvanced();
    });

    // Periodic sweep
    setInterval(() => {
      captureMessages();
      captureAlternative();
    }, 2000);

    console.log('[EMRY] Claude watching for messages');
  }

  // Start when ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', startWatching);
  } else {
    startWatching();
  }

})();
