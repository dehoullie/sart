// app/javascript/controllers/autohide_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    // don’t hide until we’ve scrolled at least this far from the top (optional)
    offset: { type: Number, default: 0 }
  }

  connect() {
    this.lastScrollY = window.pageYOffset
    this.callback = this.onScroll.bind(this)
    window.addEventListener("scroll", this.callback, { passive: true })
  }

  disconnect() {
    window.removeEventListener("scroll", this.callback)
  }

  onScroll() {
    const currentY = window.pageYOffset

    if (currentY > this.lastScrollY && currentY > this.offsetValue) {
      // scrolling down & past offset → hide
      this.element.classList.add("hidden")
    } else {
      // scrolling up → show
      this.element.classList.remove("hidden")
    }

    this.lastScrollY = currentY
  }
}
