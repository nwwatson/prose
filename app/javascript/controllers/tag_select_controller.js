import { Controller } from "@hotwired/stimulus"
import { requestJSON } from "lib/request"
import { useClickOutside } from "lib/click_outside"
import { ListboxNavigator } from "lib/listbox"

export default class extends Controller {
  static targets = [
    "emptyInput", "hiddenInputs", "comboBox", "pills",
    "searchInput", "dropdown", "option", "createOption", "createLabel",
    "pillTemplate", "optionTemplate", "checkmarkTemplate"
  ]

  static values = {
    createUrl: String,
    formAttr: String,
    fieldName: String
  }

  connect() {
    this.clickOutside = useClickOutside(this, { onClickOutside: () => this.close() })

    this.navigator = new ListboxNavigator({
      getItems: () => this.visibleOptions(),
      highlight: (item, on) => this.highlightOption(item, on),
      clearHighlight: () => this.clearHighlight(),
      onSelect: (item) => this.selectHighlighted(item),
      onEscape: (event) => this.escape(event),
      isOpen: () => this.isOpen,
      onOpenRequest: () => this.open()
    })
  }

  disconnect() {
    this.clickOutside.unobserve()
  }

  // --- Open / Close ---

  open() {
    this.dropdownTarget.classList.remove("hidden")
    this.navigator.reset()
    this.clickOutside.observe()
  }

  close() {
    this.dropdownTarget.classList.add("hidden")
    this.searchInputTarget.value = ""
    this.filter()
    this.navigator.reset()
    this.clickOutside.unobserve()
  }

  focusInput() {
    this.searchInputTarget.focus()
  }

  // --- Filter ---

  filter() {
    const query = this.searchInputTarget.value.trim().toLowerCase()
    let hasExactMatch = false

    this.optionTargets.forEach(option => {
      const name = option.dataset.tagName
      if (!query || name.includes(query)) {
        option.classList.remove("hidden")
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

    this.navigator.reset()
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
    const pill = this.cloneTemplate(this.pillTemplateTarget)
    pill.dataset.tagId = id
    pill.querySelector("[data-pill-name]").textContent = name
    pill.querySelector("button").dataset.tagId = id
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

    try {
      const data = await requestJSON(this.createUrlValue, {
        method: "POST",
        body: { tag: { name } }
      })

      // Insert new option alphabetically if it doesn't already exist
      if (!this.optionTargets.find(o => o.dataset.tagId === String(data.id))) {
        const li = this.cloneTemplate(this.optionTemplateTarget)
        li.dataset.tagId = data.id
        li.dataset.tagName = data.name.toLowerCase()
        li.querySelector("span").textContent = data.name

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
    if (this.navigator.handleKeydown(event)) return

    if (event.key === "Backspace" && this.searchInputTarget.value === "") {
      const pills = this.pillsTarget.querySelectorAll("[data-tag-id]")
      if (pills.length > 0) {
        const lastPill = pills[pills.length - 1]
        this.removeTagById(lastPill.dataset.tagId)
      }
    }
  }

  // Enter on a highlighted option toggles it; Enter with nothing highlighted
  // creates the tag currently typed into the search input.
  selectHighlighted(item) {
    if (item) {
      item.click()
    } else if (!this.createOptionTarget.classList.contains("hidden")) {
      this.createTag()
    }
  }

  escape(event) {
    event.stopPropagation()
    this.close()
    this.searchInputTarget.blur()
  }

  // --- Helpers ---

  get isOpen() {
    return !this.dropdownTarget.classList.contains("hidden")
  }

  isSelected(id) {
    return !!this.hiddenInputsTarget.querySelector(`input[data-tag-id="${id}"]`)
  }

  cloneTemplate(template) {
    return template.content.firstElementChild.cloneNode(true)
  }

  markOptionSelected(id, selected) {
    const option = this.optionTargets.find(o => o.dataset.tagId === String(id))
    if (!option) return

    if (selected) {
      option.classList.add("bg-blue-600", "text-white", "hover:bg-blue-700")
      option.classList.remove("text-gray-900", "hover:bg-gray-100")
      // Add checkmark
      if (!option.querySelector(".checkmark")) {
        option.appendChild(this.cloneTemplate(this.checkmarkTemplateTarget))
      }
    } else {
      option.classList.remove("bg-blue-600", "text-white", "hover:bg-blue-700")
      option.classList.add("text-gray-900", "hover:bg-gray-100")
      const check = option.querySelector(".checkmark")
      if (check) check.remove()
    }
  }

  visibleOptions() {
    const options = this.optionTargets.filter(o => !o.classList.contains("hidden"))
    if (!this.createOptionTarget.classList.contains("hidden")) {
      options.push(this.createOptionTarget)
    }
    return options
  }

  clearHighlight() {
    this.optionTargets.forEach(o => o.classList.remove("bg-gray-100"))
    if (this.hasCreateOptionTarget) this.createOptionTarget.classList.remove("bg-blue-50")
  }

  highlightOption(option, on) {
    if (!on) {
      option.classList.remove("bg-gray-100", "bg-blue-50")
      return
    }

    if (option === this.createOptionTarget) {
      option.classList.add("bg-blue-50")
    } else if (!option.classList.contains("bg-blue-600")) {
      option.classList.add("bg-gray-100")
    }
  }

  dispatchChange() {
    this.hiddenInputsTarget.dispatchEvent(new Event("change", { bubbles: true }))
  }
}
