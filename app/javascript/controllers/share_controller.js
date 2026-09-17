import { Controller } from "@hotwired/stimulus"
import { useTimeouts } from "lib/timers"

const FEEDBACK_DURATION_MS = 2000

export default class extends Controller {
  static targets = ["copyFeedback", "nativeButton"]
  static values = { url: String, title: String, copiedText: String }

  connect() {
    this.timeouts = useTimeouts()
    this.feedbackTimeout = null

    if (typeof navigator.share === "function" && this.hasNativeButtonTarget) {
      this.nativeButtonTarget.hidden = false
    }
  }

  disconnect() {
    this.timeouts.clearAll()
  }

  async copy() {
    const copied = await this.writeToClipboard(this.urlValue)
    if (copied && this.element.isConnected) this.showCopyFeedback()
  }

  async native() {
    if (typeof navigator.share !== "function") return

    try {
      await navigator.share({ title: this.titleValue, url: this.urlValue })
    } catch (error) {
      // AbortError means the reader dismissed the share sheet — not a failure.
      if (error?.name !== "AbortError") console.warn("Share failed", error)
    }
  }

  // navigator.clipboard is only exposed in secure contexts (HTTPS/localhost)
  // and can reject when permission is denied, so fall back to execCommand.
  async writeToClipboard(text) {
    if (navigator.clipboard?.writeText) {
      try {
        await navigator.clipboard.writeText(text)
        return true
      } catch {
        // fall through to the legacy path
      }
    }

    return this.legacyCopy(text)
  }

  legacyCopy(text) {
    const textarea = document.createElement("textarea")
    textarea.value = text
    textarea.setAttribute("readonly", "")
    textarea.style.position = "fixed"
    textarea.style.opacity = "0"
    document.body.appendChild(textarea)
    textarea.select()

    try {
      return document.execCommand("copy")
    } catch {
      return false
    } finally {
      textarea.remove()
    }
  }

  showCopyFeedback() {
    if (!this.hasCopyFeedbackTarget) return

    this.timeouts.clear(this.feedbackTimeout)
    this.copyFeedbackTarget.textContent = this.copiedTextValue
    this.feedbackTimeout = this.timeouts.set(() => {
      this.copyFeedbackTarget.textContent = ""
      this.feedbackTimeout = null
    }, FEEDBACK_DURATION_MS)
  }
}
