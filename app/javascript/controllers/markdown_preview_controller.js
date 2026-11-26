import { Controller } from "@hotwired/stimulus"
import { escapeHtml } from "lib/dom"
import { renderMarkdown } from "lib/markdown"

const ACTIVE_TAB_CLASS = "comment-form__tab--active"

export default class extends Controller {
  static targets = ["textarea", "preview", "writeTab", "previewTab"]
  static values = { emptyMessage: String }

  showWrite() {
    this.#show({ preview: false })
  }

  showPreview() {
    const markdown = this.textareaTarget.value
    this.previewTarget.innerHTML = markdown.trim()
      ? renderMarkdown(markdown, { theme: "comment" })
      : `<p class="text-gray-400 italic">${escapeHtml(this.emptyMessageValue)}</p>`

    this.#show({ preview: true })
  }

  // Uses the `hidden` attribute, not the utility class: unlayered component CSS
  // (.form-input's `display: block`) outranks Tailwind's `.hidden`.
  #show({ preview }) {
    this.textareaTarget.hidden = preview
    this.previewTarget.hidden = !preview
    this.writeTabTarget.classList.toggle(ACTIVE_TAB_CLASS, !preview)
    this.previewTabTarget.classList.toggle(ACTIVE_TAB_CLASS, preview)
  }
}
