import { Controller } from "@hotwired/stimulus"
import { requestTurboStream } from "lib/request"

export default class extends Controller {
  static targets = ["backdrop", "dialog", "content", "promptInput"]
  static values = {
    suggestUrl: String,
    generateUrl: String
  }

  open() {
    this.backdropTarget.classList.remove("hidden")
    this.dialogTarget.classList.remove("hidden")
    document.body.classList.add("overflow-hidden")
    this.suggestPrompt()
  }

  close() {
    this.backdropTarget.classList.add("hidden")
    this.dialogTarget.classList.add("hidden")
    document.body.classList.remove("overflow-hidden")
  }

  cancel() {
    this.close()
  }

  suggestPrompt() {
    requestTurboStream(this.suggestUrlValue, { method: "POST" })
  }

  generate(event) {
    event.preventDefault()
    const formData = new FormData(event.currentTarget)
    requestTurboStream(this.generateUrlValue, { method: "POST", body: formData })
  }

  saveAndClose() {
    this.close()
    window.Turbo.visit(window.location.href)
  }

  regenerate() {
    this.suggestPrompt()
  }
}
