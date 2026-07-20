import Sortable from "@stimulus-components/sortable"

export default class extends Sortable {
  onUpdate({ item, newIndex }) {
    const form = item.querySelector("[data-admin--photo-reorder-form]")
    form.elements.namedItem("photo[position]").value = newIndex + 1
    form.requestSubmit()
  }
}
