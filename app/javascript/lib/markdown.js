// Shared, escaping markdown-to-HTML renderer used by the AI chat and comment
// preview Stimulus controllers. Input is always untrusted (AI output, user
// input) so it is HTML-escaped before any markdown rule runs — none of the
// rules below introduce raw "<"/">" from the source text, only from their
// own literal replacement markup.

import { escapeHtml } from "lib/dom"

const THEMES = {
  chat: {
    codeBlock: '<pre class="bg-gray-800 text-gray-100 rounded-md p-3 my-2 overflow-x-auto text-xs"><code>$2</code></pre>',
    inlineCode: '<code class="bg-gray-200 px-1 rounded text-sm">$1</code>',
    headers: true,
    groupedLists: false,
    links: false,
    blockquotes: false,
  },
  comment: {
    codeBlock: '<pre class="bg-gray-100 dark:bg-gray-800 text-gray-800 dark:text-gray-200 rounded-md p-3 my-2 overflow-x-auto text-xs"><code>$2</code></pre>',
    inlineCode: '<code class="bg-gray-100 dark:bg-gray-800 px-1 rounded text-sm">$1</code>',
    headers: false,
    groupedLists: true,
    links: true,
    blockquotes: true,
  },
}

export function renderMarkdown(text, { streaming = false, theme = "chat" } = {}) {
  const config = THEMES[theme]
  let html = escapeHtml(text)

  html = html.replace(/```(\w*)\n([\s\S]*?)```/g, config.codeBlock)
  if (streaming) {
    // Render an unterminated code block at the end of the stream so far.
    html = html.replace(/```(\w*)\n([\s\S]+)$/g, config.codeBlock)
  }

  html = html
    .replace(/`([^`]+)`/g, config.inlineCode)
    .replace(/\*\*(.+?)\*\*/g, "<strong>$1</strong>")
    .replace(/\*(.+?)\*/g, "<em>$1</em>")

  if (config.headers) {
    html = html
      .replace(/^### (.+)$/gm, '<h3 class="font-semibold mt-3 mb-1">$1</h3>')
      .replace(/^## (.+)$/gm, '<h2 class="font-semibold text-base mt-3 mb-1">$1</h2>')
      .replace(/^# (.+)$/gm, '<h1 class="font-bold text-lg mt-3 mb-1">$1</h1>')
  }

  if (config.groupedLists) {
    html = html
      .replace(/(^[-*] .+$(\n|$))+/gm, (match) => {
        const items = match.trim().split("\n").map((line) => `<li>${line.replace(/^[-*] /, "")}</li>`).join("")
        return `<ul>${items}</ul>`
      })
      .replace(/(^\d+\. .+$(\n|$))+/gm, (match) => {
        const items = match.trim().split("\n").map((line) => `<li>${line.replace(/^\d+\. /, "")}</li>`).join("")
        return `<ol>${items}</ol>`
      })
  } else {
    html = html
      .replace(/^[-*] (.+)$/gm, '<li class="ml-4 list-disc">$1</li>')
      .replace(/^\d+\. (.+)$/gm, '<li class="ml-4 list-decimal">$1</li>')
  }

  if (config.links) {
    html = html.replace(/\[([^\]]+)\]\(([^)]+)\)/g, '<a href="$2" class="text-ink-blue underline" rel="nofollow noopener" target="_blank">$1</a>')
  }

  if (config.blockquotes) {
    html = html.replace(/^&gt; (.+)$/gm, '<blockquote class="border-l-4 border-gray-300 pl-3 italic text-gray-600 dark:text-gray-400">$1</blockquote>')
  }

  return html
    .replace(/\n\n/g, '</p><p class="mt-2">')
    .replace(/\n/g, "<br>")
}
