import { Controller } from "@hotwired/stimulus"

// A backdrop + dialog pair: shows both, locks body scroll, focuses the dialog
// and closes on Escape. The keydown listener is on `this.element` (focus is
// moved into the dialog on open) and stops Escape from propagating, so the
// first Escape closes the modal and only the next one reaches the editor
// drawer's document-level handler.
//
// Other controllers open it by event rather than owning its markup, e.g.
// `data-action="autosave:discard-requested@window->modal#open"`.
export default class extends Controller {
  static targets = [ "backdrop", "dialog" ]

  connect() {
    this.isOpen = false
    this.handleKeydown = this.handleKeydown.bind(this)
    this.element.addEventListener("keydown", this.handleKeydown)
  }

  disconnect() {
    this.element.removeEventListener("keydown", this.handleKeydown)
    if (this.isOpen) document.body.classList.remove("overflow-hidden")
  }

  open() {
    if (this.isOpen) return
    this.isOpen = true
    this.returnFocusTo = document.activeElement
    this.backdropTarget.classList.remove("hidden")
    this.dialogTarget.classList.remove("hidden")
    document.body.classList.add("overflow-hidden")
    this.dialogTarget.focus({ preventScroll: true })
    this.dispatch("opened")
  }

  close() {
    if (!this.isOpen) return
    this.isOpen = false
    this.backdropTarget.classList.add("hidden")
    this.dialogTarget.classList.add("hidden")
    document.body.classList.remove("overflow-hidden")
    if (this.returnFocusTo?.isConnected) this.returnFocusTo.focus({ preventScroll: true })
    this.returnFocusTo = null
  }

  handleKeydown(event) {
    if (event.key !== "Escape" || !this.isOpen) return
    event.preventDefault()
    event.stopPropagation()
    this.close()
  }
}
