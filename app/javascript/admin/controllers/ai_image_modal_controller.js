import { Controller } from "@hotwired/stimulus"
import { requestTurboStream } from "lib/request"

// AI featured-image requests. Showing and hiding the dialog is the `modal`
// controller mounted on the same element; it fires `modal:opened`, which
// triggers suggestPrompt.
export default class extends Controller {
  static values = {
    suggestUrl: String,
    generateUrl: String
  }

  suggestPrompt() {
    requestTurboStream(this.suggestUrlValue, { method: "POST" })
  }

  generate(event) {
    event.preventDefault()
    const formData = new FormData(event.currentTarget)
    requestTurboStream(this.generateUrlValue, { method: "POST", body: formData })
  }

  reload() {
    window.Turbo.visit(window.location.href)
  }
}
