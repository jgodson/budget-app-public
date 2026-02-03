import { Controller } from "@hotwired/stimulus"
import "chart.js"

// Connects to data-controller="amortization-calculator"
export default class extends Controller {
  static targets = [
    "loanSelect",
    "amount",
    "rate",
    "termYears",
    "termMonths",
    "payment",
    "paymentFrequency",
    "startDate",
    "extraMonthlyAmount",
    "extraMonthlyStart",
    "extraYearlyAmount",
    "extraYearlyStart",
    "oneTimeList",
    "oneTimeTemplate",
    "warning",
    "paymentSummary",
    "totalPaid",
    "principalPaid",
    "interestPaid",
    "payoffDate",
    "interestSaved",
    "principalBar",
    "interestBar",
    "principalPercent",
    "interestPercent",
    "yearlyTableBody",
    "chartEmpty",
    "chart"
  ]

  static values = {
    loans: Array
  }

  connect() {
    if (document.documentElement.hasAttribute("data-turbo-preview")) return

    this.currencyFormatter = new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' })
    this.inputNumberFormatter = new Intl.NumberFormat('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })
    this.percentFormatter = new Intl.NumberFormat('en-US', { style: 'percent', maximumFractionDigits: 1 })

    if (!this.startDateTarget.value) {
      this.startDateTarget.value = this.todayISO()
    }

    if (!this.termYearsTarget.value && !this.termMonthsTarget.value) {
      this.termYearsTarget.value = 5
      this.termMonthsTarget.value = 0
    }

    if (!this.amountTarget.value) {
      this.amountTarget.value = this.formatInputNumber(50000)
    }

    if (!this.rateTarget.value) {
      this.rateTarget.value = this.formatInputNumber(5)
    }

    if (!this.paymentFrequencyTarget.dataset.previousFrequency) {
      this.paymentFrequencyTarget.dataset.previousFrequency = this.paymentFrequencyTarget.value || "monthly"
    }

    this.paymentMode = false
    this.isUpdatingPayment = false
    this.isUpdatingTerm = false

    this.recalculate()

    this.themeChangeListener = () => this.updateChartTheme()
    window.addEventListener('theme-changed', this.themeChangeListener)
  }

  disconnect() {
    if (this.chartInstance) {
      this.chartInstance.destroy()
    }
    window.removeEventListener('theme-changed', this.themeChangeListener)
  }

  amountEdited() {
    this.paymentMode = false
  }

  rateEdited() {
    this.paymentMode = false
  }

  termEdited() {
    if (this.isUpdatingTerm) return
    this.paymentMode = false
    this.normalizeTermInputs()
  }

  paymentEdited() {
    if (this.isUpdatingPayment) return
    this.paymentMode = true
  }

  paymentFrequencyChanged() {
    const previousFrequency = this.paymentFrequencyTarget.dataset.previousFrequency || "monthly"
    const previousFactor = this.frequencyToMonthlyFactor(previousFrequency)
    const nextFactor = this.frequencyToMonthlyFactor(this.paymentFrequencyTarget.value)
    const currentAmount = this.parseNumber(this.paymentTarget.value)
    if (currentAmount <= 0) {
      this.paymentFrequencyTarget.dataset.previousFrequency = this.paymentFrequencyTarget.value
      this.paymentMode = false
      this.paymentTarget.value = ""
      this.recalculate()
      return
    }

    const monthlyEquivalent = currentAmount * previousFactor
    const nextAmount = monthlyEquivalent / nextFactor

    this.paymentTarget.value = this.formatInputNumber(nextAmount)
    this.paymentFrequencyTarget.dataset.previousFrequency = this.paymentFrequencyTarget.value
    this.paymentMode = true
    this.recalculate()
  }

  applyLoan() {
    const loanId = this.loanSelectTarget.value
    if (!loanId) {
      this.paymentMode = false
      this.recalculate()
      return
    }

    const loan = this.loansValue.find((item) => String(item.id) === String(loanId))
    if (!loan) {
      this.recalculate()
      return
    }

    if (!this.startDateTarget.value) {
      this.startDateTarget.value = this.todayISO()
    }

    if (!this.termYearsTarget.value && !this.termMonthsTarget.value) {
      this.termYearsTarget.value = 30
      this.termMonthsTarget.value = 0
    }

    this.amountTarget.value = loan.balance_dollars ? this.formatInputNumber(loan.balance_dollars) : ""
    if (loan.last_payment_dollars && loan.last_payment_dollars > 0) {
      this.paymentTarget.value = this.formatInputNumber(loan.last_payment_dollars)
      this.paymentMode = true
    } else {
      this.paymentTarget.value = ""
      this.paymentMode = false
    }

    this.recalculate()
  }

  addOneTimePayment(event) {
    event.preventDefault()
    const fragment = this.oneTimeTemplateTarget.content.cloneNode(true)
    this.oneTimeListTarget.appendChild(fragment)
  }

  removeOneTimePayment(event) {
    event.preventDefault()
    const row = event.currentTarget.closest(".row")
    if (row) {
      row.remove()
      this.recalculate()
    }
  }

  recalculate() {
    this.clearWarning()

    const principal = this.parseNumber(this.amountTarget.value)
    const annualRate = this.parseNumber(this.rateTarget.value)
    this.normalizeTermInputs()
    const termYearsInput = this.parseNumber(this.termYearsTarget.value)
    const normalizedMonthsInput = this.parseNumber(this.termMonthsTarget.value)
    let termMonths = Math.max(0, (termYearsInput * 12) + normalizedMonthsInput)
    const startDate = this.parseDate(this.startDateTarget.value)

    if (principal <= 0 || !startDate) {
      this.resetOutputs()
      return
    }

    const paymentFrequencyFactor = this.frequencyToMonthlyFactor(this.paymentFrequencyTarget.value)
    const paymentAmount = this.parseNumber(this.paymentTarget.value)
    let monthlyPayment = paymentAmount * paymentFrequencyFactor
    let calculatedPayment = null
    const monthlyRate = annualRate / 100 / 12

    if (this.paymentMode && monthlyPayment > 0) {
      const computedTermMonths = this.calculateTermMonths(principal, monthlyRate, monthlyPayment)
      if (!computedTermMonths) {
        this.showWarning("Payment is not enough to cover interest. Increase payment or reduce rate.")
        this.resetOutputs()
        return
      }
      termMonths = Math.max(1, Math.ceil(computedTermMonths))
      this.updateTermValue(termMonths)
    } else if (termMonths <= 0) {
      this.resetOutputs()
      return
    } else if (monthlyPayment <= 0) {
      calculatedPayment = this.calculatePayment(principal, monthlyRate, termMonths)
      monthlyPayment = calculatedPayment
    } else {
      calculatedPayment = this.calculatePayment(principal, monthlyRate, termMonths)
      monthlyPayment = calculatedPayment
    }

    if (!this.paymentMode && calculatedPayment) {
      this.updatePaymentValue(calculatedPayment / paymentFrequencyFactor)
    }

    const extras = this.extractExtras()
    const scheduleResult = this.buildSchedule({
      principal,
      monthlyRate,
      monthlyPayment,
      termMonths,
      startDate,
      extras
    })

    if (scheduleResult.warning) {
      this.showWarning(scheduleResult.warning)
    }

    const baselineResult = this.buildSchedule({
      principal,
      monthlyRate,
      monthlyPayment,
      termMonths,
      startDate,
      extras: { monthly: null, yearly: null, oneTime: {} },
      skipWarning: true
    })

    this.updateSummary({
      monthlyPayment,
      calculatedPayment,
      totals: scheduleResult.totals,
      payoffDate: scheduleResult.payoffDate,
      baselineInterest: baselineResult.totals.totalInterest
    })

    this.renderYearlyTable(scheduleResult.schedule)
    this.renderChart(scheduleResult.schedule)
  }

  extractExtras() {
    const monthlyAmount = this.parseNumber(this.extraMonthlyAmountTarget.value)
    const monthlyStart = this.parseMonthIndex(this.extraMonthlyStartTarget.value)
    const yearlyAmount = this.parseNumber(this.extraYearlyAmountTarget.value)
    const yearlyStart = this.parseMonthIndex(this.extraYearlyStartTarget.value)

    const oneTimeMap = {}
    this.oneTimeListTarget.querySelectorAll(".row").forEach((row) => {
      const dateInput = row.querySelector(".one-time-date")
      const amountInput = row.querySelector(".one-time-amount")
      const monthIndex = this.parseMonthIndex(dateInput?.value)
      const amount = this.parseNumber(amountInput?.value)
      if (monthIndex !== null && amount > 0) {
        oneTimeMap[monthIndex] = (oneTimeMap[monthIndex] || 0) + amount
      }
    })

    return {
      monthly: monthlyAmount > 0 && monthlyStart !== null ? { amount: monthlyAmount, startIndex: monthlyStart } : null,
      yearly: yearlyAmount > 0 && yearlyStart !== null ? { amount: yearlyAmount, startIndex: yearlyStart, month: yearlyStart % 12 } : null,
      oneTime: oneTimeMap
    }
  }


  buildSchedule({ principal, monthlyRate, monthlyPayment, termMonths, startDate, extras, skipWarning = false }) {
    const schedule = []
    let balance = principal
    let totalPaid = 0
    let totalPrincipal = 0
    let totalInterest = 0
    let warning = null

    for (let i = 0; i < termMonths; i += 1) {
      if (balance <= 0) break

      const paymentDate = this.addMonths(startDate, i)
      const monthIndex = paymentDate.getFullYear() * 12 + paymentDate.getMonth()
      const interest = balance * monthlyRate
      let extraPayment = 0

      if (extras.monthly && monthIndex >= extras.monthly.startIndex) {
        extraPayment += extras.monthly.amount
      }

      if (extras.yearly && monthIndex >= extras.yearly.startIndex && paymentDate.getMonth() === extras.yearly.month) {
        extraPayment += extras.yearly.amount
      }

      if (extras.oneTime && extras.oneTime[monthIndex]) {
        extraPayment += extras.oneTime[monthIndex]
      }

      let totalPayment = monthlyPayment + extraPayment

      if (totalPayment <= interest) {
        if (!skipWarning) {
          warning = "Payment is not enough to cover interest. Increase payment or reduce rate."
        }
        break
      }

      let principalPaid = totalPayment - interest
      if (principalPaid > balance) {
        principalPaid = balance
        totalPayment = interest + principalPaid
      }

      balance -= principalPaid
      if (balance < 0.01) {
        balance = 0
      }
      totalPaid += totalPayment
      totalPrincipal += principalPaid
      totalInterest += interest

      schedule.push({
        date: paymentDate,
        payment: totalPayment,
        principal: principalPaid,
        interest,
        balance
      })
    }

    const payoffDate = schedule.length > 0 && schedule[schedule.length - 1].balance <= 0
      ? schedule[schedule.length - 1].date
      : null

    return {
      schedule,
      totals: { totalPaid, totalPrincipal, totalInterest },
      payoffDate,
      warning
    }
  }

  updateSummary({ monthlyPayment, calculatedPayment, totals, payoffDate, baselineInterest }) {
    this.paymentSummaryTarget.textContent = this.currencyFormatter.format(monthlyPayment || 0)
    if (calculatedPayment) {
      this.paymentSummaryTarget.textContent = `${this.currencyFormatter.format(calculatedPayment)}`
    }

    this.totalPaidTarget.textContent = this.currencyFormatter.format(totals.totalPaid || 0)
    this.principalPaidTarget.textContent = this.currencyFormatter.format(totals.totalPrincipal || 0)
    this.interestPaidTarget.textContent = this.currencyFormatter.format(totals.totalInterest || 0)

    if (payoffDate) {
      this.payoffDateTarget.textContent = payoffDate.toLocaleDateString('en-US', { month: 'long', year: 'numeric' })
    } else {
      this.payoffDateTarget.textContent = "Not paid off within term"
    }

    const interestSaved = Math.max(0, (baselineInterest || 0) - (totals.totalInterest || 0))
    this.interestSavedTarget.textContent = this.currencyFormatter.format(interestSaved)

    const totalPaid = totals.totalPaid || 0
    const principalPct = totalPaid > 0 ? (totals.totalPrincipal / totalPaid) : 0
    const interestPct = totalPaid > 0 ? (totals.totalInterest / totalPaid) : 0

    this.principalBarTarget.style.width = `${(principalPct * 100).toFixed(1)}%`
    this.interestBarTarget.style.width = `${(interestPct * 100).toFixed(1)}%`
    this.principalPercentTarget.textContent = `Principal: ${(principalPct * 100).toFixed(1)}%`
    this.interestPercentTarget.textContent = `Interest: ${(interestPct * 100).toFixed(1)}%`
  }

  renderYearlyTable(schedule) {
    if (!schedule.length) {
      this.yearlyTableBodyTarget.innerHTML = "<tr><td colspan=\"5\" class=\"text-center text-muted\">Enter loan details to see the amortization table.</td></tr>"
      return
    }

    const yearly = {}
    schedule.forEach((row) => {
      const year = row.date.getFullYear()
      if (!yearly[year]) {
        yearly[year] = { totalPaid: 0, totalPrincipal: 0, totalInterest: 0, endingBalance: row.balance }
      }
      yearly[year].totalPaid += row.payment
      yearly[year].totalPrincipal += row.principal
      yearly[year].totalInterest += row.interest
      yearly[year].endingBalance = row.balance
    })

    const rows = Object.keys(yearly).sort((a, b) => Number(a) - Number(b)).map((year) => {
      const data = yearly[year]
      return `
        <tr>
          <td>${year}</td>
          <td>${this.currencyFormatter.format(data.totalPaid)}</td>
          <td>${this.currencyFormatter.format(data.totalPrincipal)}</td>
          <td>${this.currencyFormatter.format(data.totalInterest)}</td>
          <td>${this.currencyFormatter.format(Math.max(0, data.endingBalance))}</td>
        </tr>
      `
    }).join("")

    this.yearlyTableBodyTarget.innerHTML = rows
  }

  renderChart(schedule) {
    if (!schedule.length) {
      this.chartEmptyTarget.classList.remove("d-none")
      this.chartTarget.classList.add("d-none")
      if (this.chartInstance) {
        this.chartInstance.data.labels = []
        this.chartInstance.data.datasets.forEach((dataset) => { dataset.data = [] })
        this.chartInstance.update()
      }
      return
    }

    this.chartEmptyTarget.classList.add("d-none")
    this.chartTarget.classList.remove("d-none")

    const labels = schedule.map((row) => row.date.toLocaleDateString('en-US', { month: 'short', year: '2-digit' }))
    const balanceData = schedule.map((row) => Math.max(0, row.balance))
    const paymentData = schedule.map((row) => row.payment)
    const principalData = schedule.map((row) => row.principal)
    const interestData = schedule.map((row) => row.interest)

    const datasets = [
      { label: "Balance Left", data: balanceData, borderColor: "#0d6efd", backgroundColor: "rgba(13, 110, 253, 0.1)", tension: 0.1, borderWidth: 2, pointRadius: 0, yAxisID: "y" },
      { label: "Payment", data: paymentData, borderColor: "#198754", backgroundColor: "rgba(25, 135, 84, 0.1)", tension: 0.1, borderWidth: 2, pointRadius: 0, yAxisID: "y1" },
      { label: "Principal Paid", data: principalData, borderColor: "#0dcaf0", backgroundColor: "rgba(13, 202, 240, 0.1)", tension: 0.1, borderWidth: 2, pointRadius: 0, yAxisID: "y1" },
      { label: "Interest Paid", data: interestData, borderColor: "#ffc107", backgroundColor: "rgba(255, 193, 7, 0.1)", tension: 0.1, borderWidth: 2, pointRadius: 0, yAxisID: "y1" }
    ]

    if (!this.chartInstance) {
      const ctx = this.chartTarget.getContext("2d")
      this.chartInstance = new window.Chart(ctx, {
        type: "line",
        data: { labels, datasets },
        options: this.chartOptions()
      })
    } else {
      this.chartInstance.data.labels = labels
      this.chartInstance.data.datasets = datasets
      this.chartInstance.options = this.chartOptions()
      this.chartInstance.update()
    }
  }

  chartOptions() {
    const theme = document.documentElement.getAttribute('data-bs-theme')
    const textColor = theme === 'dark' ? '#adb5bd' : '#666666'
    const gridColor = theme === 'dark' ? 'rgba(255, 255, 255, 0.1)' : 'rgba(0, 0, 0, 0.1)'

    return {
      responsive: true,
      maintainAspectRatio: false,
      interaction: { mode: 'index', intersect: false },
      plugins: {
        legend: { display: true, position: 'bottom', labels: { color: textColor } },
        tooltip: {
          callbacks: {
            label: (context) => {
              let label = context.dataset.label || ''
              if (label) { label += ': ' }
              label += this.currencyFormatter.format(context.raw || 0)
              return label
            }
          }
        }
      },
      scales: {
        x: { ticks: { color: textColor }, grid: { color: gridColor } },
        y: { beginAtZero: true, ticks: { color: textColor }, grid: { color: gridColor } },
        y1: { beginAtZero: true, position: 'right', ticks: { color: textColor }, grid: { drawOnChartArea: false } }
      }
    }
  }

  updateChartTheme() {
    if (!this.chartInstance) return
    this.chartInstance.options = this.chartOptions()
    this.chartInstance.update()
  }

  calculatePayment(principal, monthlyRate, termMonths) {
    if (monthlyRate === 0) {
      return principal / termMonths
    }
    const rateFactor = Math.pow(1 + monthlyRate, termMonths)
    return principal * (monthlyRate * rateFactor) / (rateFactor - 1)
  }

  calculateTermMonths(principal, monthlyRate, monthlyPayment) {
    if (monthlyRate === 0) {
      return principal / monthlyPayment
    }
    if (monthlyPayment <= monthlyRate * principal) {
      return null
    }
    return Math.log(monthlyPayment / (monthlyPayment - (monthlyRate * principal))) / Math.log(1 + monthlyRate)
  }

  updatePaymentValue(value) {
    this.isUpdatingPayment = true
    this.paymentTarget.value = this.formatInputNumber(value)
    this.isUpdatingPayment = false
  }

  updateTermValue(termMonths) {
    this.isUpdatingTerm = true
    const years = Math.floor(termMonths / 12)
    const months = Math.max(0, termMonths - (years * 12))
    this.termYearsTarget.value = String(years)
    this.termMonthsTarget.value = String(this.normalizeMonths(months))
    this.isUpdatingTerm = false
  }

  normalizeMonths(value) {
    if (!Number.isFinite(value)) return 0
    return Math.min(11, Math.max(0, Math.round(value)))
  }

  frequencyToMonthlyFactor(frequency) {
    switch (frequency) {
      case "biweekly":
        return 26 / 12
      case "weekly":
        return 52 / 12
      default:
        return 1
    }
  }

  normalizeTermInputs() {
    if (this.isUpdatingTerm) return
    const years = this.parseNumber(this.termYearsTarget.value)
    if (Number.isFinite(years)) {
      this.termYearsTarget.value = String(Math.max(0, Math.round(years)))
    }
    const months = this.parseNumber(this.termMonthsTarget.value)
    if (Number.isFinite(months)) {
      let normalizedYears = Number.isFinite(years) ? Math.max(0, Math.round(years)) : 0
      const totalMonths = Math.max(0, Math.round(months))
      normalizedYears += Math.floor(totalMonths / 12)
      const remainingMonths = totalMonths % 12
      this.termYearsTarget.value = String(normalizedYears)
      this.termMonthsTarget.value = String(remainingMonths)
    }
  }

  parseNumber(value) {
    const normalized = value?.toString().replace(/,/g, "")
    const parsed = parseFloat(normalized)
    return Number.isFinite(parsed) ? parsed : 0
  }

  formatInputNumber(value) {
    const parsed = Number.isFinite(value) ? value : this.parseNumber(value)
    return this.inputNumberFormatter.format(parsed || 0)
  }

  parseDate(value) {
    if (!value) return null
    const parts = value.split("-").map((part) => parseInt(part, 10))
    if (parts.length < 3 || parts.some((part) => Number.isNaN(part))) {
      return null
    }
    const [year, month, day] = parts
    return new Date(year, month - 1, day)
  }

  parseMonthIndex(value) {
    if (!value) return null
    const [year, month] = value.split("-").map((part) => parseInt(part, 10))
    if (!year || !month) return null
    return (year * 12) + (month - 1)
  }

  addMonths(date, months) {
    const base = new Date(date.getTime())
    const day = base.getDate()
    base.setMonth(base.getMonth() + months)
    if (base.getDate() < day) {
      base.setDate(0)
    }
    return base
  }

  todayISO() {
    const today = new Date()
    const month = String(today.getMonth() + 1).padStart(2, "0")
    const day = String(today.getDate()).padStart(2, "0")
    return `${today.getFullYear()}-${month}-${day}`
  }

  showWarning(message) {
    this.warningTarget.textContent = message
    this.warningTarget.classList.remove("d-none")
  }

  clearWarning() {
    this.warningTarget.textContent = ""
    this.warningTarget.classList.add("d-none")
  }

  resetOutputs() {
    this.paymentSummaryTarget.textContent = this.currencyFormatter.format(0)
    this.totalPaidTarget.textContent = this.currencyFormatter.format(0)
    this.principalPaidTarget.textContent = this.currencyFormatter.format(0)
    this.interestPaidTarget.textContent = this.currencyFormatter.format(0)
    this.payoffDateTarget.textContent = "-"
    this.interestSavedTarget.textContent = this.currencyFormatter.format(0)
    this.principalBarTarget.style.width = "0%"
    this.interestBarTarget.style.width = "0%"
    this.principalPercentTarget.textContent = "Principal: 0%"
    this.interestPercentTarget.textContent = "Interest: 0%"
    this.yearlyTableBodyTarget.innerHTML = "<tr><td colspan=\"5\" class=\"text-center text-muted\">Enter loan details to see the amortization table.</td></tr>"
    this.renderChart([])
  }
}
