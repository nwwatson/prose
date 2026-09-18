import { Controller } from "@hotwired/stimulus"
import { request } from "lib/request"

// Native HTML5 drag-and-drop reordering for a list of items. Each list is its
// own controller instance, so items can only be dropped within the list they
// started in. After a drop that changed the order, the new id order is PATCHed
// to `urlValue` as { location, ids }; if that fails the page is reloaded so
// the list reflects what the server actually stored.
//
//   <ul data-controller="sortable" data-sortable-url-value="..." data-sortable-location-value="header">
//     <li data-sortable-target="item" data-id="1" draggable="true"
//         data-action="dragstart->sortable#start dragend->sortable#end">...</li>
//   </ul>
//   (the <ul> also needs data-action="dragover->sortable#over drop->sortable#drop")
export default class extends Controller {
  static targets = ["item"]
  static values = { url: String, location: String }
  static classes = ["dragging"]

  start(event) {
    this.dragged = event.currentTarget
    this.originalOrder = this.ids()
    event.dataTransfer.effectAllowed = "move"
    // Firefox won't start a drag without data set.
    event.dataTransfer.setData("text/plain", this.dragged.dataset.id)
    this.dragged.classList.add(...this.draggingClasses)
  }

  over(event) {
    if (!this.dragged) return
    event.preventDefault()
    event.dataTransfer.dropEffect = "move"

    const target = event.target.closest("[data-sortable-target~='item']")
    if (!target || target === this.dragged || !this.element.contains(target)) return

    const { top, height } = target.getBoundingClientRect()
    const after = event.clientY > top + height / 2
    target.parentNode.insertBefore(this.dragged, after ? target.nextSibling : target)
  }

  drop(event) {
    if (this.dragged) event.preventDefault()
  }

  async end() {
    if (!this.dragged) return
    this.dragged.classList.remove(...this.draggingClasses)
    this.dragged = null

    const ids = this.ids()
    if (ids.join(",") === this.originalOrder.join(",")) return

    try {
      const response = await request(this.urlValue, {
        method: "PATCH",
        body: { location: this.locationValue, ids }
      })
      if (!response.ok) throw new Error(`Reorder failed: ${response.status}`)
    } catch (error) {
      console.error(error)
      window.Turbo.visit(window.location.href, { action: "replace" })
    }
  }

  ids() {
    return this.itemTargets.map((item) => item.dataset.id)
  }
}
