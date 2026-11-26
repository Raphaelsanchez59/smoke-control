import { Controller } from "@hotwired/stimulus"

// Fait défiler la page jusqu'au dernier message à chaque affichage
export default class extends Controller {
  connect() {
    this.element.lastElementChild?.scrollIntoView()
  }
}
