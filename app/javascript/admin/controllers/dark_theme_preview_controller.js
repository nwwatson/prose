import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "themeSelect", "customFields", "preview", "previewLink",
    "bgColor", "textColor", "accentColor"
  ]
  static values = { themes: Object }

  update(event) {
    const key = event.target.value

    if (key === "custom") {
      this.customFieldsTarget.classList.remove("hidden")
      this.applyPreview(
        this.bgColorTarget.value,
        this.textColorTarget.value,
        this.accentColorTarget.value
      )
    } else {
      this.customFieldsTarget.classList.add("hidden")
      const theme = this.themesValue[key]
      if (theme) {
        this.applyPreview(theme.bg, theme.text, theme.accent)
      }
    }
  }

  updateCustom() {
    this.applyPreview(
      this.bgColorTarget.value,
      this.textColorTarget.value,
      this.accentColorTarget.value
    )
  }

  applyPreview(bg, text, accent) {
    this.previewTarget.style.backgroundColor = bg
    this.previewTarget.style.color = text
    if (this.hasPreviewLinkTarget) {
      this.previewLinkTarget.style.color = accent
    }
  }
}
