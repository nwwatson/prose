import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "headingFont", "subtitleFont", "bodyFont",
    "headingSize", "subtitleSize", "bodySize",
    "previewHeading", "previewSubtitle", "previewBody"
  ]

  #loadedFonts = new Set()

  connect() {
    this.update()
  }

  update() {
    const headingFont = this.headingFontTarget.value
    const subtitleFont = this.subtitleFontTarget.value
    const bodyFont = this.bodyFontTarget.value
    const headingSize = this.headingSizeTarget.value
    const subtitleSize = this.subtitleSizeTarget.value
    const bodySize = this.bodySizeTarget.value

    // Load fonts dynamically
    this.#loadFont(headingFont)
    this.#loadFont(subtitleFont)
    this.#loadFont(bodyFont)

    // Update preview styles
    this.previewHeadingTarget.style.fontFamily = `"${headingFont}"`
    this.previewHeadingTarget.style.fontSize = `${headingSize}rem`

    this.previewSubtitleTarget.style.fontFamily = `"${subtitleFont}"`
    this.previewSubtitleTarget.style.fontSize = `${subtitleSize}rem`

    this.previewBodyTarget.style.fontFamily = `"${bodyFont}"`
    this.previewBodyTarget.style.fontSize = `${bodySize}rem`
  }

  #loadFont(fontName) {
    if (this.#loadedFonts.has(fontName)) return

    this.#loadedFonts.add(fontName)
    const family = fontName.replace(/ /g, "+")
    const link = document.createElement("link")
    link.rel = "stylesheet"
    link.href = `https://fonts.googleapis.com/css2?family=${family}&display=swap`
    document.head.appendChild(link)
  }
}
