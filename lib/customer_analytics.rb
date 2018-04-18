# frozen_string_literal: true

# This module provides customer analytics.
module CustomerAnalytics
  def one_time_buyers
    @sales_engine.customers.all.map do |customer|
      customer if customer.fully_paid_invoices.length == 1
    end.compact
  end

  def top_buyers(num_of_customers = 20)
    sorted_customers = top_spenders.sort_by { |_, value| value || 0 }.reverse
    customer_array = []
    sorted_customers.each { |customer| customer_array << customer[0] }
    customer_array.take(num_of_customers)
  end

  def top_spenders
    @sales_engine.customers.all.map do |customer|
      totals = invoices_by_customer_id(customer.id).map do |invoice|
        invoice.total if invoice_paid_in_full?(invoice.id)
      end
      [customer, totals.compact.inject(:+)]
    end
  end

  def invoices_by_customer_id(customer_id)
    @sales_engine.invoices.find_all_by_customer_id(customer_id)
  end

  def top_merchant_for_customer(customer_id)
    inv_totals = calculate_invoice_totals(customer_id).sort_by(&:last).reverse
    top_invoice_id = inv_totals.first.first
    merchant_id = @sales_engine.invoices.find_by_id(top_invoice_id).merchant_id
    @sales_engine.merchants.find_by_id(merchant_id)
  end

  def calculate_invoice_totals(customer_id)
    invoices_by_customer_id(customer_id).map do |invoice|
      storage = []
      @sales_engine.invoice_items.group_by_number_of_items.each do |element|
        storage << element [1] if element[0] == invoice.id
      end
      [invoice.id, storage.inject(:+)]
    end
  end

  def invoice_paid_in_full?(invoice_id)
    invoice = @sales_engine.invoices.find_by_id(invoice_id)
    invoice.is_paid_in_full?
  end

  def best_invoice_by_quantity
    invoices = @sales_engine.invoices.all.map do |invoice|
      [invoice, invoice.amount_of_items] if invoice.is_paid_in_full?
    end.compact
    invoices.sort_by { |_, value| value || 0 }.reverse[1].first
  end

  def customers_with_unpaid_invoices
    @sales_engine.customers.all.map do |customer|
      invoices_by_customer_id(customer.id).map do |invoice|
        customer unless invoice.is_paid_in_full?
      end.compact.uniq
    end.flatten
  end

  def best_invoice_by_revenue
    invoices = @sales_engine.invoices.all.map do |invoice|
      [invoice, invoice.total] if invoice.is_paid_in_full?
    end.compact
    invoices.sort_by { |_, value| value || 0 }.reverse.flatten.first
  end

  def one_time_buyers_top_item
    @sales_engine.items.find_by_id(list_of_one_time_buyers_items[0])
  end

  def list_of_one_time_buyers_items
    items = one_time_buyers.map do |customer|
      return_high_volume_items(customer.id)
    end
    item_hash = return_item_ids_with_quantity(items)
    item_hash.max_by { |_, v| v.inject(:+) }
  end

  def return_item_ids_with_quantity(items)
    new_hash = {}
    items.flatten(1).each do |element|
      if new_hash[element[0]]
        new_hash[element[0]] << element[1]
      else
        new_hash[element[0]] = [] << element[1]
      end
    end
    new_hash
  end

  def return_high_volume_items(customer_id)
    invoices_with_item_amounts(customer_id)
  end

  def highest_volume_items(customer_id)
    high_volume = invoices_with_item_amounts(customer_id).group_by(&:last).max
    calculate_high_volume_items(high_volume)
  end

  def calculate_high_volume_items(high_volume_array)
    high_volume_array.flatten(1).drop(1).map do |item_array|
      @sales_engine.items.find_by_id(item_array[0])
    end
  end

  def invoices_with_item_amounts(customer_id)
    invoices_by_customer_id(customer_id).map do |invoice|
      invoice.invoice_items.map do |invoice_item|
        [invoice_item.item_id, invoice_item.quantity]
      end
    end.compact.flatten(1)
  end

  def items_bought_in_year(customer_id, year)
    item_ids = find_items_sold_by_year(customer_id, year)
    item_ids.map { |item_id| @sales_engine.items.find_by_id(item_id) }
  end

  def find_items_sold_by_year(customer_id, year)
    invoices_by_customer_id(customer_id).map do |invoice|
      if invoice.created_at.strftime('%Y') == year.to_s
        invoice.invoice_items.map(&:item_id)
      end
    end.flatten.compact
  end
end
