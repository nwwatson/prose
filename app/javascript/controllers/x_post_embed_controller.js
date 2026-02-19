import { Controller } from "@hotwired/stimulus"

const X_POST_PATTERN = /^https?:\/\/(x\.com|twitter\.com)\/\w+\/status\/\d+/

export default class extends Controller {
  static values = { url: String }

  connect() {
    this.boundHandlePaste = this.handlePaste.bind(this)
    this.element.addEventListener("paste", this.boundHandlePaste, true)
  }

  disconnect() {
    this.element.removeEventListener("paste", this.boundHandlePaste, true)
  }

  handlePaste(event) {
    const text = event.clipboardData?.getData("text/plain")?.trim()
    if (!text || !X_POST_PATTERN.test(text)) return

    event.preventDefault()
    event.stopPropagation()

    const editor = this.element.querySelector("lexxy-editor")
    if (!editor) return

    fetch(this.urlValue, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify({ url: text })
    })
      .then(r => r.json())
      .then(({ sgid, html }) => {
        const attachment = document.createElement("action-text-attachment")
        attachment.setAttribute("sgid", sgid)
        attachment.setAttribute("content-type", "text/html")
        attachment.setAttribute("content", JSON.stringify(html))
        editor.contents.insertHtml(attachment.outerHTML)
      })
      .catch(err => console.error("[x-post-embed] error:", err))
  }
}
