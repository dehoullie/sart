import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="bio-button"
export default class extends Controller {
  static targets = ["down", "up"]

  connect() {
    const button = this.element.querySelector('button')
    const collapseEl = document.querySelector(button.dataset.bsTarget)
    collapseEl.addEventListener('show.bs.collapse', () => this.show())
    collapseEl.addEventListener('hide.bs.collapse', () => this.hide())
  }

  show() {
    this.downTarget.classList.add('d-none')
    this.upTarget.classList.remove('d-none')
  }

  hide() {
    this.downTarget.classList.remove('d-none')
    this.upTarget.classList.add('d-none')
  }
}
