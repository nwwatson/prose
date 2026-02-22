import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["editor", "preview", "toggleButton", "toggleIcon", "toggleLabel"]

  connect() {
    this.previewing = false
    this.boundKeydown = this.handleKeydown.bind(this)
    document.addEventListener("keydown", this.boundKeydown)
  }

  disconnect() {
    document.removeEventListener("keydown", this.boundKeydown)
  }

  handleKeydown(event) {
    if (!this.hasEditorTarget) return

    if ((event.metaKey || event.ctrlKey) && event.shiftKey && event.key === "p") {
      event.preventDefault()
      this.toggle()
    }
  }

  async toggle() {
    if (!this.hasEditorTarget) return

    if (this.previewing) {
      this.showEditor()
    } else {
      await this.showPreview()
    }
  }

  async showPreview() {
    const autosave = this.application.getControllerForElementAndIdentifier(this.element, "autosave")

    if (autosave) {
      if (autosave.dirty || autosave.saving) {
        try {
          if (autosave.saving) {
            await autosave.savePromise
          }
          if (autosave.dirty) {
            await autosave.save()
          }
        } catch {
          return
        }
      }

      if (!autosave.persistedValue) return
    }

    const previewUrl = this.#buildPreviewUrl(autosave)
    if (!previewUrl) return

    try {
      const csrfToken = document.querySelector("meta[name='csrf-token']")?.content
      const response = await fetch(previewUrl, {
        headers: {
          "Accept": "text/html",
          "X-CSRF-Token": csrfToken
        }
      })

      if (!response.ok) return

      const html = await response.text()
      this.previewTarget.innerHTML = html
      this.editorTarget.classList.add("hidden")
      this.previewTarget.classList.remove("hidden")
      this.previewing = true
      this.updateButton()
    } catch {
      // Silently fail — editor remains visible
    }
  }

  showEditor() {
    this.previewTarget.classList.add("hidden")
    this.previewTarget.innerHTML = ""
    this.editorTarget.classList.remove("hidden")
    this.previewing = false
    this.updateButton()
  }

  updateButton() {
    if (!this.hasToggleLabelTarget) return

    if (this.previewing) {
      this.toggleLabelTarget.textContent = "Edit"
      this.toggleIconTarget.innerHTML = `
        <path stroke-linecap="round" stroke-linejoin="round" d="M15.232 5.232l3.536 3.536m-2.036-5.036a2.5 2.5 0 113.536 3.536L6.5 21.036H3v-3.572L16.732 3.732z" />
      `
    } else {
      this.toggleLabelTarget.textContent = "Preview"
      this.toggleIconTarget.innerHTML = `
        <path stroke-linecap="round" stroke-linejoin="round" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
        <path stroke-linecap="round" stroke-linejoin="round" d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
      `
    }
  }

  #buildPreviewUrl(autosave) {
    if (!autosave) return null
    const baseUrl = autosave.urlValue
    if (!baseUrl) return null
    return `${baseUrl}/preview`
  }
}
