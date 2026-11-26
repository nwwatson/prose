import { Controller } from "@hotwired/stimulus"
import { fadeIn, fadeOut } from "admin/lib/transition"

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

  get isOpen() {
    return !this.sidebarTarget.classList.contains("-translate-x-full")
  }

  open() {
    this.sidebarTarget.classList.remove("-translate-x-full")
    this.sidebarTarget.classList.add("translate-x-0")
    fadeIn(this.backdropTarget)
    document.body.classList.add("overflow-hidden")
  }

  close() {
    // Also runs on every turbo:before-visit, usually with the sidebar closed.
    if (!this.isOpen) return

    this.sidebarTarget.classList.remove("translate-x-0")
    this.sidebarTarget.classList.add("-translate-x-full")
    fadeOut(this.backdropTarget)
    document.body.classList.remove("overflow-hidden")
  }

  handleKeydown(event) {
    if (event.key === "Escape" && this.isOpen) this.close()
  }
}
