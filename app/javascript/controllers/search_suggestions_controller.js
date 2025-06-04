import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="search-suggestions"
export default class extends Controller {
  static targets = ["cancelButton"]
  connect() {

  }
  onKeyUp(event) {
    // submit only after 3 characters
    // do if key is backspace or delete
    // if pressed key is esc, call onCancelClick
    if (event.key === "Escape") {
      this.onCancelClick(event);
      return;
    }
    if (event.key === "Backspace" || event.key === "Delete") {
      if (event.target.value.length == 0) {
        this.onCancelClick(event);
        return;
     }
    }
    if (event.target.value.length < 3) {
      return;
    }
    // if >= 3 runs the search
    if (event.target.value.length >= 3) {

      this.element.querySelector("input[type='search']").classList.add("border-end-0");
      this.cancelButtonTarget.classList.remove("d-none");
      this.element.requestSubmit();
      this.backButtonTarget.classList.remove("d-none");
    }
  }
  onCancelClick(event) {
    event.preventDefault();
    // clear the input field this controller itself
    this.element.querySelector("input[type='search']").value = "";
    // hide the cancel button
    this.cancelButtonTarget.classList.add("d-none");

    this.element.querySelector("input[type='search']").classList.remove("border-end-0");
    this.element.requestSubmit();
  }

  onBackClick(event) {
    event.preventDefault();
    // clear the input field this controller itself
    this.element.querySelector("input[type='search']").value = "";
    // hide the cancel button
    this.cancelButtonTarget.classList.add("d-none");

    this.element.querySelector("input[type='search']").classList.remove("border-end-0");
    // go back to the previous page
    window.history.back();
  }
}
