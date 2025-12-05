/**
 * EMRY ChatGPT Capture
 * Handles chat.openai.com and chatgpt.com
 */

(function() {
  'use strict';

  if (!window.EMRY) {
    console.error('[EMRY] Universal helper not loaded');
    return;
  }

  const EMRY = window.EMRY;
  EMRY.init('chatgpt');

  console.log('[EMRY] ChatGPT capture initialized');

  /**
   * Extract messages from ChatGPT's DOM
   */
  function captureMessages() {
    // ChatGPT uses data-message-author-role attribute
    const messages = document.querySelectorAll('[data-message-author-role]');

    messages.forEach(messageElement => {
      const role = messageElement.getAttribute('data-message-author-role');
      const messageId = messageElement.getAttribute('data-message-id');

      // Use message ID for deduplication if available
      if (messageId && EMRY.seenMessages.has(messageId)) {
        return;
      }

      // Extract content
      const content = EMRY.extractText(messageElement);

      if (content && content.length > 10) {
        EMRY.queueMessage(role, content, {
          message_id: messageId,
          detector: 'chatgpt-primary'
        });

        if (messageId) {
          EMRY.seenMessages.add(messageId);
        }
      }
    });
  }

  /**
   * Alternative detection method (fallback for UI changes)
   */
  function captureAlternative() {
    // Look for articles containing messages
    const articles = document.querySelectorAll('article, [data-testid^="conversation-turn"]');

    articles.forEach(article => {
      // Determine role by presence of specific markers
      const isUser = article.querySelector('[data-message-author-role="user"]') !== null;
      const isAssistant = article.querySelector('[data-message-author-role="assistant"]') !== null;

      let role = 'unknown';
      if (isUser) role = 'user';
      else if (isAssistant) role = 'assistant';

      if (role !== 'unknown') {
        const content = EMRY.extractText(article);
        if (content && content.length > 10) {
          EMRY.queueMessage(role, content, {
            detector: 'chatgpt-fallback'
          });
        }
      }
    });
  }

  /**
   * Watch for new messages
   */
  function startWatching() {
    // Initial capture
    captureMessages();
    captureAlternative();

    // Watch for changes
    const observer = EMRY.createObserver(() => {
      captureMessages();
      captureAlternative();
    });

    // Periodic sweep (in case mutation observer misses something)
    setInterval(() => {
      captureMessages();
    }, 2000);

    console.log('[EMRY] ChatGPT watching for messages');
  }

  // Start when DOM is ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', startWatching);
  } else {
    startWatching();
  }

})();
