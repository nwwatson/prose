import { Controller } from "@hotwired/stimulus"
import { copyText } from "lib/clipboard"

// Copies the text of the source target to the clipboard.
export default class extends Controller {
  static targets = ["source"]

  copy() {
    copyText(this.sourceTarget.textContent.trim())
  }
}
