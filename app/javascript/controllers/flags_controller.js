import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="flags"
export default class extends Controller {
  static targets = ["flag_icon"]
  connect() {
    fetch("https://ipapi.co/json/")
  .then(res => res.json())
  .then(data => {
    this.flag_iconTarget.classList.add(`fi-${data.country_code.toLowerCase()}`);
  });
  }
}
