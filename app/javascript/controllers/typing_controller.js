import { Controller } from "@hotwired/stimulus"

// Affiche la bulle "l'assistant écrit…" dès qu'une réponse est envoyée
export default class extends Controller {
  static targets = ["messages", "template"]

  show() {
    this.messagesTarget.appendChild(this.templateTarget.content.cloneNode(true))
    this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight
  }
}
