import { Controller } from "@hotwired/stimulus"
import { readingList } from "lib/reading_list"

// A save-for-later toggle for one post. The markup (ReadingListHelper#bookmark_button)
// lives inside cached post cards, so it ships hidden and reader-agnostic; this
// controller reveals it and reflects whether the post is in the reading list.
export default class extends Controller {
  static values = { postId: Number, saveLabel: String, removeLabel: String }

  connect() {
    this.element.hidden = false
    this.refresh()
  }

  toggle(event) {
    // Cards wrap their title in a link; don't let a click here reach it.
    event.preventDefault()
    readingList.toggle(this.postIdValue)
  }

  refresh() {
    const saved = readingList.has(this.postIdValue)
    const label = saved ? this.removeLabelValue : this.saveLabelValue

    this.element.setAttribute("aria-pressed", String(saved))
    this.element.setAttribute("aria-label", label)
    this.element.title = label
    this.element.classList.toggle("bookmark-btn--saved", saved)
  }
}
