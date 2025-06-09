import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="theme"
export default class extends Controller {
static targets = ["label"]

  connect() {
    // Apply stored theme on load or fallback to existing attribute or light
    const stored = localStorage.getItem("theme");
    const initial = document.documentElement.getAttribute("data-bs-theme");
    const theme = stored || initial || "dark";
    document.documentElement.setAttribute("data-bs-theme", theme);

    // Initialize the toggle switch state and label
    const checkbox = this.element.querySelector("input[type=checkbox]");
    checkbox.checked = theme === "dark";
    this.labelTarget.textContent = theme.charAt(0).toUpperCase() + theme.slice(1);
  }

  toggle() {
    // Flip between light and dark
    const current = document.documentElement.getAttribute("data-bs-theme")
    const next = current === "dark" ? "light" : "dark"
    document.documentElement.setAttribute("data-bs-theme", next)
    localStorage.setItem("theme", next)

    // Update the label text
    this.labelTarget.textContent = next.charAt(0).toUpperCase() + next.slice(1);
  }
}
