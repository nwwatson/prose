import { Controller } from "@hotwired/stimulus"
import { useClickOutside } from "admin/lib/click_outside"
import { ListboxNavigator } from "admin/lib/listbox"
import { fadeIn, fadeOut } from "admin/lib/transition"

const HIGHLIGHT_CLASSES = [ "ring-2", "ring-inset", "ring-blue-400" ]
const DROPDOWN_TRANSITION = { off: [ "opacity-0", "scale-95" ], on: [ "opacity-100", "scale-100" ] }

export default class extends Controller {
  static targets = ["select", "trigger", "triggerText", "dropdown", "optionTemplate"]

  connect() {
    this.opened = false
    this.buildOptions()
    this.syncTriggerText()

    this.clickOutside = useClickOutside(this, { onClickOutside: () => this.close() })

    this.navigator = new ListboxNavigator({
      getItems: () => this.items(),
      highlight: (li, on) => {
        if (on) {
          li.classList.add(...HIGHLIGHT_CLASSES)
        } else {
          li.classList.remove(...HIGHLIGHT_CLASSES)
        }
      },
      onSelect: (li) => this.selectFromKeyboard(li),
      onEscape: (event) => this.escape(event),
      getItemText: (li) => li.querySelector("[data-option-text]").textContent,
      typeAhead: true,
      homeEnd: true,
      selectOnSpace: true
    })

    this.handleKeydown = this.handleKeydown.bind(this)
  }

  disconnect() {
    this.clickOutside.unobserve()
    this.element.removeEventListener("keydown", this.handleKeydown)
  }

  buildOptions() {
    const items = Array.from(this.selectTarget.options, (option) => {
      const li = this.optionTemplateTarget.content.firstElementChild.cloneNode(true)
      li.dataset.value = option.value
      li.querySelector("[data-option-text]").textContent = option.textContent

      const swatch = li.querySelector("[data-option-swatch]")
      if (option.dataset.color) {
        swatch.style.backgroundColor = option.dataset.color
      } else {
        swatch.remove()
      }
      return li
    })

    this.dropdownTarget.replaceChildren(...items)
    this.updateSelectedState()
  }

  items() {
    return Array.from(this.dropdownTarget.querySelectorAll("li"))
  }

  selectedItem() {
    return this.dropdownTarget.querySelector('[aria-selected="true"]')
  }

  syncTriggerText() {
    const label = this.selectedItem()?.querySelector("[data-option-label]")
    if (label) this.triggerTextTarget.replaceChildren(label.cloneNode(true))
  }

  toggle() {
    if (this.isOpen()) {
      this.close()
    } else {
      this.open()
    }
  }

  open() {
    this.opened = true
    fadeIn(this.dropdownTarget, DROPDOWN_TRANSITION)

    this.clickOutside.observe()
    // Scoped to the component rather than `document` so an open dropdown's
    // Escape can be stopped before it reaches the editor drawer. The trigger
    // is focused explicitly because clicking a <button> does not focus it in
    // every browser, and without focus the listener would never fire.
    this.element.addEventListener("keydown", this.handleKeydown)
    this.triggerTarget.focus()

    this.selectedItem()?.scrollIntoView({ block: "nearest" })
    this.navigator.index = this.selectedOptionIndex()
  }

  close() {
    this.opened = false
    fadeOut(this.dropdownTarget, DROPDOWN_TRANSITION)

    this.clickOutside.unobserve()
    this.element.removeEventListener("keydown", this.handleKeydown)
  }

  isOpen() {
    return this.opened
  }

  pick(event) {
    const li = event.target.closest("li")
    if (!li) return

    this.selectValue(li.dataset.value)
    this.close()
  }

  selectValue(value) {
    this.selectTarget.value = value
    this.selectTarget.dispatchEvent(new Event("change", { bubbles: true }))

    this.updateSelectedState()
    this.syncTriggerText()
  }

  updateSelectedState() {
    const currentValue = this.selectTarget.value
    this.items().forEach((li) => {
      li.setAttribute("aria-selected", li.dataset.value === currentValue)
    })
  }

  // --- Keyboard ---

  handleKeydown(event) {
    this.navigator.handleKeydown(event)
  }

  selectFromKeyboard(li) {
    if (!li) return
    this.selectValue(li.dataset.value)
    this.close()
    this.triggerTarget.focus()
  }

  escape(event) {
    event.preventDefault()
    // Keep the editor drawer's document-level Escape handler from also firing.
    event.stopPropagation()
    this.close()
    this.triggerTarget.focus()
  }

  selectedOptionIndex() {
    return Math.max(0, this.items().indexOf(this.selectedItem()))
  }
}
