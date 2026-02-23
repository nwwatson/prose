import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "preview", "previewBg", "previewAccent", "previewHeading", "previewBody",
    "accentColor", "backgroundColor", "textColor", "headingColor"
  ]

  update() {
    if (this.hasPreviewAccentTarget && this.hasAccentColorTarget) {
      this.previewAccentTarget.style.backgroundColor = this.accentColorTarget.value
    }

    if (this.hasPreviewBgTarget && this.hasBackgroundColorTarget) {
      this.previewBgTarget.style.backgroundColor = this.backgroundColorTarget.value
    }

    if (this.hasPreviewHeadingTarget && this.hasHeadingColorTarget) {
      this.previewHeadingTarget.style.color = this.headingColorTarget.value
    }

    if (this.hasPreviewBodyTarget && this.hasTextColorTarget) {
      this.previewBodyTarget.style.color = this.textColorTarget.value
    }
  }
}
