import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "preview", "previewBg", "previewAccent", "previewHeading", "previewBody",
    "previewTemplate", "previewFont", "previewPreheader", "previewFooter",
    "previewSocialTwitter", "previewSocialGithub", "previewSocialLinkedin", "previewSocialWebsite",
    "previewSocial",
    "accentColor", "accentColorText", "backgroundColor", "backgroundColorText",
    "textColor", "textColorText", "headingColor", "headingColorText",
    "template", "fontFamily", "preheader", "footer",
    "socialTwitter", "socialGithub", "socialLinkedin", "socialWebsite"
  ]

  static values = {
    fonts: Object
  }

  update() {
    this.#syncPair("accentColor")
    this.#syncPair("backgroundColor")
    this.#syncPair("textColor")
    this.#syncPair("headingColor")

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
      const hasPreview = `has${target.charAt(0).toUpperCase() + target.slice(1)}Target`
      const hasSource = `has${source.charAt(0).toUpperCase() + source.slice(1)}Target`
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

  #syncPair(name) {
    const colorTarget = `${name}Target`
    const textTarget = `${name}TextTarget`
    const hasColor = `has${name.charAt(0).toUpperCase() + name.slice(1)}Target`
    const hasText = `has${name.charAt(0).toUpperCase() + name.slice(1)}TextTarget`

    if (this[hasColor] && this[hasText]) {
      const colorEl = this[colorTarget]
      const textEl = this[textTarget]

      if (document.activeElement === textEl) {
        const val = textEl.value.trim()
        if (/^#[0-9a-fA-F]{6}$/.test(val)) {
          colorEl.value = val
        }
      } else {
        textEl.value = colorEl.value
      }
    }
  }
}
