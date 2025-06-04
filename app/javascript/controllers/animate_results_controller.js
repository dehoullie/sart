import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["card"];

  _connect() {
    this.cardTargets.forEach((card, index) => {
      // Add the fadeInLeft animation class
      card.classList.add("animate__fadeInLeft");
      // Stagger the delay (0.1s * index)
      const delay = 0.1 * index;
      // Animate.css respects the --animate-delay CSS variable
      card.style.setProperty("--animate-delay", `${delay}s`);
    });
  }
}
