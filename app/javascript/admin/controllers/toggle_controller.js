import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["checkbox", "track", "knob"]

  connect() {
    this.render()
  }

  toggle() {
    this.checkboxTarget.checked = !this.checkboxTarget.checked
    this.checkboxTarget.dispatchEvent(new Event("change", { bubbles: true }))
    this.render()
  }

  render() {
    const on = this.checkboxTarget.checked

    if (on) {
      this.trackTarget.classList.add("bg-blue-600")
      this.trackTarget.classList.remove("bg-gray-200")
      this.knobTarget.classList.add("translate-x-5")
      this.knobTarget.classList.remove("translate-x-0")
    } else {
      this.trackTarget.classList.remove("bg-blue-600")
      this.trackTarget.classList.add("bg-gray-200")
      this.knobTarget.classList.remove("translate-x-5")
      this.knobTarget.classList.add("translate-x-0")
    }
  }
}
