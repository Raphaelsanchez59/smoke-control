import { Controller } from "@hotwired/stimulus"

// Affiche la réponse de Smokey lettre par lettre
export default class extends Controller {
  connect() {
    this.pieces = []

    const walker = document.createTreeWalker(this.element, NodeFilter.SHOW_TEXT)
    while (walker.nextNode()) {
      this.pieces.push({ node: walker.currentNode, text: walker.currentNode.textContent })
    }

    this.pieces.forEach((piece) => { piece.node.textContent = "" })

    this.pieceIndex = 0
    this.letterIndex = 0
    this.timer = setInterval(() => this.typeLetter(), 35)
  }

  typeLetter() {
    const piece = this.pieces[this.pieceIndex]

    if (!piece) {
      clearInterval(this.timer)
      return
    }

    piece.node.textContent += piece.text[this.letterIndex]
    this.letterIndex++

    if (this.letterIndex >= piece.text.length) {
      this.pieceIndex++
      this.letterIndex = 0
    }
  }

  disconnect() {
    clearInterval(this.timer)
  }
}
