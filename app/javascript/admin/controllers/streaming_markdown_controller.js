import { Controller } from "@hotwired/stimulus"
import { renderMarkdown } from "lib/markdown"

// Progressively renders markdown as raw text chunks stream in.
// Raw chunks are appended to `sourceTarget` (hidden) by Turbo Stream broadcasts.
// A MutationObserver watches for new child nodes and re-renders the accumulated
// text as HTML into `outputTarget` on each batch of mutations.
export default class extends Controller {
  static targets = ["source", "output"]

  connect() {
    this.renderPending = false
    this.observer = new MutationObserver(() => this.scheduleRender())
    this.observer.observe(this.sourceTarget, { childList: true, characterData: true, subtree: true })
  }

  disconnect() {
    this.observer?.disconnect()
  }

  scheduleRender() {
    if (this.renderPending) return
    this.renderPending = true
    requestAnimationFrame(() => {
      this.render()
      this.renderPending = false
    })
  }

  render() {
    const raw = this.sourceTarget.textContent || ""
    this.outputTarget.innerHTML = renderMarkdown(raw, { streaming: true, theme: "chat" })
    this.dispatch("rendered")
  }
}
