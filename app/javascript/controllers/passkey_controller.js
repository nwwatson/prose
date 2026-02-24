import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["authButton", "registerButton", "nameInput", "error"]

  connect() {
    if (!window.PublicKeyCredential) {
      this.element.style.display = "none"
    }
  }

  async authenticate(event) {
    event.preventDefault()
    this.clearError()

    try {
      const optionsResponse = await this.fetchJSON("/admin/passkey_authentication/options", { method: "POST" })
      optionsResponse.challenge = this.base64urlToBuffer(optionsResponse.challenge)

      if (optionsResponse.allowCredentials) {
        optionsResponse.allowCredentials = optionsResponse.allowCredentials.map(cred => ({
          ...cred,
          id: this.base64urlToBuffer(cred.id)
        }))
      }

      const credential = await navigator.credentials.get({ publicKey: optionsResponse })

      const verifyResponse = await this.fetchJSON("/admin/passkey_authentication/verify", {
        method: "POST",
        body: JSON.stringify({
          credential: {
            id: credential.id,
            rawId: this.bufferToBase64url(credential.rawId),
            type: credential.type,
            response: {
              authenticatorData: this.bufferToBase64url(credential.response.authenticatorData),
              clientDataJSON: this.bufferToBase64url(credential.response.clientDataJSON),
              signature: this.bufferToBase64url(credential.response.signature),
              userHandle: credential.response.userHandle ? this.bufferToBase64url(credential.response.userHandle) : null
            },
            clientExtensionResults: credential.getClientExtensionResults()
          }
        })
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
      const optionsResponse = await this.fetchJSON("/admin/passkeys/registration_options", { method: "POST" })
      optionsResponse.challenge = this.base64urlToBuffer(optionsResponse.challenge)
      optionsResponse.user.id = this.base64urlToBuffer(optionsResponse.user.id)

      if (optionsResponse.excludeCredentials) {
        optionsResponse.excludeCredentials = optionsResponse.excludeCredentials.map(cred => ({
          ...cred,
          id: this.base64urlToBuffer(cred.id)
        }))
      }

      const credential = await navigator.credentials.create({ publicKey: optionsResponse })

      const name = this.hasNameInputTarget ? this.nameInputTarget.value : "Passkey"

      const form = document.createElement("form")
      form.method = "POST"
      form.action = "/admin/passkeys"
      form.style.display = "none"

      const csrfInput = document.createElement("input")
      csrfInput.name = "authenticity_token"
      csrfInput.value = this.csrfToken
      form.appendChild(csrfInput)

      const nameInput = document.createElement("input")
      nameInput.name = "name"
      nameInput.value = name
      form.appendChild(nameInput)

      const credentialData = {
        id: credential.id,
        rawId: this.bufferToBase64url(credential.rawId),
        type: credential.type,
        response: {
          attestationObject: this.bufferToBase64url(credential.response.attestationObject),
          clientDataJSON: this.bufferToBase64url(credential.response.clientDataJSON)
        },
        clientExtensionResults: credential.getClientExtensionResults()
      }

      const credInput = document.createElement("input")
      credInput.name = "credential"
      credInput.value = JSON.stringify(credentialData)
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

  async fetchJSON(url, options = {}) {
    const headers = {
      "X-CSRF-Token": this.csrfToken,
      "Accept": "application/json"
    }

    if (options.body && typeof options.body === "string") {
      headers["Content-Type"] = "application/json"
    }

    const response = await fetch(url, { ...options, headers })
    const data = await response.json()

    if (!response.ok) {
      throw new Error(data.error || "Request failed")
    }

    return data
  }

  get csrfToken() {
    return document.querySelector("meta[name='csrf-token']")?.content
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

  base64urlToBuffer(base64url) {
    const base64 = base64url.replace(/-/g, "+").replace(/_/g, "/")
    const padded = base64.padEnd(base64.length + (4 - base64.length % 4) % 4, "=")
    const binary = atob(padded)
    const buffer = new ArrayBuffer(binary.length)
    const view = new Uint8Array(buffer)
    for (let i = 0; i < binary.length; i++) {
      view[i] = binary.charCodeAt(i)
    }
    return buffer
  }

  bufferToBase64url(buffer) {
    const bytes = new Uint8Array(buffer)
    let binary = ""
    for (let i = 0; i < bytes.byteLength; i++) {
      binary += String.fromCharCode(bytes[i])
    }
    return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=/g, "")
  }
}
