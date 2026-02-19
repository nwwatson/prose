import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel", "overlay", "mainContent", "messageInput", "messagesContainer",
                     "titleField", "subtitleField", "contentField"]
  static values = {
    pinned: { type: Boolean, default: false },
    postSlug: String
  }

  connect() {
    this.boundKeydown = this.keydown.bind(this)
    document.addEventListener("keydown", this.boundKeydown)
  }

  disconnect() {
    document.removeEventListener("keydown", this.boundKeydown)
  }

  toggle() {
    if (this.panelTarget.classList.contains("translate-x-full")) {
      this.open()
    } else {
      this.close()
    }
  }

  open() {
    if (this.pinnedValue) {
      this.panelTarget.classList.remove("translate-x-full")
      this.panelTarget.classList.add("translate-x-0")
      if (this.hasMainContentTarget) {
        this.mainContentTarget.classList.add("mr-96")
      }
    } else {
      this.overlayTarget.classList.remove("hidden")
      requestAnimationFrame(() => {
        this.overlayTarget.classList.remove("opacity-0")
        this.panelTarget.classList.remove("translate-x-full")
        this.panelTarget.classList.add("translate-x-0")
      })
    }
    this.scrollToBottom()
  }

  close() {
    if (this.pinnedValue) {
      this.panelTarget.classList.remove("translate-x-0")
      this.panelTarget.classList.add("translate-x-full")
      if (this.hasMainContentTarget) {
        this.mainContentTarget.classList.remove("mr-96")
      }
    } else {
      this.overlayTarget.classList.add("opacity-0")
      this.panelTarget.classList.remove("translate-x-0")
      this.panelTarget.classList.add("translate-x-full")
      this.panelTarget.addEventListener("transitionend", () => {
        this.overlayTarget.classList.add("hidden")
      }, { once: true })
    }
  }

  pin() {
    this.pinnedValue = true
    this.overlayTarget.classList.add("hidden")
    this.overlayTarget.classList.add("opacity-0")
    if (this.hasMainContentTarget) {
      this.mainContentTarget.classList.add("mr-96")
    }
    this.element.querySelector("[data-pin-icon]")?.classList.add("text-indigo-600")
  }

  unpin() {
    this.pinnedValue = false
    if (this.hasMainContentTarget) {
      this.mainContentTarget.classList.remove("mr-96")
    }
    this.element.querySelector("[data-pin-icon]")?.classList.remove("text-indigo-600")
  }

  togglePin() {
    if (this.pinnedValue) {
      this.unpin()
    } else {
      this.pin()
    }
  }

  submitMessage(event) {
    event.preventDefault()
    const input = this.messageInputTarget
    const content = input.value.trim()
    if (!content) return

    this.sendMessage(content)
    input.value = ""
    input.focus()
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

    // CSRF token
    const csrfToken = document.querySelector("meta[name='csrf-token']")?.content
    if (csrfToken) {
      const csrfField = document.createElement("input")
      csrfField.type = "hidden"
      csrfField.name = "authenticity_token"
      csrfField.value = csrfToken
      form.appendChild(csrfField)
    }

    // Content
    const contentField = document.createElement("input")
    contentField.type = "hidden"
    contentField.name = "content"
    contentField.value = content
    form.appendChild(contentField)

    // Quick action
    if (quickAction) {
      const actionField = document.createElement("input")
      actionField.type = "hidden"
      actionField.name = "quick_action"
      actionField.value = quickAction
      form.appendChild(actionField)
    }

    // Live content sync - grab current editor content
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

    // Accept turbo stream
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

  keydown(event) {
    // Cmd/Ctrl + Shift + A to toggle panel
    if ((event.metaKey || event.ctrlKey) && event.shiftKey && event.key === "A") {
      event.preventDefault()
      this.toggle()
    }

    // Escape to close
    if (event.key === "Escape" && !this.panelTarget.classList.contains("translate-x-full")) {
      this.close()
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
}
