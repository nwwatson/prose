import { Controller } from "@hotwired/stimulus"
import { renderMarkdown } from "lib/markdown"

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
      ? renderMarkdown(markdown, { theme: "comment" })
      : '<p class="text-gray-400 italic">Nothing to preview</p>'

    this.textareaTarget.classList.add("hidden")
    this.previewTarget.classList.remove("hidden")
    this.previewTabTarget.classList.add("border-gray-900", "text-gray-900", "dark:border-gray-100", "dark:text-gray-100")
    this.previewTabTarget.classList.remove("border-transparent", "text-gray-500")
    this.writeTabTarget.classList.remove("border-gray-900", "text-gray-900", "dark:border-gray-100", "dark:text-gray-100")
    this.writeTabTarget.classList.add("border-transparent", "text-gray-500")
  }
}
