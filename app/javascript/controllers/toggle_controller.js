import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  toggle() {
    const categoryId = this.element.dataset.categoryId
    const subcategoryRows = document.querySelectorAll(`.subcategory-row[data-parent-id="${categoryId}"]`)
    
    subcategoryRows.forEach(row => {
      row.classList.toggle('hidden-row')
    })
    
    this.element.classList.toggle('bi-chevron-right')
    this.element.classList.toggle('bi-chevron-down')
  }
}
