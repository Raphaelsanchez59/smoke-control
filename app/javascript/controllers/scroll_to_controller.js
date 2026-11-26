import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    selector: { type: String, default: "#smoker-profiles, .row.row-cols-1.row-cols-md-3" },
    offset: { type: Number, default: 80 }
  }

  toTarget(event) {
    event.preventDefault()
    const target = document.querySelector(this.selectorValue)
    if (!target) return

    const top = target.getBoundingClientRect().top + window.scrollY - this.offsetValue
    window.scrollTo({ top: Math.max(0, top), behavior: "smooth" })
  }
}
