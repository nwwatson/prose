import { Controller } from "@hotwired/stimulus"

// Renders markdown for static (non-streaming) messages.
// Used by _message.html.erb for persisted assistant messages.
export default class extends Controller {
  static values = { raw: String }

  connect() {
    if (this.hasRawValue && this.rawValue) {
      this.element.innerHTML = this.formatMarkdown(this.rawValue)
    }
  }

  formatMarkdown(text) {
    return text
      // Code blocks
      .replace(/```(\w*)\n([\s\S]*?)```/g, '<pre class="bg-gray-800 text-gray-100 rounded-md p-3 my-2 overflow-x-auto text-xs"><code>$2</code></pre>')
      // Inline code
      .replace(/`([^`]+)`/g, '<code class="bg-gray-200 px-1 rounded text-sm">$1</code>')
      // Bold
      .replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>')
      // Italic
      .replace(/\*(.+?)\*/g, '<em>$1</em>')
      // Headers
      .replace(/^### (.+)$/gm, '<h3 class="font-semibold mt-3 mb-1">$1</h3>')
      .replace(/^## (.+)$/gm, '<h2 class="font-semibold text-base mt-3 mb-1">$1</h2>')
      .replace(/^# (.+)$/gm, '<h1 class="font-bold text-lg mt-3 mb-1">$1</h1>')
      // Unordered lists
      .replace(/^[-*] (.+)$/gm, '<li class="ml-4 list-disc">$1</li>')
      // Ordered lists
      .replace(/^\d+\. (.+)$/gm, '<li class="ml-4 list-decimal">$1</li>')
      // Paragraphs (double newlines)
      .replace(/\n\n/g, '</p><p class="mt-2">')
      // Single newlines to breaks
      .replace(/\n/g, '<br>')
  }
}
