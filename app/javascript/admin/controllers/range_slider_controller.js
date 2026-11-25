import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "value"]
  static values = { suffix: { type: String, default: "" } }

  connect() {
    this.updateDisplay()
  }

  updateDisplay() {
    const input = this.inputTarget
    const percent = ((input.value - input.min) / (input.max - input.min)) * 100

    input.style.background = `linear-gradient(to right, #3b82f6 ${percent}%, #e5e7eb ${percent}%)`
    this.valueTarget.textContent = `${input.value}${this.suffixValue}`
  }
}
