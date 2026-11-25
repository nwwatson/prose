import { Controller } from "@hotwired/stimulus"

const HEX_COLOR_PATTERN = /^#[0-9a-fA-F]{6}$/

export default class extends Controller {
  static targets = ["color", "text"]

  fromColor() {
    this.textTarget.value = this.colorTarget.value
    this.#dispatchChange(this.colorTarget.value)
  }

  fromText() {
    const value = this.textTarget.value.trim()
    if (!HEX_COLOR_PATTERN.test(value)) return

    this.colorTarget.value = value
    this.#dispatchChange(value)
  }

  #dispatchChange(value) {
    this.dispatch("change", { detail: { value } })
  }
}
