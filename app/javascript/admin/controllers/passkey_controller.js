import { Controller } from "@hotwired/stimulus"
import { csrfToken, requestJSON } from "lib/request"
import { decodeOptions, serializeCredential } from "admin/lib/webauthn"

export default class extends Controller {
  static targets = ["nameInput", "error"]
  static values = {
    authenticationOptionsUrl: String,
    verifyUrl: String,
    registrationOptionsUrl: String,
    createUrl: String,
    defaultName: String,
    authenticationFailedMessage: String,
    registrationFailedMessage: String,
    alreadyRegisteredMessage: String
  }

  connect() {
    if (!window.PublicKeyCredential) {
      this.element.style.display = "none"
    }
  }

  async authenticate(event) {
    event.preventDefault()
    this.clearError()

    try {
      const options = await requestJSON(this.authenticationOptionsUrlValue, { method: "POST" })
      const credential = await navigator.credentials.get({ publicKey: decodeOptions(options) })

      const verifyResponse = await requestJSON(this.verifyUrlValue, {
        method: "POST",
        body: { credential: serializeCredential(credential) }
      })

      if (verifyResponse.redirect_url) {
        window.Turbo.visit(verifyResponse.redirect_url)
      }
    } catch (error) {
      if (error.name === "NotAllowedError") {
        return // User cancelled
      }
      this.showError(error.message || this.authenticationFailedMessageValue)
    }
  }

  async register(event) {
    event.preventDefault()
    this.clearError()

    try {
      const options = await requestJSON(this.registrationOptionsUrlValue, { method: "POST" })
      const credential = await navigator.credentials.create({ publicKey: decodeOptions(options) })

      const name = this.hasNameInputTarget ? this.nameInputTarget.value : this.defaultNameValue

      const form = document.createElement("form")
      form.method = "POST"
      form.action = this.createUrlValue
      form.style.display = "none"

      const csrfInput = document.createElement("input")
      csrfInput.name = "authenticity_token"
      csrfInput.value = csrfToken()
      form.appendChild(csrfInput)

      const nameInput = document.createElement("input")
      nameInput.name = "name"
      nameInput.value = name
      form.appendChild(nameInput)

      const credInput = document.createElement("input")
      credInput.name = "credential"
      credInput.value = JSON.stringify(serializeCredential(credential))
      form.appendChild(credInput)

      document.body.appendChild(form)
      form.submit()
    } catch (error) {
      if (error.name === "NotAllowedError") {
        return
      }
      if (error.name === "InvalidStateError") {
        this.showError(this.alreadyRegisteredMessageValue)
        return
      }
      this.showError(error.message || this.registrationFailedMessageValue)
    }
  }

  showError(message) {
    if (this.hasErrorTarget) {
      this.errorTarget.textContent = message
      this.errorTarget.classList.remove("hidden")
    }
  }

  clearError() {
    if (this.hasErrorTarget) {
      this.errorTarget.textContent = ""
      this.errorTarget.classList.add("hidden")
    }
  }
}
