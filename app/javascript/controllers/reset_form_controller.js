import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="reset-form"
export default class extends Controller {
  static targets = ["form", "list", "listItem"];
  connect() {
    this.scrollToBottom();
  }
  reset() {
    this.formTarget.reset()
    this.scrollToBottom();
  }

  scrollToBottom() {
    this.listTarget.scrollTo(0, this.listTarget.scrollHeight);
  }

  listItemTargetConnected() {
    this.scrollToBottom();
  }
}
