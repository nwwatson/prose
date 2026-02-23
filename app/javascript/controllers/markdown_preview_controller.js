import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["textarea", "preview", "writeTab", "previewTab"]

  showWrite() {
    this.textareaTarget.classList.remove("hidden")
    this.previewTarget.classList.add("hidden")
    this.writeTabTarget.classList.add("border-gray-900", "text-gray-900", "dark:border-gray-100", "dark:text-gray-100")
    this.writeTabTarget.classList.remove("border-transparent", "text-gray-500")
    this.previewTabTarget.classList.remove("border-gray-900", "text-gray-900", "dark:border-gray-100", "dark:text-gray-100")
    this.previewTabTarget.classList.add("border-transparent", "text-gray-500")
  }

  showPreview() {
    const markdown = this.textareaTarget.value
    this.previewTarget.innerHTML = markdown.trim()
      ? this.formatMarkdown(markdown)
      : '<p class="text-gray-400 italic">Nothing to preview</p>'

    this.textareaTarget.classList.add("hidden")
    this.previewTarget.classList.remove("hidden")
    this.previewTabTarget.classList.add("border-gray-900", "text-gray-900", "dark:border-gray-100", "dark:text-gray-100")
    this.previewTabTarget.classList.remove("border-transparent", "text-gray-500")
    this.writeTabTarget.classList.remove("border-gray-900", "text-gray-900", "dark:border-gray-100", "dark:text-gray-100")
    this.writeTabTarget.classList.add("border-transparent", "text-gray-500")
  }

  formatMarkdown(text) {
    return text
      // Code blocks
      .replace(/```(\w*)\n([\s\S]*?)```/g, '<pre class="bg-gray-100 dark:bg-gray-800 text-gray-800 dark:text-gray-200 rounded-md p-3 my-2 overflow-x-auto text-xs"><code>$2</code></pre>')
      // Inline code
      .replace(/`([^`]+)`/g, '<code class="bg-gray-100 dark:bg-gray-800 px-1 rounded text-sm">$1</code>')
      // Bold
      .replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>')
      // Italic
      .replace(/\*(.+?)\*/g, '<em>$1</em>')
      // Unordered lists (group consecutive lines)
      .replace(/(^[-*] .+$(\n|$))+/gm, (match) => {
        const items = match.trim().split('\n').map(line => `<li>${line.replace(/^[-*] /, '')}</li>`).join('')
        return `<ul>${items}</ul>`
      })
      // Ordered lists (group consecutive lines)
      .replace(/(^\d+\. .+$(\n|$))+/gm, (match) => {
        const items = match.trim().split('\n').map(line => `<li>${line.replace(/^\d+\. /, '')}</li>`).join('')
        return `<ol>${items}</ol>`
      })
      // Links
      .replace(/\[([^\]]+)\]\(([^)]+)\)/g, '<a href="$2" class="text-ink-blue underline" rel="nofollow noopener" target="_blank">$1</a>')
      // Blockquotes
      .replace(/^> (.+)$/gm, '<blockquote class="border-l-4 border-gray-300 pl-3 italic text-gray-600 dark:text-gray-400">$1</blockquote>')
      // Paragraphs (double newlines)
      .replace(/\n\n/g, '</p><p class="mt-2">')
      // Single newlines to breaks
      .replace(/\n/g, '<br>')
  }
}
