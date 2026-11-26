import { Controller } from "@hotwired/stimulus"
import { request } from "lib/request"

export default class extends Controller {
  static targets = ["editor", "preview", "previewLabel", "editLabel"]

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
      const response = await request(previewUrl, { accept: "text/html" })

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

  // The view renders both icon+label pairs, already translated.
  updateButton() {
    if (this.hasPreviewLabelTarget) this.previewLabelTarget.hidden = this.previewing
    if (this.hasEditLabelTarget) this.editLabelTarget.hidden = !this.previewing
  }

  #buildPreviewUrl(autosave) {
    if (!autosave) return null
    const baseUrl = autosave.urlValue
    if (!baseUrl) return null
    return `${baseUrl}/preview`
  }
}
