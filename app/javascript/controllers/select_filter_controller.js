import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "select"]
  static values = { submitForm: Boolean }

  connect() {
    this.originalOptions = Array.from(this.selectTarget.options).map((option) => ({
      value: option.value,
      text: option.text,
      disabled: option.disabled,
      selected: option.selected,
    }))

    this.availableOptions = this.originalOptions.filter((option) => option.value !== "")

    this.element.classList.add("position-relative")
    this.inputTarget.setAttribute("autocomplete", "off")

    this.buildDropdown()
    this.renderOptions()
    this.syncInputFromSelect()

    this.boundPositionClearButton = this.positionClearButton.bind(this)
    this.boundAdjustInputPadding = this.adjustInputPadding.bind(this)
    window.addEventListener("resize", this.boundPositionClearButton)
    window.addEventListener("resize", this.boundAdjustInputPadding)
    requestAnimationFrame(() => this.positionClearButton())
    requestAnimationFrame(() => this.adjustInputPadding())
  }

  disconnect() {
    this.dropdown?.remove()
    if (this.clearButton) {
      this.clearButton.removeEventListener("click", this.clearHandler)
      this.clearButton.remove()
    }
    if (this.boundPositionClearButton) {
      window.removeEventListener("resize", this.boundPositionClearButton)
    }
    if (this.boundAdjustInputPadding) {
      window.removeEventListener("resize", this.boundAdjustInputPadding)
    }
  }

  filter() {
    const query = this.inputTarget.value.trim().toLowerCase()
    this.renderOptions(query)
    this.openDropdown()
  }

  handleKeydown(event) {
    if (["ArrowDown", "ArrowUp", "Enter", "Escape"].includes(event.key)) {
      event.preventDefault()
    }

    if (event.key === "ArrowDown") this.moveActive(1)
    if (event.key === "ArrowUp") this.moveActive(-1)
    if (event.key === "Enter") this.chooseActive()
    if (event.key === "Escape") this.closeDropdown()
  }

  openDropdown() {
    if (!this.dropdown.classList.contains("show")) {
      this.dropdown.classList.add("show")
    }
  }

  closeDropdown() {
    this.dropdown.classList.remove("show")
    this.activeIndex = undefined
    this.updateActiveStyles()
  }

  syncInputFromSelect() {
    const selectedOption = this.originalOptions.find(
      (option) => option.value === this.selectTarget.value
    )

    this.inputTarget.value = selectedOption?.value ? selectedOption.text : ""
  }

  syncInput() {
    this.syncInputFromSelect()
  }

  clear(event) {
    event?.preventDefault()
    this.inputTarget.value = ""
    this.selectTarget.value = ""
    this.closeDropdown()
    this.dispatchChange()
    if (this.submitFormValue) this.submitForm()
    this.renderOptions("")
    this.inputTarget.focus()
  }

  dispatchChange() {
    this.selectTarget.dispatchEvent(new Event("change", { bubbles: true }))
  }

  buildDropdown() {
    if (this.clearButton) {
      this.clearButton.removeEventListener("click", this.clearHandler)
      this.clearButton.remove()
    }

    this.dropdown = document.createElement("div")
    this.dropdown.classList.add("dropdown-menu", "w-100", "shadow-sm")
    this.dropdown.style.maxHeight = "16rem"
    this.dropdown.style.overflowY = "auto"
    this.dropdown.style.zIndex = "1000"
    this.dropdown.setAttribute("role", "listbox")

    this.inputTarget.insertAdjacentElement("afterend", this.dropdown)

    this.clearButton = document.createElement("button")
    this.clearButton.type = "button"
    this.clearButton.className =
      "btn btn-link text-secondary position-absolute p-0 d-flex align-items-center select-filter-clear"
    this.clearButton.setAttribute("aria-label", "Clear category selection")
    this.clearButton.innerHTML = '<i class="bi bi-x-circle"></i>'
    this.clearHandler = this.clear.bind(this)
    this.clearButton.addEventListener("click", this.clearHandler)
    this.element.appendChild(this.clearButton)
  }

  renderOptions(query = "") {
    const lowerQuery = query.toLowerCase()

    const matches = this.availableOptions.filter((option) =>
      option.text.toLowerCase().includes(lowerQuery)
    )

    this.visibleOptions = []

    if (matches.length === 0) {
      const fallbackText =
        this.availableOptions.length === 0
          ? "No categories available"
          : "No categories matching text found"
      this.visibleOptions.push({
        value: "",
        text: fallbackText,
        selectable: false,
        muted: true,
      })
    } else {
      matches.forEach((option) => {
        this.visibleOptions.push({ ...option, selectable: !option.disabled })
      })
    }

    this.renderDropdownItems()
  }

  renderDropdownItems() {
    this.dropdown.innerHTML = ""

    this.visibleOptions.forEach((option, index) => {
      const item = document.createElement("button")
      item.type = "button"
      item.className = "dropdown-item py-2 px-3 text-start"
      item.textContent = option.text
      item.setAttribute("role", "option")
      item.dataset.index = index

      if (!option.selectable) {
        item.classList.add("disabled", "text-secondary", "small")
        item.setAttribute("aria-disabled", "true")
        item.tabIndex = -1
      } else {
        item.addEventListener("mousedown", (event) => {
          event.preventDefault()
          this.selectOption(index)
        })
      }

      this.dropdown.appendChild(item)
    })

    this.updateActiveStyles()
  }

  selectOption(index) {
    const option = this.visibleOptions[index]
    if (!option || !option.selectable) return

    this.selectTarget.value = option.value
    this.inputTarget.value = option.text
    this.closeDropdown()
    this.dispatchChange()
    if (this.submitFormValue) this.submitForm()
  }

  moveActive(delta) {
    if (!this.visibleOptions?.length) return

    const hasSelectable = this.visibleOptions.some((option) => option.selectable)
    if (!hasSelectable) return

    const startIndex = typeof this.activeIndex === "number" ? this.activeIndex : -1
    let nextIndex = startIndex

    do {
      nextIndex = (nextIndex + delta + this.visibleOptions.length) % this.visibleOptions.length
    } while (this.visibleOptions[nextIndex] && !this.visibleOptions[nextIndex].selectable && nextIndex !== startIndex)

    if (this.visibleOptions[nextIndex]?.selectable) {
      this.activeIndex = nextIndex
      this.updateActiveStyles()
      this.inputTarget.value = this.visibleOptions[nextIndex].text
      this.scrollActiveIntoView()
    }
  }

  chooseActive() {
    if (typeof this.activeIndex === "number") {
      this.selectOption(this.activeIndex)
    }
  }

  updateActiveStyles() {
    Array.from(this.dropdown.children).forEach((child, index) => {
      if (index === this.activeIndex && this.visibleOptions[index]?.selectable) {
        child.classList.add("active")
        child.setAttribute("aria-selected", "true")
      } else {
        child.classList.remove("active")
        child.removeAttribute("aria-selected")
      }
    })
  }

  scrollActiveIntoView() {
    const activeChild = this.dropdown.children[this.activeIndex]
    if (!activeChild) return

    activeChild.scrollIntoView({ block: "nearest" })
  }

  positionClearButton() {
    if (!this.clearButton || !this.inputTarget) return

    const inputRect = this.inputTarget.getBoundingClientRect()
    const hostRect = this.element.getBoundingClientRect()
    const offsetTop = inputRect.top - hostRect.top + inputRect.height / 2

    this.clearButton.style.top = `${offsetTop}px`
    this.clearButton.style.transform = "translateY(-50%)"

    const offsetRight = hostRect.right - inputRect.right
    this.clearButton.style.right = `${offsetRight + 12}px`
  }

  adjustInputPadding() {
    if (!this.clearButton || !this.inputTarget) return

    const buttonWidth = this.clearButton.getBoundingClientRect().width
    const currentPadding = window
      .getComputedStyle(this.inputTarget)
      .paddingRight.replace("px", "")

    const desiredPadding = Math.ceil(buttonWidth + 18)

    if (Number(currentPadding) < desiredPadding) {
      this.inputTarget.style.paddingRight = `${desiredPadding}px`
    }
  }

  submitForm() {
    const form = this.element.closest("form")
    if (form) form.requestSubmit()
  }
}
