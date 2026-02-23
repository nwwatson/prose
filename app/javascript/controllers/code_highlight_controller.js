import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  async connect() {
    const blocks = this.element.querySelectorAll("pre code")
    if (blocks.length === 0) return

    const hljs = (await import("highlight.js")).default

    blocks.forEach((block) => {
      hljs.highlightElement(block)
      this.addCopyButton(block.closest("pre"))
    })
  }

  addCopyButton(pre) {
    if (!pre || pre.querySelector(".code-copy-btn")) return

    pre.style.position = "relative"

    const button = document.createElement("button")
    button.className = "code-copy-btn"
    button.textContent = "Copy"
    button.type = "button"
    button.addEventListener("click", () => this.copyCode(pre, button))

    pre.appendChild(button)
  }

  async copyCode(pre, button) {
    const code = pre.querySelector("code")
    if (!code) return

    try {
      await navigator.clipboard.writeText(code.textContent)
      button.textContent = "Copied!"
      setTimeout(() => { button.textContent = "Copy" }, 2000)
    } catch {
      button.textContent = "Failed"
      setTimeout(() => { button.textContent = "Copy" }, 2000)
    }
  }
}
