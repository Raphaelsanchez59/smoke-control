import { Controller } from "@hotwired/stimulus"

// Affiche la bulle "l'assistant écrit…" dès qu'une réponse est envoyée
export default class extends Controller {
  static targets = ["messages", "template", "input"]

  show(event) {
    if (event.submitter) event.submitter.disabled = true
    this.messagesTarget.appendChild(this.templateTarget.content.cloneNode(true))
    this.messagesTarget.lastElementChild.scrollIntoView({ behavior: "smooth" })
  }

  clearInput() {
    this.inputTarget.value = ""
  }
}
