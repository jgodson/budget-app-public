import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["categorySelect", "amountInput", "suggestionText", "averageAmount"]

  connect() {
    // If a category is already selected (e.g. edit), fetch the average
    if (this.categorySelectTarget.value) {
      this.fetchAverage()
    }
  }

  async fetchAverage() {
    const categoryId = this.categorySelectTarget.value
    
    if (!categoryId) {
      this.hideSuggestion()
      return
    }

    try {
      const response = await fetch(`/categories/${categoryId}/average_spending`, {
        headers: {
          "Accept": "application/json"
        }
      })

      if (response.ok) {
        const data = await response.json()
        if (data.average !== null && data.average > 0) {
          this.showSuggestion(data.average)
        } else {
          this.hideSuggestion()
        }
      } else {
        this.hideSuggestion()
      }
    } catch (error) {
      console.error("Error fetching average spending:", error)
      this.hideSuggestion()
    }
  }

  showSuggestion(amount) {
    // Format as currency
    const formattedAmount = new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: 'USD'
    }).format(amount)

    this.averageAmountTarget.textContent = formattedAmount
    this.averageAmountTarget.dataset.value = amount.toFixed(2) // Store raw value for filling
    this.suggestionTextTarget.classList.remove("d-none")
  }

  hideSuggestion() {
    this.suggestionTextTarget.classList.add("d-none")
    this.averageAmountTarget.textContent = ""
  }

  useSuggestion(event) {
    event.preventDefault()
    const amount = this.averageAmountTarget.dataset.value
    if (amount) {
      this.amountInputTarget.value = amount
      // Trigger change event if needed for other controllers
      this.amountInputTarget.dispatchEvent(new Event('change'))
      // Also trigger blur to format if using number-input controller
      this.amountInputTarget.dispatchEvent(new Event('blur'))
    }
  }
}
