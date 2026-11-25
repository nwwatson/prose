import { Controller } from "@hotwired/stimulus"
import { capitalize } from "lib/dom"

export default class extends Controller {
  static targets = [
    "preview", "previewBg", "previewAccent", "previewHeading", "previewBody",
    "previewTemplate", "previewFont", "previewPreheader", "previewFooter",
    "previewSocialTwitter", "previewSocialGithub", "previewSocialLinkedin", "previewSocialWebsite",
    "previewSocial",
    "accentColor", "backgroundColor", "textColor", "headingColor",
    "template", "fontFamily", "preheader", "footer",
    "socialTwitter", "socialGithub", "socialLinkedin", "socialWebsite"
  ]

  static values = {
    fonts: Object
  }

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

    if (this.hasPreviewTemplateTarget && this.hasTemplateTarget) {
      const selected = this.templateTarget.selectedOptions[0]
      this.previewTemplateTarget.textContent = selected ? selected.text : "Minimal"
    }

    if (this.hasFontFamilyTarget) {
      const key = this.fontFamilyTarget.value
      const stack = this.fontsValue[key] || this.fontsValue["system"]
      if (this.hasPreviewFontTarget) {
        this.previewFontTarget.textContent = this.fontFamilyTarget.selectedOptions[0]?.text || "System Default"
      }
      if (this.hasPreviewHeadingTarget) {
        this.previewHeadingTarget.style.fontFamily = stack
      }
      if (this.hasPreviewBodyTarget) {
        this.previewBodyTarget.style.fontFamily = stack
      }
    }

    if (this.hasPreviewPreheaderTarget && this.hasPreheaderTarget) {
      const text = this.preheaderTarget.value.trim()
      this.previewPreheaderTarget.textContent = text || "Preview text shown in inbox..."
      this.previewPreheaderTarget.style.opacity = text ? "1" : "0.5"
    }

    if (this.hasPreviewFooterTarget && this.hasFooterTarget) {
      const text = this.footerTarget.value.trim()
      this.previewFooterTarget.textContent = text || "Custom footer text"
      this.previewFooterTarget.style.opacity = text ? "1" : "0.5"
    }

    this.#updateSocialIcons()
  }

  #updateSocialIcons() {
    const fields = [
      { target: "previewSocialTwitter", source: "socialTwitter" },
      { target: "previewSocialGithub", source: "socialGithub" },
      { target: "previewSocialLinkedin", source: "socialLinkedin" },
      { target: "previewSocialWebsite", source: "socialWebsite" }
    ]

    let anyVisible = false
    fields.forEach(({ target, source }) => {
      const hasPreview = `has${capitalize(target)}Target`
      const hasSource = `has${capitalize(source)}Target`
      if (this[hasPreview] && this[hasSource]) {
        const visible = this[`${source}Target`].value.trim() !== ""
        this[`${target}Target`].style.display = visible ? "inline-block" : "none"
        if (visible) anyVisible = true
      }
    })

    if (this.hasPreviewSocialTarget) {
      this.previewSocialTarget.style.display = anyVisible ? "flex" : "none"
    }
  }
}
