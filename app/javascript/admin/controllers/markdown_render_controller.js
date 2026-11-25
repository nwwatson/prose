import { Controller } from "@hotwired/stimulus"
import { renderMarkdown } from "lib/markdown"

// Renders markdown for static (non-streaming) messages.
// Used by _message.html.erb for persisted assistant messages.
export default class extends Controller {
  static values = { raw: String }

  connect() {
    if (this.hasRawValue && this.rawValue) {
      this.element.innerHTML = renderMarkdown(this.rawValue, { theme: "chat" })
    }
  }
}
