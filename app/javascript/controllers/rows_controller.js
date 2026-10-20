import { Controller } from "@hotwired/stimulus"

// A list of same-shaped inputs (wrong answers, tags) with add and remove buttons.
export default class extends Controller {
  static targets = ["list", "template"]
  static values = { max: Number, min: { type: Number, default: 1 } }

  add() {
    if (this.maxValue && this.rows.length >= this.maxValue) return
    this.listTarget.insertAdjacentHTML("beforeend", this.templateTarget.innerHTML)
    this.rows.at(-1).querySelector("input").focus()
  }

  remove(event) {
    if (this.rows.length <= this.minValue) return
    event.target.closest("[data-row]").remove()
  }

  get rows() {
    return [...this.listTarget.querySelectorAll("[data-row]")]
  }
}
