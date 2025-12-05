/**
 * EMRY Perplexity Capture
 * Handles perplexity.ai
 */

(function() {
  'use strict';

  if (!window.EMRY) {
    console.error('[EMRY] Universal helper not loaded');
    return;
  }

  const EMRY = window.EMRY;
  EMRY.init('perplexity');

  console.log('[EMRY] Perplexity capture initialized');

  function captureMessages() {
    // Perplexity-specific selectors
    const messages = document.querySelectorAll([
      '[class*="Answer"]',
      '[class*="Query"]',
      '[class*="SearchResult"]',
      'div[class*="prose"]'
    ].join(','));

    messages.forEach(element => {
      const classes = element.className.toLowerCase();
      let role = 'unknown';

      if (classes.includes('query') || classes.includes('question')) {
        role = 'user';
      } else if (classes.includes('answer') || classes.includes('result')) {
        role = 'assistant';
      }

      const content = EMRY.extractText(element);

      if (content && content.length > 15 && role !== 'unknown') {
        EMRY.queueMessage(role, content, {
          detector: 'perplexity'
        });
      }
    });
  }

  function startWatching() {
    captureMessages();

    EMRY.createObserver(() => {
      captureMessages();
    });

    setInterval(captureMessages, 2000);

    console.log('[EMRY] Perplexity watching for messages');
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', startWatching);
  } else {
    startWatching();
  }

})();
