import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "panel", "overlay", "mainContent",
    "hamburgerIcon", "closeIcon",
    "pinIcon",
    "tabButton", "tabContent",
    "messageInput", "messagesContainer"
  ]

  static values = {
    pinned: { type: Boolean, default: false },
    postSlug: String,
    aiAvailable: { type: Boolean, default: false },
    activeTab: { type: String, default: "settings" }
  }

  connect() {
    this.boundKeydown = this.keydown.bind(this)
    document.addEventListener("keydown", this.boundKeydown)
    this.hasBeenOpened = false
  }

  disconnect() {
    document.removeEventListener("keydown", this.boundKeydown)
  }

  get isOpen() {
    return this.hasPanelTarget && !this.panelTarget.classList.contains("translate-x-full")
  }

  toggle() {
    if (this.isOpen) {
      this.close()
    } else {
      this.open()
    }
  }

  open(tabName = null) {
    if (!this.hasBeenOpened) {
      this.hasBeenOpened = true
      this.element.querySelector(".animate-pulse-subtle")?.classList.remove("animate-pulse-subtle")
    }

    if (tabName) {
      this.activeTabValue = tabName
    }

    this.showTab(this.activeTabValue)

    if (this.hasHamburgerIconTarget) this.hamburgerIconTarget.classList.add("hidden")
    if (this.hasCloseIconTarget) this.closeIconTarget.classList.remove("hidden")

    if (this.pinnedValue) {
      this.panelTarget.classList.remove("translate-x-full")
      this.panelTarget.classList.add("translate-x-0")
      this.applyPinnedMargin()
    } else {
      this.overlayTarget.classList.remove("hidden")
      requestAnimationFrame(() => {
        this.overlayTarget.classList.remove("opacity-0")
        this.panelTarget.classList.remove("translate-x-full")
        this.panelTarget.classList.add("translate-x-0")
      })
    }

    if (this.activeTabValue === "ai") {
      this.scrollToBottom()
    }
  }

  close() {
    if (this.hasHamburgerIconTarget) this.hamburgerIconTarget.classList.remove("hidden")
    if (this.hasCloseIconTarget) this.closeIconTarget.classList.add("hidden")

    if (this.pinnedValue) {
      this.removePinnedMargin()
    }

    this.panelTarget.classList.remove("translate-x-0")
    this.panelTarget.classList.add("translate-x-full")

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

    if (tabName === "ai") {
      this.scrollToBottom()
    }
  }

  showTab(tabName) {
    this.tabButtonTargets.forEach(btn => {
      if (btn.dataset.tab === tabName) {
        btn.classList.add("border-blue-500", "text-blue-600")
        btn.classList.remove("border-transparent", "text-gray-500", "hover:border-gray-300", "hover:text-gray-700")
      } else {
        btn.classList.remove("border-blue-500", "text-blue-600")
        btn.classList.add("border-transparent", "text-gray-500", "hover:border-gray-300", "hover:text-gray-700")
      }
    })

    this.tabContentTargets.forEach(content => {
      if (content.dataset.tab === tabName) {
        content.classList.remove("hidden")
      } else {
        content.classList.add("hidden")
      }
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
    this.pinnedValue = true
    this.overlayTarget.classList.add("hidden")
    this.overlayTarget.classList.add("opacity-0")
    this.applyPinnedMargin()
    if (this.hasPinIconTarget) {
      this.pinIconTarget.classList.add("text-blue-600")
      this.pinIconTarget.classList.remove("text-gray-400")
    }
  }

  unpin() {
    this.pinnedValue = false
    this.removePinnedMargin()
    if (this.hasPinIconTarget) {
      this.pinIconTarget.classList.remove("text-blue-600")
      this.pinIconTarget.classList.add("text-gray-400")
    }
    // Show overlay since panel is open and now unpinned
    if (this.isOpen) {
      this.overlayTarget.classList.remove("hidden")
      requestAnimationFrame(() => {
        this.overlayTarget.classList.remove("opacity-0")
      })
    }
  }

  applyPinnedMargin() {
    if (this.hasMainContentTarget) {
      this.mainContentTarget.style.marginRight = "28rem"
    }
  }

  removePinnedMargin() {
    if (this.hasMainContentTarget) {
      this.mainContentTarget.style.marginRight = ""
    }
  }

  // AI messaging
  submitMessage(event) {
    event.preventDefault()
    if (!this.hasMessageInputTarget) return
    const content = this.messageInputTarget.value.trim()
    if (!content) return

    this.sendMessage(content)
    this.messageInputTarget.value = ""
    this.messageInputTarget.focus()
  }

  quickAction(event) {
    const action = event.currentTarget.dataset.quickAction
    const labels = {
      proofread: "Proofread my post",
      critique: "Critique my post",
      brainstorm: "Help me brainstorm ideas",
      social: "Write social media posts for my article"
    }
    this.sendMessage(labels[action] || action, action)
  }

  sendMessage(content, quickAction = null) {
    const form = document.createElement("form")
    form.method = "POST"
    form.action = `/admin/posts/${this.postSlugValue}/ai/messages`
    form.style.display = "none"

    const csrfToken = document.querySelector("meta[name='csrf-token']")?.content
    if (csrfToken) {
      const csrfField = document.createElement("input")
      csrfField.type = "hidden"
      csrfField.name = "authenticity_token"
      csrfField.value = csrfToken
      form.appendChild(csrfField)
    }

    const contentField = document.createElement("input")
    contentField.type = "hidden"
    contentField.name = "content"
    contentField.value = content
    form.appendChild(contentField)

    if (quickAction) {
      const actionField = document.createElement("input")
      actionField.type = "hidden"
      actionField.name = "quick_action"
      actionField.value = quickAction
      form.appendChild(actionField)
    }

    const titleEl = document.querySelector("[name='post[title]']")
    const subtitleEl = document.querySelector("[name='post[subtitle]']")
    if (titleEl) {
      const f = document.createElement("input")
      f.type = "hidden"
      f.name = "title"
      f.value = titleEl.value
      form.appendChild(f)
    }
    if (subtitleEl) {
      const f = document.createElement("input")
      f.type = "hidden"
      f.name = "subtitle"
      f.value = subtitleEl.value
      form.appendChild(f)
    }

    form.setAttribute("data-turbo", "true")
    form.setAttribute("accept", "text/vnd.turbo-stream.html")

    document.body.appendChild(form)
    form.requestSubmit()
    document.body.removeChild(form)

    this.scrollToBottom()
  }

  scrollToBottom() {
    if (this.hasMessagesContainerTarget) {
      requestAnimationFrame(() => {
        this.messagesContainerTarget.scrollTop = this.messagesContainerTarget.scrollHeight
      })
    }
  }

  handleKeydown(event) {
    if (event.key === "Enter" && !event.shiftKey) {
      event.preventDefault()
      this.submitMessage(event)
    }
  }

  clearConversation() {
    const csrfToken = document.querySelector("meta[name='csrf-token']")?.content
    fetch(`/admin/posts/${this.postSlugValue}/ai/conversation`, {
      method: "POST",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
        "X-CSRF-Token": csrfToken,
        "Accept": "text/vnd.turbo-stream.html, text/html"
      },
      body: "conversation_type=chat"
    })
    .then(response => {
      if (response.redirected) {
        window.Turbo.visit(response.url)
      }
    })
  }

  keydown(event) {
    // Cmd/Ctrl + Shift + A to toggle AI tab
    if ((event.metaKey || event.ctrlKey) && event.shiftKey && event.key === "A") {
      if (!this.aiAvailableValue) return
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
