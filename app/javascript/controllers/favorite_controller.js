import { Controller } from "@hotwired/stimulus"


export default class extends Controller {
  static targets = ["heart"]

  animate() {
    this.element.classList.add("animate__bounce")
  }
}
