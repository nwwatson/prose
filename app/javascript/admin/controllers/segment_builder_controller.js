import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { countUrl: String }

  refresh() {
    if (!this.countUrlValue) return

    const form = this.element
    const formData = new FormData(form)
    const params = new URLSearchParams()

    for (const [key, value] of formData.entries()) {
      if (key.startsWith("segment[") && key !== "segment[name]" && key !== "segment[description]") {
        params.append(key, value)
      }
    }

    const url = `${this.countUrlValue}?${params.toString()}`
    const frame = document.getElementById("segment_count")
    if (frame) {
      frame.src = url
    }
  }
}
