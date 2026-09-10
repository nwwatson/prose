import { Controller } from "@hotwired/stimulus"
import { useTimeouts } from "lib/timers"

export default class extends Controller {
  static targets = ["copyFeedback", "nativeButton"]
  static values = { url: String, title: String }

  connect() {
    this.timeouts = useTimeouts()

    if (navigator.share && this.hasNativeButtonTarget) {
      this.nativeButtonTarget.hidden = false
    }
  }

  disconnect() {
    this.timeouts.clearAll()
  }

  copy() {
    navigator.clipboard.writeText(this.urlValue).then(() => {
      if (!this.hasCopyFeedbackTarget) return

      this.copyFeedbackTarget.hidden = false
      this.timeouts.set(() => {
        this.copyFeedbackTarget.hidden = true
      }, 2000)
    })
  }

  native() {
    navigator.share({ title: this.titleValue, url: this.urlValue })
  }
}
