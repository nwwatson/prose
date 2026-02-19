import { Controller } from "@hotwired/stimulus"

// Progressively renders markdown as raw text chunks stream in.
// Raw chunks are appended to `sourceTarget` (hidden) by Turbo Stream broadcasts.
// A MutationObserver watches for new child nodes and re-renders the accumulated
// text as HTML into `outputTarget` on each batch of mutations.
export default class extends Controller {
  static targets = ["source", "output"]

  connect() {
    this.renderPending = false
    this.observer = new MutationObserver(() => this.scheduleRender())
    this.observer.observe(this.sourceTarget, { childList: true, characterData: true, subtree: true })
  }

  disconnect() {
    this.observer?.disconnect()
  }

  scheduleRender() {
    if (this.renderPending) return
    this.renderPending = true
    requestAnimationFrame(() => {
      this.render()
      this.renderPending = false
    })
  }

  render() {
    const raw = this.sourceTarget.textContent || ""
    this.outputTarget.innerHTML = this.formatMarkdown(raw)
    this.scrollParent()
  }

  scrollParent() {
    const container = this.element.closest("[data-ai-panel-target='messagesContainer']")
    if (container) {
      container.scrollTop = container.scrollHeight
    }
  }

  formatMarkdown(text) {
    return text
      // Code blocks (complete)
      .replace(/```(\w*)\n([\s\S]*?)```/g, '<pre class="bg-gray-800 text-gray-100 rounded-md p-3 my-2 overflow-x-auto text-xs"><code>$2</code></pre>')
      // Incomplete code block at end of stream — render what we have so far
      .replace(/```(\w*)\n([\s\S]+)$/g, '<pre class="bg-gray-800 text-gray-100 rounded-md p-3 my-2 overflow-x-auto text-xs"><code>$2</code></pre>')
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
