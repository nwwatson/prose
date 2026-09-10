import { Controller } from "@hotwired/stimulus"
import { requestJSON } from "lib/request"
import { insertAttachment } from "lib/action_text"

const PROVIDERS = [
  { name: "xPost", pattern: /^https?:\/\/(x\.com|twitter\.com)\/\w+\/status\/\d+/ },
  { name: "youtube", pattern: /^https?:\/\/(www\.)?(youtube\.com\/(watch\?v=|embed\/)|youtu\.be\/|m\.youtube\.com\/watch\?v=)[\w-]+/ }
]

export default class extends Controller {
  static values = { urls: Object }

  connect() {
    this.boundHandlePaste = this.handlePaste.bind(this)
    this.element.addEventListener("paste", this.boundHandlePaste, true)
  }

  disconnect() {
    this.element.removeEventListener("paste", this.boundHandlePaste, true)
  }

  handlePaste(event) {
    const text = event.clipboardData?.getData("text/plain")?.trim()
    if (!text) return

    const provider = PROVIDERS.find(({ pattern }) => pattern.test(text))
    if (!provider) return

    const url = this.urlsValue[provider.name]
    if (!url) return

    event.preventDefault()
    event.stopPropagation()

    const editor = this.element.querySelector("lexxy-editor")
    if (!editor) return

    requestJSON(url, { method: "POST", body: { url: text } })
      .then(({ sgid, html }) => insertAttachment(editor, { sgid, html }))
      .catch(err => console.error("[paste-embed] error:", err))
  }
}
