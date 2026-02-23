import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["status", "discardBackdrop", "discardModal"]
  static values = {
    url: String,
    method: { type: String, default: "POST" },
    persisted: { type: Boolean, default: false },
    backUrl: String,
    formSelector: { type: String, default: "#post_form" },
    titleSelector: { type: String, default: "#post_title" }
  }

  connect() {
    this.dirty = false
    this.saving = false
    this.pendingSave = false
    this.saveTimer = null
    this.savePromise = null
    this.boundBeforeUnload = this.beforeUnload.bind(this)
    window.addEventListener("beforeunload", this.boundBeforeUnload)
  }

  disconnect() {
    clearTimeout(this.saveTimer)
    window.removeEventListener("beforeunload", this.boundBeforeUnload)
  }

  scheduleAutosave() {
    this.dirty = true
    this.updateStatus("unsaved")
    clearTimeout(this.saveTimer)
    this.saveTimer = setTimeout(() => this.save(), 3000)
  }

  handleChange(event) {
    if (event.target.type === "file") {
      this.dirty = true
      this.save()
    } else {
      this.scheduleAutosave()
    }
  }

  preventSubmit(event) {
    event.preventDefault()
    this.scheduleAutosave()
  }

  async save() {
    const titleInput = this.element.querySelector(this.titleSelectorValue)
    if (titleInput && !titleInput.value.trim()) return

    if (this.saving) {
      this.pendingSave = true
      return this.savePromise
    }

    this.saving = true
    this.updateStatus("saving")

    const form = this.element.querySelector(this.formSelectorValue)
    const formData = new FormData(form)

    // Remove empty file inputs to avoid re-uploading
    for (const [key, value] of [...formData.entries()]) {
      if (value instanceof File && value.size === 0) {
        formData.delete(key)
      }
    }

    const csrfToken = document.querySelector("meta[name='csrf-token']")?.content

    this.savePromise = fetch(this.urlValue, {
      method: this.methodValue,
      headers: {
        "Accept": "application/json",
        "X-CSRF-Token": csrfToken
      },
      body: formData
    })
      .then(async (response) => {
        const data = await response.json()

        if (response.ok) {
          if (!this.persistedValue) {
            // First create — transition to edit mode
            history.replaceState({}, "", data.edit_url)
            form.action = data.url
            this.urlValue = data.url
            this.methodValue = "PATCH"
            this.persistedValue = true
          } else if (data.url !== this.urlValue) {
            // Slug changed
            history.replaceState({}, "", data.edit_url)
            form.action = data.url
            this.urlValue = data.url
          }

          this.dirty = false
          this.updateStatus("saved")
        } else {
          this.updateStatus("error")
          setTimeout(() => this.save(), 5000)
        }
      })
      .catch(() => {
        this.updateStatus("error")
        setTimeout(() => this.save(), 5000)
      })
      .finally(() => {
        this.saving = false
        if (this.pendingSave) {
          this.pendingSave = false
          this.save()
        }
      })

    return this.savePromise
  }

  async handleBack(event) {
    event.preventDefault()

    const titleInput = this.element.querySelector(this.titleSelectorValue)
    const hasTitle = titleInput && titleInput.value.trim()

    if (!this.persistedValue && !hasTitle) {
      this.openDiscardModal()
      return
    }

    if (this.dirty) {
      this.updateStatus("saving")
      const timeout = new Promise((_, reject) =>
        setTimeout(() => reject(new Error("timeout")), 10000)
      )
      try {
        await Promise.race([this.save(), timeout])
      } catch {
        // Navigate anyway after timeout
      }
    }

    window.Turbo.visit(this.backUrlValue)
  }

  openDiscardModal() {
    this.discardBackdropTarget.classList.remove("hidden")
    this.discardModalTarget.classList.remove("hidden")
    document.body.classList.add("overflow-hidden")
  }

  closeDiscardModal() {
    this.discardBackdropTarget.classList.add("hidden")
    this.discardModalTarget.classList.add("hidden")
    document.body.classList.remove("overflow-hidden")
  }

  confirmDiscard() {
    this.dirty = false
    window.Turbo.visit(this.backUrlValue)
  }

  updateStatus(state) {
    if (!this.hasStatusTarget) return

    const el = this.statusTarget
    el.classList.remove("text-amber-600", "text-gray-500", "text-red-600")

    switch (state) {
      case "unsaved":
        el.textContent = "Unsaved changes"
        el.classList.add("text-amber-600")
        break
      case "saving":
        el.textContent = "Saving..."
        el.classList.add("text-gray-500")
        break
      case "saved":
        el.textContent = "Saved"
        el.classList.add("text-gray-500")
        break
      case "error":
        el.textContent = "Save failed"
        el.classList.add("text-red-600")
        break
    }
  }

  beforeUnload(event) {
    if (this.dirty) {
      event.preventDefault()
      event.returnValue = ""
    }
  }
}
