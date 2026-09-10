import { Controller } from "@hotwired/stimulus"
import { storage } from "lib/storage"

const ACTIVE_TAB_CLASSES = [ "border-blue-500", "text-blue-600" ]
const INACTIVE_TAB_CLASSES = [ "border-transparent", "text-gray-500", "hover:border-gray-300", "hover:text-gray-700" ]

export default class extends Controller {
  static targets = [
    "panel", "overlay", "mainContent",
    "hamburgerIcon", "closeIcon",
    "pinIcon",
    "tabButton", "tabContent"
  ]

  static values = {
    pinned: { type: Boolean, default: false },
    activeTab: { type: String, default: "settings" }
  }

  connect() {
    this.boundKeydown = this.keydown.bind(this)
    document.addEventListener("keydown", this.boundKeydown)
    this.hasBeenOpened = false

    this.smQuery = window.matchMedia("(min-width: 640px)")
    this.boundResize = this.handleResize.bind(this)
    this.smQuery.addEventListener("change", this.boundResize)

    if (storage.getBoolean("prose:editor-drawer-pinned") && this.smQuery.matches) {
      this.pin()
      this.open()
    }
  }

  disconnect() {
    document.removeEventListener("keydown", this.boundKeydown)
    this.smQuery.removeEventListener("change", this.boundResize)
  }

  handleResize(event) {
    // Visual unpin only — don't clear stored state so pinning restores on wider screens
    if (!event.matches && this.pinnedValue) this.applyUnpin()
  }

  get isOpen() {
    return this.hasPanelTarget && !this.panelTarget.classList.contains("translate-x-full")
  }

  // Whether this editor renders an AI tab — derived from the DOM so the drawer
  // carries no AI-specific values on editors without an AI panel.
  get hasAiTab() {
    return this.tabButtonTargets.some(btn => btn.dataset.tab === "ai")
  }

  toggle() {
    if (this.isOpen) this.close()
    else this.open()
  }

  open(tabName = null) {
    if (!this.hasBeenOpened) {
      this.hasBeenOpened = true
      this.element.querySelector(".animate-pulse-subtle")?.classList.remove("animate-pulse-subtle")
    }

    if (tabName) this.activeTabValue = tabName

    this.showTab(this.activeTabValue)
    this.setToggleIcon(true)

    if (this.pinnedValue) {
      this.slidePanel(true)
      this.setPinnedMargin(true)
    } else {
      this.overlayTarget.classList.remove("hidden")
      requestAnimationFrame(() => {
        this.overlayTarget.classList.remove("opacity-0")
        this.slidePanel(true)
      })
    }
  }

  close() {
    this.setToggleIcon(false)
    if (this.pinnedValue) this.setPinnedMargin(false)
    this.slidePanel(false)

    if (!this.pinnedValue) {
      this.overlayTarget.classList.add("opacity-0")
      this.panelTarget.addEventListener("transitionend", () => {
        this.overlayTarget.classList.add("hidden")
      }, { once: true })
    }
  }

  // Tab switching
  switchTab(event) {
    const tabName = event.currentTarget.dataset.tab
    this.activeTabValue = tabName
    this.showTab(tabName)
  }

  showTab(tabName) {
    this.tabButtonTargets.forEach(btn => {
      const active = btn.dataset.tab === tabName
      ACTIVE_TAB_CLASSES.forEach(c => btn.classList.toggle(c, active))
      INACTIVE_TAB_CLASSES.forEach(c => btn.classList.toggle(c, !active))
    })

    this.tabContentTargets.forEach(content => {
      content.classList.toggle("hidden", content.dataset.tab !== tabName)
    })

    // Dispatched on the panel so per-tab controllers mounted inside it can react
    // (e.g. ai-chat scrolling its message list into view).
    this.dispatch("tab-shown", {
      target: this.hasPanelTarget ? this.panelTarget : this.element,
      detail: { tab: tabName }
    })
  }

  // Pin/unpin
  togglePin() {
    if (this.pinnedValue) {
      this.unpin()
    } else {
      this.pin()
    }
  }

  pin() {
    if (!this.smQuery.matches) return
    this.pinnedValue = true
    storage.set("prose:editor-drawer-pinned", "true")
    this.overlayTarget.classList.add("hidden", "opacity-0")
    this.setPinnedMargin(true)
    this.setPinIcon(true)
  }

  unpin() {
    storage.set("prose:editor-drawer-pinned", "false")
    this.applyUnpin()
  }

  applyUnpin() {
    this.pinnedValue = false
    this.setPinnedMargin(false)
    this.setPinIcon(false)
    // Show overlay since panel is open and now unpinned
    if (this.isOpen) this.showOverlay()
  }

  setPinIcon(active) {
    if (!this.hasPinIconTarget) return
    this.pinIconTarget.classList.toggle("text-blue-600", active)
    this.pinIconTarget.classList.toggle("text-gray-400", !active)
  }

  showOverlay() {
    this.overlayTarget.classList.remove("hidden")
    requestAnimationFrame(() => this.overlayTarget.classList.remove("opacity-0"))
  }

  setPinnedMargin(pinned) {
    if (this.hasMainContentTarget) this.mainContentTarget.style.marginRight = pinned ? "28rem" : ""
  }

  setToggleIcon(open) {
    if (this.hasHamburgerIconTarget) this.hamburgerIconTarget.classList.toggle("hidden", open)
    if (this.hasCloseIconTarget) this.closeIconTarget.classList.toggle("hidden", !open)
  }

  slidePanel(open) {
    this.panelTarget.classList.toggle("translate-x-0", open)
    this.panelTarget.classList.toggle("translate-x-full", !open)
  }

  keydown(event) {
    // Cmd/Ctrl + Shift + A to toggle AI tab
    if ((event.metaKey || event.ctrlKey) && event.shiftKey && event.key === "A") {
      if (!this.hasAiTab) return
      event.preventDefault()
      if (this.isOpen && this.activeTabValue === "ai") {
        this.close()
      } else {
        this.open("ai")
      }
      return
    }

    // Escape to close (skip if a custom-select or tag-select dropdown is open)
    if (event.key === "Escape" && this.isOpen) {
      const openDropdown = document.querySelector("[data-custom-select-target='dropdown']:not(.hidden)")
      const openTagSelect = document.querySelector("[data-tag-select-target='dropdown']:not(.hidden)")
      if (openDropdown || openTagSelect) return
      this.close()
    }
  }
}
