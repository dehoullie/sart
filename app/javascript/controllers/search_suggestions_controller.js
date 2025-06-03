import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="search-suggestions"
export default class extends Controller {
  connect() {

  }
  onKeyUp(event) {
    // submit only after 3 characters
    // do if key is backspace or delete
    if (event.key === "Backspace" || event.key === "Delete") {
      if (event.target.value.length == 0) {
      this.element.requestSubmit();
     }
    }
    if (event.target.value.length < 3) {
      return;
    }
    this.element.requestSubmit();
  }
}
