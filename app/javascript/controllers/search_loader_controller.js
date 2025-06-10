// app/javascript/controllers/search_loader_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    query:   String,
    threshold: Number
  }

  connect() {
    // if no query or already enough results, do nothing
    if (!this.queryValue || this.countResults() >= this.thresholdValue) return

    this.showLoader()
    this.startPolling()
  }

  disconnect() {
    clearInterval(this.interval)
  }

  countResults() {
    // assumes each result is wrapped in a `.card`
    return this.element.querySelectorAll(".card").length
  }

  showLoader() {
    document.getElementById("loader").classList.remove("d-none")
  }
  hideLoader() {
    document.getElementById("loader").classList.add("d-none")
  }

  startPolling() {
    this.interval = setInterval(async () => {
      const url = `/movies?query=${encodeURIComponent(this.queryValue)}`
      let res  = await fetch(url, { headers: { "Accept": "text/vnd.turbo-stream.html" } })
      if (!res.ok) return

      let html = await res.text()
      // replace the whole frame’s innerHTML with new turbo-stream response
      this.element.innerHTML = html

      if (this.countResults() >= this.thresholdValue) {
        this.hideLoader()
        clearInterval(this.interval)
      }
    }, 3000) // every 3s
  }
}
