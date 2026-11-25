import { Controller } from "@hotwired/stimulus"

// Fait défiler la zone des messages tout en bas à chaque affichage
export default class extends Controller {
  connect() {
    this.element.scrollTop = this.element.scrollHeight
  }
}
