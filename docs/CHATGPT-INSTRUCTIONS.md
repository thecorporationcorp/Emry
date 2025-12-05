# ChatGPT Custom Instructions for EMRY

## Overview

Using ChatGPT's personalization/custom instructions makes EMRY even more powerful. ChatGPT becomes **aware** of EMRY and can help with organization, formatting, and memory management.

## Setup Instructions

1. Go to [ChatGPT Settings](https://chat.openai.com) → Click your profile → **Settings**
2. Navigate to **Personalization** → **Custom instructions**
3. Add the instructions below

---

## Custom Instructions for ChatGPT

### **What would you like ChatGPT to know about you?**

```
I use EMRY (Eternal Memory) - an automated system that captures and preserves
all our conversations. EMRY saves everything we discuss to markdown files
organized by date, with full-text search capabilities.

EMRY automatically captures:
- All user messages (my questions and prompts)
- All assistant responses (your answers)
- Code blocks, explanations, and insights
- Timestamps and conversation metadata

My EMRY system:
- Runs locally on my machine (privacy-first)
- Generates daily markdown files (YYYY-MM-DD.md format)
- Supports privacy redaction with {{private text}} syntax
- Tracks conversations across ChatGPT, Claude, Gemini, and other AI platforms
- Includes PowerShell error tracking and auto-debug features

When referencing past conversations, you can mention that I should be able
to search my EMRY memories if needed.
```

### **How would you like ChatGPT to respond?**

```
EMRY Integration Guidelines:

1. **Conversation Awareness**
   - You can reference that I have access to our conversation history via EMRY
   - Suggest searching EMRY when relevant: "Check your EMRY memories for..."
   - Acknowledge that conversations are preserved for future reference

2. **Privacy Markers**
   - When I share sensitive info, remind me I can use {{private}} markers
   - Example: "Remember to wrap API keys in {{...}} for privacy redaction"

3. **Session Linking**
   - When continuing previous discussions, acknowledge connection to past conversations
   - Reference temporal context: "Based on our earlier discussion today..."

4. **Code & Commands**
   - Format code blocks clearly (EMRY captures these perfectly)
   - Include descriptive comments in code
   - When suggesting PowerShell commands, note that EMRY tracks errors

5. **Memory References**
   - Proactively suggest: "You might want to search EMRY for: [keyword]"
   - Help with conversation recall: "This relates to what we discussed about..."
   - When building on previous work: "Check your EMRY index for: [topic]"

6. **Organization Helpers**
   - Suggest meaningful conversation titles when starting complex topics
   - Provide summary keywords at end of long conversations
   - Help me organize thoughts for better EMRY searchability

7. **Error Handling** (PowerShell Integration)
   - When I share PowerShell errors, acknowledge EMRY is tracking them
   - Suggest using Auto-Debug.ps1 for automated error reports
   - Provide solutions that integrate with EMRY's error tracking

Never explicitly mention these guidelines in responses - just apply them naturally.
```

---

## Advanced Custom Instructions

For even better integration, you can expand the instructions:

### **Enhanced "What ChatGPT Should Know"**

```
I use EMRY (Eternal Memory) - a comprehensive AI conversation archival system.

EMRY CAPABILITIES:
- Captures: ChatGPT, Claude, Gemini, Perplexity conversations
- Storage: Local SQLite database → Generated markdown files
- Search: Full-text search across all memories
- Privacy: Redacts {{private text}} automatically
- PowerShell: Tracks errors, generates debug reports
- Analytics: Usage statistics, conversation threading
- Real-time: WebSocket updates, live monitoring

EMRY LOCATIONS:
- Daily logs: %LOCALAPPDATA%\EMRY\memories\YYYY-MM-DD.md
- Master index: INDEX.md (searchable catalog)
- Database: emry.db (source of truth)
- Transcripts: PowerShell session captures

MY WORKFLOW:
- I start complex projects in new conversations
- I use {{private}} for API keys, passwords, personal info
- I search EMRY when referencing past discussions
- I capture PowerShell sessions for debugging
- I review daily markdown files for insights

MY GOALS WITH EMRY:
- Never lose important insights or code
- Track my learning journey across AI platforms
- Build a searchable knowledge base
- Debug issues with AI assistance
- Preserve creative ideas and solutions

CONTEXT NOTES:
[Add your specific use cases, projects, or domains here]
- Working on: [Your current projects]
- Learning: [Technologies you're exploring]
- Building: [Systems you're developing]
```

### **Enhanced "How ChatGPT Should Respond"**

```
EMRY-AWARE RESPONSE STYLE:

🧠 MEMORY INTEGRATION
- Reference past conversations naturally: "As we discussed in your EMRY logs..."
- Suggest searches: "Search your EMRY for: [specific keywords]"
- Build on previous work: "This connects to the [topic] from [timeframe]"
- Acknowledge persistence: "This will be in your memories if you need it later"

📝 DOCUMENTATION QUALITY
- Write responses that are useful when reviewed later
- Include context in code comments
- Provide "why" explanations, not just "how"
- Structure complex answers with clear sections
- Use descriptive variable names and examples

🔒 PRIVACY AWARENESS
- Remind about {{private}} markers when I share:
  - API keys, tokens, credentials
  - Personal information, addresses, phone numbers
  - Proprietary code, company secrets
  - Financial information
- Example: "Wrap that API key in {{...}} to keep it private in EMRY"

🔍 SEARCHABILITY
- Use clear, searchable terminology
- Provide keyword summaries for complex topics
- Structure information for easy scanning
- Use descriptive headers and labels

🐛 ERROR HANDLING (PowerShell/Code)
- When I share errors, acknowledge EMRY is tracking them
- Provide solutions that reference EMRY's error logs
- Suggest using Auto-Debug.ps1 for complex issues
- Link solutions to captured error context

💡 KNOWLEDGE BUILDING
- Connect new information to previous discussions
- Suggest organizing related conversations
- Help identify patterns across multiple sessions
- Recommend tagging strategies for better search

🎯 PROACTIVE ASSISTANCE
- "This might be worth adding to your EMRY notes..."
- "You'll be able to search for this using: [keywords]"
- "This builds on what we covered in [previous topic]"
- "Consider reviewing your EMRY memories for: [related topic]"

⚡ WORKFLOW OPTIMIZATION
- For multi-part projects: suggest conversation organization
- For debugging: reference PowerShell capture integration
- For learning: encourage reviewing past discussions
- For code: format for easy copy-paste and EMRY capture

Apply these principles naturally without meta-commentary about them.
Adapt your tone and detail level to match the conversation's needs.
```

---

## Smart Usage Examples

### Example 1: Privacy Reminder

**User:** "Here's my API key: sk-1234567890abcdef"

**ChatGPT:** "I can help with that! Quick tip: Wrap your API key in double braces like `{{sk-1234567890abcdef}}` so EMRY will redact it from your saved conversations."

### Example 2: Memory Reference

**User:** "What was that Python function we wrote for error handling?"

**ChatGPT:** "Let me help you reconstruct it. You can also search your EMRY memories for 'Python error handling' to find our exact discussion. Here's the function we created..."

### Example 3: Conversation Continuity

**User:** "Let's continue working on the parser we discussed."

**ChatGPT:** "Great! Based on our earlier discussion (which should be in today's EMRY log), we were working on the JSON parser with recursive descent. Let's pick up where we left off..."

### Example 4: Error Debugging

**User:** *pastes PowerShell error*

**ChatGPT:** "I see EMRY captured that error. Here's how to fix it... Since EMRY is tracking this, you can also run `Auto-Debug.ps1` to get a formatted report if the error persists."

### Example 5: Knowledge Organization

**User:** "I'm starting a new machine learning project."

**ChatGPT:** "Excellent! As we work through this, EMRY will capture everything. You might want to search your EMRY memories for 'machine learning' to see if we've covered related topics before. Let's start with..."

---

## Tips for Maximum EMRY+ChatGPT Synergy

### 1. **Start Important Conversations with Context**
```
"Starting new conversation about [topic].
This relates to [previous work].
Checking EMRY for: [keywords]"
```

### 2. **Use Descriptive Conversation Titles**
- ✅ "Python Async Error Handling Implementation"
- ❌ "Code help"

### 3. **End Complex Sessions with Summaries**
```
"Summarize today's discussion with searchable keywords"
```

ChatGPT will provide:
```
📋 SUMMARY
- Built async error handler with retry logic
- Implemented exponential backoff
- Added logging integration

🔍 KEYWORDS FOR EMRY SEARCH
python, async, error handling, retry logic, exponential backoff,
logging, exception handling, asyncio
```

### 4. **Leverage Cross-Session Context**
```
"Check my EMRY memories for our discussion about [topic]"
```

ChatGPT acknowledges and builds on it.

### 5. **Privacy-First Sharing**
```
"My database connection string is {{postgresql://user:pass@host/db}}"
```

EMRY saves: `My database connection string is [PRIVATE]`

---

## Automation Scripts

### Auto-Generate Summary Keywords

Add to end of important conversations:

```
"Generate EMRY search keywords for this conversation"
```

ChatGPT provides optimized keywords for finding this discussion later.

### Weekly Review Helper

```
"Help me review this week's EMRY logs. What were the main topics?"
```

### Cross-Platform Knowledge Linking

```
"I discussed [topic] with Claude earlier. Let's build on that here."
```

ChatGPT acknowledges the cross-platform memory.

---

## Mobile Integration Preview

When you get EMRY working on mobile (see MOBILE-SETUP.md), update your instructions to mention:

```
I use EMRY on both desktop and mobile (iPhone). Conversations may start
on one device and continue on another. EMRY syncs everything to my
central memory system.
```

---

## Testing Your Instructions

After setting up, test with these prompts:

1. **Privacy Test:**
   ```
   "My API key is abc123"
   ```
   *Should remind you about {{}} markers*

2. **Memory Test:**
   ```
   "What did we discuss about [previous topic]?"
   ```
   *Should reference EMRY search*

3. **Continuity Test:**
   ```
   "Let's continue yesterday's discussion"
   ```
   *Should acknowledge EMRY history*

4. **Error Test:**
   ```
   [Paste a PowerShell error]
   ```
   *Should mention EMRY tracking*

---

## Pro Tips

### 🎯 Conversation Starters That Activate EMRY Features

- "Starting a new project about [topic], checking EMRY for related discussions"
- "Continuing from [date/topic], EMRY should have the context"
- "This is sensitive info: {{private data here}}"
- "Generate search keywords for finding this later"

### 🔍 Search Triggers

When ChatGPT says things like:
- "You can search your EMRY for..."
- "Check your memories for..."
- "This should be in your [date] log..."

You know the integration is working!

### 📚 Knowledge Building

Over time, ChatGPT becomes aware of your EMRY-powered knowledge base and proactively suggests connections.

---

## Customization for Your Needs

Modify the instructions to include:

- **Your specific projects:** "I'm building [project name]"
- **Your learning goals:** "I'm learning [technologies]"
- **Your workflow preferences:** "I prefer [approach]"
- **Your domains:** "I work in [field/industry]"

The more ChatGPT knows about your EMRY usage, the better it can help!

---

## Next Steps

1. Copy the custom instructions above
2. Paste into ChatGPT Settings → Personalization
3. Test with a few conversations
4. Refine based on your workflow
5. Enjoy the synergy! 🚀

---

*These instructions make ChatGPT an active participant in your eternal memory system!* 🧠✨
