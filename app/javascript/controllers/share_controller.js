import { Controller } from "@hotwired/stimulus"
import { copyText } from "lib/clipboard"
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
    const copied = await copyText(this.urlValue)
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
