# frozen_string_literal: true

# This module provides merchant analytics.
module MerchantAnalytics
  def best_item_for_merchant(merchant_id)
    item_id_and_revenue = return_invoices_with_total_revenue(merchant_id)
    item_id = item_id_and_revenue.flatten(1).max_by(&:last)[0]
    @sales_engine.items.find_by_id(item_id)
  end

  def return_invoices_with_total_revenue(merchant_id)
    @sales_engine.invoices.merchant_id[merchant_id].map do |invoice|
      if invoice.is_paid_in_full?
        return_all_items_and_revenue_by_invoice_id(invoice.id)
      end
    end.compact
  end

  def return_all_items_and_revenue_by_invoice_id(invoice_id)
    @sales_engine.invoice_items.invoice_id[invoice_id].map do |invoice_item|
      [invoice_item.item_id, invoice_item.possible_revenue]
    end.compact
  end

  def most_sold_item_for_merchant(merchant_id)
    item_hash = return_item_hash_with_ids_and_quantities(merchant_id)
    item_ids = []
    item_hash.each do |key, value|
      item_ids << key if value == item_hash.values.max
    end
    item_ids.map { |item_id| @sales_engine.items.find_by_id(item_id) }
  end

  def return_item_hash_with_ids_and_quantities(merchant_id)
    item_id_and_quantity = return_invoices_with_total_quantity(merchant_id)
    item_hash = {}
    item_id_and_quantity.flatten(1).each do |element|
      if item_hash[element[0]]
        item_hash[element[0]] << element[1]
      else
        item_hash[element[0]] = [] << element[1]
      end
    end
    item_hash
  end

  def return_invoices_with_total_quantity(merchant_id)
    @sales_engine.invoices.merchant_id[merchant_id].map do |invoice|
      if invoice.is_paid_in_full?
        return_all_items_and_quantity_by_invoice_id(invoice.id)
      end
    end.compact
  end

  def return_all_items_and_quantity_by_invoice_id(invoice_id)
    @sales_engine.invoice_items.invoice_id[invoice_id].map do |invoice_item|
      [invoice_item.item_id, invoice_item.quantity]
    end.compact
  end

  def revenue_by_merchant(merchant_id)
    invoice_array = return_invoices_with_total_revenue(merchant_id)
    invoice_array.flatten(1).map { |element| element[1] }.inject(:+)
  end
end
