import { Controller } from "@hotwired/stimulus"
import { csrfToken, requestJSON } from "lib/request"
import { decodeOptions, serializeCredential } from "admin/lib/webauthn"

export default class extends Controller {
  static targets = ["nameInput", "error"]

  connect() {
    if (!window.PublicKeyCredential) {
      this.element.style.display = "none"
    }
  }

  async authenticate(event) {
    event.preventDefault()
    this.clearError()

    try {
      const options = await requestJSON("/admin/passkey_authentication/options", { method: "POST" })
      const credential = await navigator.credentials.get({ publicKey: decodeOptions(options) })

      const verifyResponse = await requestJSON("/admin/passkey_authentication/verify", {
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
      this.showError(error.message || "Passkey authentication failed.")
    }
  }

  async register(event) {
    event.preventDefault()
    this.clearError()

    try {
      const options = await requestJSON("/admin/passkeys/registration_options", { method: "POST" })
      const credential = await navigator.credentials.create({ publicKey: decodeOptions(options) })

      const name = this.hasNameInputTarget ? this.nameInputTarget.value : "Passkey"

      const form = document.createElement("form")
      form.method = "POST"
      form.action = "/admin/passkeys"
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
        this.showError("This passkey is already registered.")
        return
      }
      this.showError(error.message || "Passkey registration failed.")
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
