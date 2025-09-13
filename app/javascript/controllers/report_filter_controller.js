import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dateInput", "submit"]
  static values = { lastDate: String }

  connect() {
    // All'avvio, aggiorna il campo data in base al tipo selezionato (utile su caricamento diretto di new)
    const typeSelect = this.element.querySelector("#report_type")
    if (typeSelect) {
      this.updateDateInput({ target: typeSelect })
    }
  }

  updateDateInput(event) {
    const type = event.target.value
    let html = ""

    if (type === "daily") {
      const defaultDate = this.lastDateValue || this.yesterday()
      html = `
        <label for="date" class="block text-xs font-semibold">Giorno</label>
        <input type="date" name="date" id="date"
          value="${defaultDate}"
          class="border rounded px-2 py-1" />
      `
    } else if (type === "weekly") {
      const week = this.currentWeek()
      html = `
        <label for="week" class="block text-xs font-semibold">Settimana</label>
        <input type="week" name="week" id="week"
          value="${week}"
          class="border rounded px-2 py-1" />
      `
    } else if (type === "monthly") {
      const month = this.currentMonth()
      html = `
        <label for="month" class="block text-xs font-semibold">Mese</label>
        <input type="month" name="month" id="month"
          value="${month}"
          class="border rounded px-2 py-1" />
      `
    }
    this.dateInputTarget.innerHTML = html
  }

  // AGGIUNGI QUESTO METODO
  submit(event) {
    if (this.hasSubmitTarget) {
      this.submitTarget.value = "In elaborazione..."
      this.submitTarget.disabled = true
    }
  }

  yesterday() {
    const yesterday = new Date()
    yesterday.setDate(yesterday.getDate() - 1)
    return yesterday.toISOString().split('T')[0]
  }

  currentWeek() {
    const d = new Date()
    const year = d.getFullYear()
    const week = this.getWeekNumber(d)
    return `${year}-W${week.toString().padStart(2, '0')}`
  }

  currentMonth() {
    const d = new Date()
    return d.toISOString().slice(0, 7)
  }

  getWeekNumber(d) {
    d = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()))
    d.setUTCDate(d.getUTCDate() + 4 - (d.getUTCDay()||7))
    const yearStart = new Date(Date.UTC(d.getUTCFullYear(),0,1))
    const weekNo = Math.ceil((((d - yearStart) / 86400000) + 1)/7)
    return weekNo
  }
}