import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["preview"]
  static values = { colors: Object }

  update(event) {
    const key = event.target.value
    const hex = this.colorsValue[key]
    if (hex && this.hasPreviewTarget) {
      this.previewTarget.style.backgroundColor = hex
    }
  }
}
