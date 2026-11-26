import { Controller } from "@hotwired/stimulus"
import { request, requestTurboStream } from "lib/request"

// AI chat transport for the editor drawer's AI tab. Mounted only where an AI
// panel is rendered, so the drawer itself stays free of AI targets and values.
export default class extends Controller {
  static targets = ["messageInput", "messagesContainer"]

  // prompts: quick action key → the message sent for it.
  static values = { messagesUrl: String, conversationUrl: String, prompts: Object }

  connect() {
    this.scrollToBottom()
  }

  // Fired by editor-drawer when a tab becomes visible.
  tabShown(event) {
    if (event.detail.tab === "ai") this.scrollToBottom()
  }

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
    this.sendMessage(this.promptsValue[action] || action, action)
  }

  async sendMessage(content, quickAction = null) {
    const body = new URLSearchParams({ content })
    if (quickAction) body.set("quick_action", quickAction)

    const form = this.editorForm
    const title = form?.querySelector("[name='post[title]']")?.value
    const subtitle = form?.querySelector("[name='post[subtitle]']")?.value
    if (title !== undefined) body.set("title", title)
    if (subtitle !== undefined) body.set("subtitle", subtitle)

    await requestTurboStream(this.messagesUrlValue, {
      method: "POST",
      body
    })

    this.scrollToBottom()
  }

  scrollToBottom() {
    if (!this.hasMessagesContainerTarget) return
    requestAnimationFrame(() => {
      this.messagesContainerTarget.scrollTop = this.messagesContainerTarget.scrollHeight
    })
  }

  handleKeydown(event) {
    if (event.key === "Enter" && !event.shiftKey) {
      event.preventDefault()
      this.submitMessage(event)
    }
  }

  async clearConversation() {
    const response = await request(this.conversationUrlValue, {
      method: "POST",
      accept: "text/vnd.turbo-stream.html, text/html",
      body: new URLSearchParams({ conversation_type: "chat" })
    })

    if (response.redirected) window.Turbo.visit(response.url)
  }

  // The post form the autosave controller manages, so title/subtitle are read
  // from this editor rather than from anywhere in the document.
  get editorForm() {
    const host = this.element.closest("[data-controller~='autosave']")
    const autosave = host && this.application.getControllerForElementAndIdentifier(host, "autosave")
    return (host || document).querySelector(autosave?.formSelectorValue || "#post_form")
  }
}
