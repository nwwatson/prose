import { Controller } from "@hotwired/stimulus"

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
    const csrfToken = document.querySelector("meta[name='csrf-token']")?.content
    fetch(this.suggestUrlValue, {
      method: "POST",
      headers: {
        "X-CSRF-Token": csrfToken,
        "Accept": "text/vnd.turbo-stream.html"
      }
    })
    .then(response => response.text())
    .then(html => {
      Turbo.renderStreamMessage(html)
    })
  }

  generate(event) {
    event.preventDefault()
    const form = event.currentTarget
    const formData = new FormData(form)
    const csrfToken = document.querySelector("meta[name='csrf-token']")?.content

    fetch(this.generateUrlValue, {
      method: "POST",
      headers: {
        "X-CSRF-Token": csrfToken,
        "Accept": "text/vnd.turbo-stream.html"
      },
      body: formData
    })
    .then(response => response.text())
    .then(html => {
      Turbo.renderStreamMessage(html)
    })
  }

  saveAndClose() {
    this.close()
    window.Turbo.visit(window.location.href)
  }

  regenerate() {
    this.suggestPrompt()
  }
}
