import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="share"
export default class extends Controller {
  static values = { title: String, text: String }

  share() {
    if (navigator.share) {
      navigator.share({
        title: this.titleValue,
        text: this.textValue,
        url: window.location.href
      })
    } else {
      // Fallback: copy link to clipboard
      navigator.clipboard.writeText(window.location.href).then(() => {
        alert("Link copied to clipboard!");
      }, () => {
        prompt("Copy this link:", window.location.href);
      });
    }
  }
}
