import { Controller } from "@hotwired/stimulus"

const YOUTUBE_PATTERN = /^https?:\/\/(www\.)?(youtube\.com\/(watch\?v=|embed\/)|youtu\.be\/|m\.youtube\.com\/watch\?v=)[\w-]+/

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
    if (!text || !YOUTUBE_PATTERN.test(text)) return

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
      .catch(err => console.error("[youtube-embed] error:", err))
  }
}
