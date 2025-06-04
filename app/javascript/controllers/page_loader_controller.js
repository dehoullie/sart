import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="page-loader"
export default class extends Controller {
  connect() {
      document.addEventListener("DOMContentLoaded", function() {
      // Option A: Hide as soon as DOM is parsed (before images, etc. finish)
      const loader = document.getElementById("page-loader");
      if (loader) {
        loader.style.display = "none";
      }
    });
  }
}
