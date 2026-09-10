import { Controller } from "@hotwired/stimulus"
import { escapeHtml } from "lib/dom"
import { useClickOutside } from "lib/click_outside"
import { ListboxNavigator } from "lib/listbox"

const HIGHLIGHT_CLASSES = [ "ring-2", "ring-inset", "ring-blue-400" ]

export default class extends Controller {
  static targets = ["select", "trigger", "triggerText", "dropdown"]

  connect() {
    this.buildOptions()
    this.syncTriggerText()

    this.clickOutside = useClickOutside(this, { onClickOutside: () => this.close() })

    this.navigator = new ListboxNavigator({
      getItems: () => Array.from(this.dropdownTarget.querySelectorAll("li")),
      highlight: (li, on) => {
        if (on) {
          li.classList.add(...HIGHLIGHT_CLASSES)
        } else {
          li.classList.remove(...HIGHLIGHT_CLASSES)
        }
      },
      onSelect: (li) => this.selectFromKeyboard(li),
      onEscape: (event) => this.escape(event),
      getItemText: (li) => li.querySelector("span").textContent,
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
    const dropdown = this.dropdownTarget
    dropdown.innerHTML = ""

    const options = this.selectTarget.options
    for (let i = 0; i < options.length; i++) {
      const option = options[i]
      const li = document.createElement("li")
      li.setAttribute("role", "option")
      li.setAttribute("data-value", option.value)
      li.setAttribute("data-action", "click->custom-select#pick")
      li.className = this.optionClasses(option.value === this.selectTarget.value)
      const color = option.dataset.color
      const swatchHtml = color
        ? `<span class="inline-block h-5 w-5 rounded border border-gray-300 shrink-0" style="background-color: ${escapeHtml(color)}"></span>`
        : ""
      const flexClass = color ? "flex items-center gap-2" : ""

      li.innerHTML = `
        <span class="${flexClass} block truncate">${swatchHtml}${escapeHtml(option.textContent)}</span>
        <span class="absolute inset-y-0 right-0 flex items-center pr-3 ${option.value === this.selectTarget.value ? "text-white" : "hidden"}">
          <svg class="h-4 w-4" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor">
            <path fill-rule="evenodd" d="M16.704 4.153a.75.75 0 01.143 1.052l-8 10.5a.75.75 0 01-1.127.075l-4.5-4.5a.75.75 0 011.06-1.06l3.894 3.893 7.48-9.817a.75.75 0 011.05-.143z" clip-rule="evenodd" />
          </svg>
        </span>
      `
      dropdown.appendChild(li)
    }
  }

  optionClasses(selected) {
    const base = "relative cursor-pointer select-none py-2 pl-3 pr-9 transition-colors"
    if (selected) {
      return `${base} bg-blue-600 text-white`
    }
    return `${base} text-gray-900 hover:bg-gray-100`
  }

  syncTriggerText() {
    const selected = this.selectTarget.options[this.selectTarget.selectedIndex]
    if (selected) {
      const color = selected.dataset.color
      if (color) {
        this.triggerTextTarget.innerHTML = `<span class="flex items-center gap-2"><span class="inline-block h-5 w-5 rounded border border-gray-300 shrink-0" style="background-color: ${escapeHtml(color)}"></span>${escapeHtml(selected.textContent)}</span>`
      } else {
        this.triggerTextTarget.textContent = selected.textContent
      }
    }
  }

  toggle() {
    if (this.isOpen()) {
      this.close()
    } else {
      this.open()
    }
  }

  open() {
    const dropdown = this.dropdownTarget
    dropdown.classList.remove("hidden")
    // Force reflow before adding transition classes
    dropdown.offsetHeight // eslint-disable-line no-unused-expressions
    dropdown.classList.remove("opacity-0", "scale-95")
    dropdown.classList.add("opacity-100", "scale-100")

    this.clickOutside.observe()
    // Scoped to the component rather than `document` so an open dropdown's
    // Escape can be stopped before it reaches the editor drawer. The trigger
    // is focused explicitly because clicking a <button> does not focus it in
    // every browser, and without focus the listener would never fire.
    this.element.addEventListener("keydown", this.handleKeydown)
    this.triggerTarget.focus()

    // Scroll selected option into view
    const selected = dropdown.querySelector('[class*="bg-blue-600"]')
    if (selected) {
      selected.scrollIntoView({ block: "nearest" })
    }

    this.navigator.index = this.selectedOptionIndex()
  }

  close() {
    const dropdown = this.dropdownTarget
    dropdown.classList.remove("opacity-100", "scale-100")
    dropdown.classList.add("opacity-0", "scale-95")

    const onTransitionEnd = () => {
      dropdown.classList.add("hidden")
      dropdown.removeEventListener("transitionend", onTransitionEnd)
    }
    dropdown.addEventListener("transitionend", onTransitionEnd)

    this.clickOutside.unobserve()
    this.element.removeEventListener("keydown", this.handleKeydown)
  }

  isOpen() {
    return !this.dropdownTarget.classList.contains("hidden")
  }

  pick(event) {
    const li = event.target.closest("li")
    if (!li) return

    const value = li.getAttribute("data-value")
    this.selectValue(value)
    this.close()
  }

  selectValue(value) {
    this.selectTarget.value = value
    this.selectTarget.dispatchEvent(new Event("change", { bubbles: true }))

    this.syncTriggerText()
    this.updateOptionStyles()
  }

  updateOptionStyles() {
    const items = this.dropdownTarget.querySelectorAll("li")
    const currentValue = this.selectTarget.value

    items.forEach((li) => {
      const isSelected = li.getAttribute("data-value") === currentValue
      li.className = this.optionClasses(isSelected)

      const checkmark = li.querySelector("span:last-child")
      if (isSelected) {
        checkmark.classList.remove("hidden")
        checkmark.classList.add("text-white")
      } else {
        checkmark.classList.add("hidden")
      }
    })
  }

  // --- Keyboard ---

  handleKeydown(event) {
    this.navigator.handleKeydown(event)
  }

  selectFromKeyboard(li) {
    if (!li) return
    this.selectValue(li.getAttribute("data-value"))
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
    const items = this.dropdownTarget.querySelectorAll("li")
    const currentValue = this.selectTarget.value
    for (let i = 0; i < items.length; i++) {
      if (items[i].getAttribute("data-value") === currentValue) return i
    }
    return 0
  }
}
