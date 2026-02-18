import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel", "overlay"]

  connect() {
    this.boundKeydown = this.keydown.bind(this)
    document.addEventListener("keydown", this.boundKeydown)
  }

  disconnect() {
    document.removeEventListener("keydown", this.boundKeydown)
  }

  toggle() {
    if (this.panelTarget.classList.contains("translate-x-full")) {
      this.open()
    } else {
      this.close()
    }
  }

  open() {
    this.overlayTarget.classList.remove("hidden")
    requestAnimationFrame(() => {
      this.overlayTarget.classList.remove("opacity-0")
      this.panelTarget.classList.remove("translate-x-full")
      this.panelTarget.classList.add("translate-x-0")
    })
  }

  close() {
    this.overlayTarget.classList.add("opacity-0")
    this.panelTarget.classList.remove("translate-x-0")
    this.panelTarget.classList.add("translate-x-full")
    this.panelTarget.addEventListener("transitionend", () => {
      this.overlayTarget.classList.add("hidden")
    }, { once: true })
  }

  keydown(event) {
    if (event.key === "Escape" && !this.panelTarget.classList.contains("translate-x-full")) {
      this.close()
    }
  }
}
