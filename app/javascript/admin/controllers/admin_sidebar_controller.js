import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sidebar", "backdrop"]

  connect() {
    this.boundKeydown = this.handleKeydown.bind(this)
    document.addEventListener("keydown", this.boundKeydown)

    this.boundTurboVisit = this.close.bind(this)
    document.addEventListener("turbo:before-visit", this.boundTurboVisit)
  }

  disconnect() {
    document.removeEventListener("keydown", this.boundKeydown)
    document.removeEventListener("turbo:before-visit", this.boundTurboVisit)
  }

  open() {
    this.sidebarTarget.classList.remove("-translate-x-full")
    this.sidebarTarget.classList.add("translate-x-0")
    this.backdropTarget.classList.remove("hidden")
    requestAnimationFrame(() => {
      this.backdropTarget.classList.remove("opacity-0")
    })
    document.body.classList.add("overflow-hidden")
  }

  close() {
    this.sidebarTarget.classList.remove("translate-x-0")
    this.sidebarTarget.classList.add("-translate-x-full")
    this.backdropTarget.classList.add("opacity-0")
    this.sidebarTarget.addEventListener("transitionend", () => {
      this.backdropTarget.classList.add("hidden")
    }, { once: true })
    document.body.classList.remove("overflow-hidden")
  }

  handleKeydown(event) {
    if (event.key === "Escape" && !this.sidebarTarget.classList.contains("-translate-x-full")) {
      this.close()
    }
  }
}
