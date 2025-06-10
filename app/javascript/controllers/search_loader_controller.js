// app/javascript/controllers/search_loader_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.observeResults()
  }

  observeResults() {
    const resultsList = this.element.querySelector("#results_list")
    if (!resultsList) return

    this.observer = new MutationObserver(() => {
      if (resultsList.querySelector("[data-movie-card]")) {
        resultsList.querySelectorAll(".skeleton-card").forEach(el => el.remove())
      }
    })
    this.observer.observe(resultsList, { childList: true, subtree: true })
  }

  disconnect() {
    if (this.observer) this.observer.disconnect()
  }
}
