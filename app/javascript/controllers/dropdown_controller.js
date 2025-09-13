import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu"]

  connect() {
    document.addEventListener("click", this.closeAllDropdownsOnOutsideClick)
  }

  disconnect() {
    document.removeEventListener("click", this.closeAllDropdownsOnOutsideClick)
  }

  toggle(event) {
    event.preventDefault()
    event.stopPropagation()
    this.closeAllDropdownsExceptCurrent()
    this.menuTarget.classList.toggle("opacity-0")
    this.menuTarget.classList.toggle("invisible")
    this.menuTarget.classList.toggle("opacity-100")
    this.menuTarget.classList.toggle("visible")
  }

  closeAllDropdownsExceptCurrent() {
    document.querySelectorAll('[data-controller="dropdown"]').forEach(controllerEl => {
      if (controllerEl !== this.element) {
        const menu = controllerEl.querySelector('[data-dropdown-target="menu"]')
        if (menu) {
          menu.classList.add("opacity-0", "invisible")
          menu.classList.remove("opacity-100", "visible")
        }
      }
    })
  }

  // Chiude tutti i dropdown se il click non è dentro nessun dropdown
  closeAllDropdownsOnOutsideClick = (event) => {
    // Se il click NON è dentro un qualsiasi dropdown
    if (!event.target.closest('[data-controller="dropdown"]')) {
      document.querySelectorAll('[data-controller="dropdown"]').forEach(controllerEl => {
        const menu = controllerEl.querySelector('[data-dropdown-target="menu"]')
        if (menu) {
          menu.classList.add("opacity-0", "invisible")
          menu.classList.remove("opacity-100", "visible")
        }
      })
    }
  }
}