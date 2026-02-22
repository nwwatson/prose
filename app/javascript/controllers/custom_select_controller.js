import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["select", "trigger", "triggerText", "dropdown"]

  connect() {
    this.buildOptions()
    this.syncTriggerText()
    this.handleOutsideClick = this.handleOutsideClick.bind(this)
    this.handleKeydown = this.handleKeydown.bind(this)
    this.searchString = ""
    this.searchTimeout = null
  }

  disconnect() {
    document.removeEventListener("click", this.handleOutsideClick)
    document.removeEventListener("keydown", this.handleKeydown)
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
        ? `<span class="inline-block h-5 w-5 rounded border border-gray-300 shrink-0" style="background-color: ${this.escapeHtml(color)}"></span>`
        : ""
      const flexClass = color ? "flex items-center gap-2" : ""

      li.innerHTML = `
        <span class="${flexClass} block truncate">${swatchHtml}${this.escapeHtml(option.textContent)}</span>
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
        this.triggerTextTarget.innerHTML = `<span class="flex items-center gap-2"><span class="inline-block h-5 w-5 rounded border border-gray-300 shrink-0" style="background-color: ${this.escapeHtml(color)}"></span>${this.escapeHtml(selected.textContent)}</span>`
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

    document.addEventListener("click", this.handleOutsideClick)
    document.addEventListener("keydown", this.handleKeydown)

    // Scroll selected option into view
    const selected = dropdown.querySelector('[class*="bg-blue-600"]')
    if (selected) {
      selected.scrollIntoView({ block: "nearest" })
    }

    this.focusedIndex = this.selectedOptionIndex()
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

    document.removeEventListener("click", this.handleOutsideClick)
    document.removeEventListener("keydown", this.handleKeydown)
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

  handleOutsideClick(event) {
    if (!this.element.contains(event.target)) {
      this.close()
    }
  }

  handleKeydown(event) {
    const items = this.dropdownTarget.querySelectorAll("li")
    if (items.length === 0) return

    switch (event.key) {
      case "Escape":
        event.preventDefault()
        this.close()
        this.triggerTarget.focus()
        break
      case "ArrowDown":
        event.preventDefault()
        this.focusedIndex = Math.min((this.focusedIndex ?? -1) + 1, items.length - 1)
        this.highlightItem(items)
        break
      case "ArrowUp":
        event.preventDefault()
        this.focusedIndex = Math.max((this.focusedIndex ?? 1) - 1, 0)
        this.highlightItem(items)
        break
      case "Home":
        event.preventDefault()
        this.focusedIndex = 0
        this.highlightItem(items)
        break
      case "End":
        event.preventDefault()
        this.focusedIndex = items.length - 1
        this.highlightItem(items)
        break
      case "Enter":
      case " ":
        event.preventDefault()
        if (this.focusedIndex != null && items[this.focusedIndex]) {
          const value = items[this.focusedIndex].getAttribute("data-value")
          this.selectValue(value)
          this.close()
          this.triggerTarget.focus()
        }
        break
      default:
        // Type-ahead search
        if (event.key.length === 1) {
          this.typeAhead(event.key, items)
        }
        break
    }
  }

  typeAhead(char, items) {
    clearTimeout(this.searchTimeout)
    this.searchString += char.toLowerCase()
    this.searchTimeout = setTimeout(() => { this.searchString = "" }, 500)

    for (let i = 0; i < items.length; i++) {
      const text = items[i].querySelector("span").textContent.toLowerCase()
      if (text.startsWith(this.searchString)) {
        this.focusedIndex = i
        this.highlightItem(items)
        break
      }
    }
  }

  highlightItem(items) {
    items.forEach((li, i) => {
      if (i === this.focusedIndex) {
        li.classList.add("ring-2", "ring-inset", "ring-blue-400")
        li.scrollIntoView({ block: "nearest" })
      } else {
        li.classList.remove("ring-2", "ring-inset", "ring-blue-400")
      }
    })
  }

  selectedOptionIndex() {
    const items = this.dropdownTarget.querySelectorAll("li")
    const currentValue = this.selectTarget.value
    for (let i = 0; i < items.length; i++) {
      if (items[i].getAttribute("data-value") === currentValue) return i
    }
    return 0
  }

  escapeHtml(text) {
    const div = document.createElement("div")
    div.textContent = text
    return div.innerHTML
  }
}
