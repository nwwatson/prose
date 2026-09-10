// Shared keyboard navigation for listbox-style dropdowns (`tag_select` and
// `custom_select`).
//
// The navigator owns nothing but the highlighted index and the key handling —
// every visual and app-specific decision is injected, so the two controllers
// can keep their different highlight styles, item sets, and selection
// behavior while sharing the arrow/Home/End/Enter/Escape/type-ahead logic.
//
// Options:
//   getItems()            — array of currently navigable elements (required)
//   highlight(item, on)   — apply/remove the highlight on one item (required)
//   onSelect(item)        — Enter (and Space, when `selectOnSpace`) on a
//                           highlighted item (required)
//   onEscape()            — Escape; the caller decides about propagation
//   clearHighlight()      — override when more elements than `getItems()` may
//                           be carrying a highlight
//   isOpen()              — when false, ArrowDown calls `onOpenRequest`
//   onOpenRequest()       — open the dropdown instead of moving the highlight
//   getItemText(item)     — text used by type-ahead
//   typeAhead             — enable printable-character type-ahead
//   homeEnd               — enable Home/End
//   selectOnSpace         — treat Space like Enter
//
// `handleKeydown` returns true when it handled the event, so callers can fall
// through to their own keys (e.g. `tag_select`'s Backspace).
export class ListboxNavigator {
  constructor({
    getItems,
    highlight,
    onSelect,
    onEscape = null,
    clearHighlight = null,
    isOpen = () => true,
    onOpenRequest = null,
    getItemText = (item) => item.textContent,
    typeAhead = false,
    homeEnd = false,
    selectOnSpace = false,
    typeAheadDelay = 500
  }) {
    this.getItems = getItems
    this.highlightItem = highlight
    this.onSelect = onSelect
    this.onEscape = onEscape
    this.customClearHighlight = clearHighlight
    this.isOpen = isOpen
    this.onOpenRequest = onOpenRequest
    this.getItemText = getItemText
    this.typeAheadEnabled = typeAhead
    this.homeEnd = homeEnd
    this.selectOnSpace = selectOnSpace
    this.typeAheadDelay = typeAheadDelay

    this.index = -1
    this.searchString = ""
    this.searchTimeout = null
  }

  // --- State ---

  items() {
    return this.getItems()
  }

  current() {
    return this.items()[this.index] || null
  }

  reset(index = -1) {
    this.clearHighlight()
    this.index = index
    if (index >= 0) this.applyHighlight()
  }

  clearHighlight() {
    if (this.customClearHighlight) {
      this.customClearHighlight()
    } else {
      this.items().forEach(item => this.highlightItem(item, false))
    }
  }

  setIndex(index) {
    this.clearHighlight()
    this.index = index
    this.applyHighlight()
  }

  applyHighlight() {
    const item = this.current()
    if (!item) return
    this.highlightItem(item, true)
    item.scrollIntoView({ block: "nearest" })
  }

  // --- Keys ---

  handleKeydown(event) {
    // Escape is handled before the empty-list guard so a dropdown with no
    // options can still be dismissed.
    if (event.key === "Escape") {
      if (!this.onEscape) return false
      this.onEscape(event)
      return true
    }

    if (event.key === "ArrowDown" && !this.isOpen()) {
      event.preventDefault()
      if (this.onOpenRequest) this.onOpenRequest()
      return true
    }

    const items = this.items()
    if (items.length === 0) return false

    switch (event.key) {
      case "ArrowDown":
        event.preventDefault()
        this.setIndex(Math.min(this.index + 1, items.length - 1))
        return true

      case "ArrowUp":
        event.preventDefault()
        this.setIndex(Math.max(this.index - 1, 0))
        return true

      case "Home":
        if (!this.homeEnd) return false
        event.preventDefault()
        this.setIndex(0)
        return true

      case "End":
        if (!this.homeEnd) return false
        event.preventDefault()
        this.setIndex(items.length - 1)
        return true

      case " ":
        if (!this.selectOnSpace) return false
        // fall through
      case "Enter": {
        event.preventDefault()
        const item = this.index >= 0 ? items[this.index] : null
        this.onSelect(item)
        return true
      }

      default:
        if (this.typeAheadEnabled && event.key.length === 1) {
          this.typeAhead(event.key, items)
          return true
        }
        return false
    }
  }

  typeAhead(char, items) {
    clearTimeout(this.searchTimeout)
    this.searchString += char.toLowerCase()
    this.searchTimeout = setTimeout(() => { this.searchString = "" }, this.typeAheadDelay)

    for (let i = 0; i < items.length; i++) {
      if (this.getItemText(items[i]).toLowerCase().startsWith(this.searchString)) {
        this.setIndex(i)
        break
      }
    }
  }
}
