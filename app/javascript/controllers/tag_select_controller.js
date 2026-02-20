import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "emptyInput", "hiddenInputs", "comboBox", "pills",
    "searchInput", "dropdown", "option", "createOption", "createLabel"
  ]

  static values = {
    createUrl: String,
    formAttr: String,
    fieldName: String
  }

  connect() {
    this.boundClickOutside = this.clickOutside.bind(this)
    document.addEventListener("click", this.boundClickOutside)
    this.highlightedIndex = -1
  }

  disconnect() {
    document.removeEventListener("click", this.boundClickOutside)
  }

  // --- Open / Close ---

  open() {
    this.dropdownTarget.classList.remove("hidden")
    this.highlightedIndex = -1
    this.clearHighlight()
  }

  close() {
    this.dropdownTarget.classList.add("hidden")
    this.searchInputTarget.value = ""
    this.filter()
    this.highlightedIndex = -1
    this.clearHighlight()
  }

  clickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.close()
    }
  }

  focusInput() {
    this.searchInputTarget.focus()
  }

  // --- Filter ---

  filter() {
    const query = this.searchInputTarget.value.trim().toLowerCase()
    let hasExactMatch = false
    let visibleCount = 0

    this.optionTargets.forEach(option => {
      const name = option.dataset.tagName
      if (!query || name.includes(query)) {
        option.classList.remove("hidden")
        visibleCount++
      } else {
        option.classList.add("hidden")
      }
      if (name === query) hasExactMatch = true
    })

    if (this.hasCreateOptionTarget) {
      if (query && !hasExactMatch && this.hasCreateUrlValue) {
        this.createOptionTarget.classList.remove("hidden")
        this.createLabelTarget.textContent = this.searchInputTarget.value.trim()
      } else {
        this.createOptionTarget.classList.add("hidden")
      }
    }

    this.highlightedIndex = -1
    this.clearHighlight()
  }

  // --- Selection ---

  toggleTag(event) {
    const li = event.currentTarget
    const id = li.dataset.tagId
    const name = li.querySelector("span").textContent.trim()

    if (this.isSelected(id)) {
      this.removeTagById(id)
    } else {
      this.selectTag(id, name)
    }
  }

  selectTag(id, name) {
    if (this.isSelected(id)) return

    // Add hidden input
    const input = document.createElement("input")
    input.type = "hidden"
    input.name = this.fieldNameValue
    input.value = id
    if (this.formAttrValue) input.setAttribute("form", this.formAttrValue)
    input.dataset.tagId = id
    this.hiddenInputsTarget.appendChild(input)

    // Add pill
    const pill = document.createElement("span")
    pill.className = "inline-flex items-center gap-1 rounded-full bg-blue-100 px-2.5 py-0.5 text-xs font-medium text-blue-700"
    pill.dataset.tagId = id
    pill.innerHTML = `${this.escapeHtml(name)}<button type="button" data-action="click->tag-select#removeTag" data-tag-id="${id}" class="ml-0.5 inline-flex items-center rounded-full hover:bg-blue-200 focus:outline-none" tabindex="-1"><svg class="h-3 w-3" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12"/></svg></button>`
    this.pillsTarget.appendChild(pill)

    // Update option style
    this.markOptionSelected(id, true)

    this.searchInputTarget.value = ""
    this.filter()
    this.dispatchChange()
  }

  removeTag(event) {
    event.stopPropagation()
    const id = event.currentTarget.dataset.tagId
    this.removeTagById(id)
  }

  removeTagById(id) {
    // Remove hidden input
    const input = this.hiddenInputsTarget.querySelector(`input[data-tag-id="${id}"]`)
    if (input) input.remove()

    // Remove pill
    const pill = this.pillsTarget.querySelector(`[data-tag-id="${id}"]`)
    if (pill) pill.remove()

    // Update option style
    this.markOptionSelected(id, false)

    this.dispatchChange()
  }

  // --- Create ---

  async createTag() {
    const name = this.searchInputTarget.value.trim()
    if (!name || !this.hasCreateUrlValue) return

    const csrfToken = document.querySelector("meta[name='csrf-token']")?.content

    try {
      const response = await fetch(this.createUrlValue, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": csrfToken,
          "Accept": "application/json"
        },
        body: JSON.stringify({ tag: { name } })
      })

      if (!response.ok) return

      const data = await response.json()

      // Insert new option alphabetically if it doesn't already exist
      if (!this.optionTargets.find(o => o.dataset.tagId === String(data.id))) {
        const li = document.createElement("li")
        li.dataset.tagSelectTarget = "option"
        li.dataset.tagId = data.id
        li.dataset.tagName = data.name.toLowerCase()
        li.dataset.action = "click->tag-select#toggleTag"
        li.setAttribute("role", "option")
        li.className = "relative cursor-pointer select-none py-2 pl-3 pr-9 text-gray-900 hover:bg-gray-100"
        li.innerHTML = `<span class="block truncate">${this.escapeHtml(data.name)}</span>`

        // Find insertion point (alphabetical by name)
        const insertBefore = this.optionTargets.find(o =>
          o.dataset.tagName > data.name.toLowerCase()
        )
        if (insertBefore) {
          this.dropdownTarget.insertBefore(li, insertBefore)
        } else {
          // Insert before the create option
          this.dropdownTarget.insertBefore(li, this.createOptionTarget)
        }
      }

      this.selectTag(String(data.id), data.name)
    } catch (e) {
      // Silently fail — user can retry
    }
  }

  // --- Keyboard Navigation ---

  handleKeydown(event) {
    const visibleOptions = this.visibleOptions()

    switch (event.key) {
      case "ArrowDown":
        event.preventDefault()
        if (!this.isOpen) { this.open(); return }
        this.highlightedIndex = Math.min(this.highlightedIndex + 1, visibleOptions.length - 1)
        this.updateHighlight(visibleOptions)
        break

      case "ArrowUp":
        event.preventDefault()
        this.highlightedIndex = Math.max(this.highlightedIndex - 1, 0)
        this.updateHighlight(visibleOptions)
        break

      case "Enter":
        event.preventDefault()
        if (this.highlightedIndex >= 0 && visibleOptions[this.highlightedIndex]) {
          visibleOptions[this.highlightedIndex].click()
        } else if (!this.createOptionTarget.classList.contains("hidden")) {
          this.createTag()
        }
        break

      case "Escape":
        event.stopPropagation()
        this.close()
        this.searchInputTarget.blur()
        break

      case "Backspace":
        if (this.searchInputTarget.value === "") {
          const pills = this.pillsTarget.querySelectorAll("[data-tag-id]")
          if (pills.length > 0) {
            const lastPill = pills[pills.length - 1]
            this.removeTagById(lastPill.dataset.tagId)
          }
        }
        break
    }
  }

  // --- Helpers ---

  get isOpen() {
    return !this.dropdownTarget.classList.contains("hidden")
  }

  isSelected(id) {
    return !!this.hiddenInputsTarget.querySelector(`input[data-tag-id="${id}"]`)
  }

  markOptionSelected(id, selected) {
    const option = this.optionTargets.find(o => o.dataset.tagId === String(id))
    if (!option) return

    if (selected) {
      option.classList.add("bg-blue-600", "text-white", "hover:bg-blue-700")
      option.classList.remove("text-gray-900", "hover:bg-gray-100")
      // Add checkmark
      let check = option.querySelector(".checkmark")
      if (!check) {
        const span = document.createElement("span")
        span.className = "checkmark absolute inset-y-0 right-0 flex items-center pr-3 text-white"
        span.innerHTML = '<svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M5 13l4 4L19 7"/></svg>'
        option.appendChild(span)
      }
    } else {
      option.classList.remove("bg-blue-600", "text-white", "hover:bg-blue-700")
      option.classList.add("text-gray-900", "hover:bg-gray-100")
      const check = option.querySelector(".checkmark")
      if (check) check.remove()
    }
  }

  visibleOptions() {
    const options = []
    this.optionTargets.forEach(o => {
      if (!o.classList.contains("hidden")) options.push(o)
    })
    if (!this.createOptionTarget.classList.contains("hidden")) {
      options.push(this.createOptionTarget)
    }
    return options
  }

  clearHighlight() {
    this.optionTargets.forEach(o => o.classList.remove("bg-gray-100"))
    if (this.hasCreateOptionTarget) this.createOptionTarget.classList.remove("bg-blue-50")
  }

  updateHighlight(visibleOptions) {
    this.clearHighlight()
    const target = visibleOptions[this.highlightedIndex]
    if (!target) return

    if (target === this.createOptionTarget) {
      target.classList.add("bg-blue-50")
    } else if (!target.classList.contains("bg-blue-600")) {
      target.classList.add("bg-gray-100")
    }
    target.scrollIntoView({ block: "nearest" })
  }

  dispatchChange() {
    this.hiddenInputsTarget.dispatchEvent(new Event("change", { bubbles: true }))
  }

  escapeHtml(str) {
    const div = document.createElement("div")
    div.textContent = str
    return div.innerHTML
  }
}
