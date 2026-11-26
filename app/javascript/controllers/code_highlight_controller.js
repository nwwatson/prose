import { Controller } from "@hotwired/stimulus"
import { copyText } from "lib/clipboard"
import { useTimeouts } from "lib/timers"

const FEEDBACK_DURATION_MS = 2000

export default class extends Controller {
  static values = { copyLabel: String, copiedLabel: String, failedLabel: String }

  async connect() {
    this.timeouts = useTimeouts()

    const blocks = this.element.querySelectorAll("pre code")
    if (blocks.length === 0) return

    const hljs = (await import("highlight.js")).default

    blocks.forEach((block) => {
      hljs.highlightElement(block)
      this.addCopyButton(block.closest("pre"))
    })
  }

  disconnect() {
    this.timeouts.clearAll()
  }

  addCopyButton(pre) {
    if (!pre || pre.querySelector(".code-copy-btn")) return

    pre.style.position = "relative"

    const button = document.createElement("button")
    button.className = "code-copy-btn"
    button.textContent = this.copyLabelValue
    button.type = "button"
    button.addEventListener("click", () => this.copyCode(pre, button))

    pre.appendChild(button)
  }

  async copyCode(pre, button) {
    const code = pre.querySelector("code")
    if (!code) return

    const copied = await copyText(code.textContent)
    if (!this.element.isConnected) return

    button.textContent = copied ? this.copiedLabelValue : this.failedLabelValue
    this.timeouts.set(() => { button.textContent = this.copyLabelValue }, FEEDBACK_DURATION_MS)
  }
}
