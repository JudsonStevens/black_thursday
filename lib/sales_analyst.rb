# frozen_string_literal: true

require_relative 'math_helper.rb'
require_relative 'analysis_helper.rb'
require 'time'
# Sales analyst class to perform analysis.
class SalesAnalyst
  include MathHelper
  include AnalysisHelper
  attr_reader :sales_engine
  def initialize(sales_engine)
    @sales_engine = sales_engine
  end

  def average_items_per_merchant
    (@sales_engine.items.all.length / @sales_engine.merchants.all.length).round(2)
  end

  def average_items_per_merchant_standard_deviation
    standard_deviation(all_items, average_items_per_merchant)
  end

  def standard_deviation_of_item_price
    list_of_prices = @sales_engine.items.all.map(&:unit_price)
    standard_deviation(list_of_prices, average_average_price_per_merchant)
  end

  def golden_items
    std_dev = standard_deviation_of_item_price
    average = average_average_price_per_merchant
    price_of_item = average + (2 * std_dev)
    price_range = price_of_item.to_i..find_max_price
    @sales_engine.items.find_all_by_price_in_range(price_range)
  end

  def merchants_with_high_item_count
    std_dev = average_items_per_merchant_standard_deviation
    average = average_items_per_merchant
    amount_of_items = average + std_dev
    @sales_engine.merchants.all.map do |merchant|
      amount = @sales_engine.merchants.find_by_id(merchant.id).items.length
      merchant if amount > amount_of_items
    end.compact
  end

  def average_average_price_per_merchant
    average_prices = average_prices_over_all_merchants
    (average_prices.inject(:+) / @sales_engine.merchants.all.length).round(2)
  end

  def average_prices_over_all_merchants
    @sales_engine.merchants.all.map do |merchant|
      average_item_price_for_merchant(merchant.id)
    end
  end

  def find_max_price
    @sales_engine.items.unit_price.keys.max.to_i
  end

  def average_invoices_per_merchant
    all_invoices = @sales_engine.invoices.all.length
    (all_invoices.inject(:+).to_f / @sales_engine.merchants.all.length).round(2)
  end

  def average_invoices_per_merchant_standard_deviation
    average_num_of_invoices = average_invoices_per_merchant
    list_of_invoices = @sales_engine.invoices.all.length
    standard_deviation(list_of_invoices, average_num_of_invoices)
  end

  def top_merchants_by_invoice_count
    std_dev = average_invoices_per_merchant_standard_deviation
    average = average_invoices_per_merchant
    bottom_of_range = (std_dev * 2) + average
    @sales_engine.merchants.all.map do |merchant|
      amount = @sales_engine.merchants.find_by_id(merchant.id).invoices.length
      merchant if amount > bottom_of_range
    end.compact
  end

  def bottom_merchants_by_invoice_count
    std_dev = average_invoices_per_merchant_standard_deviation
    average = average_invoices_per_merchant
    bottom_of_range = average - (std_dev * 2)
    @sales_engine.merchants.all.map do |merchant|
      amount = @sales_engine.merchants.find_by_id(merchant.id).invoices.length
      merchant if amount < bottom_of_range
    end.compact
  end

  def day_count_hash
    days = @sales_engine.invoices.all.map { |invoice| invoice.created_at.wday }
    group = days.group_by { |day| day }
    group.each { |key, value| group[key] = value.length }
  end

  def find_top_days
    average = day_count_hash.values.inject(:+) / 7
    std_dev = standard_deviation_of_invoices_by_weekday
    amount = std_dev + average
    day_count_hash.select do |_, value|
      value > amount
    end
  end

  def top_days_by_invoice_count
    find_top_days.keys.map { |day| Date::DAYNAMES[day] }
  end

  def standard_deviation_of_invoices_by_weekday
    average = day_count_hash.values.inject(:+) / 7
    total_invoices_by_day = day_count_hash.values
    squared_num_invoice = total_invoices_by_day.map { |day| (day - average)**2 }
    value = squared_num_invoice.inject(:+) / (total_invoices_by_day.length - 1)
    Math.sqrt(value)
  end

  def invoice_status(status_symbol)
    status_hash = find_status_hash
    value = status_hash.select { |key, _| key == status_symbol }.values
    ((value[0].to_f / status_hash.values.inject(:+)) * 100).round(2)
  end

  def find_status_hash
    all_status = @sales_engine.invoices.all.map(&:status)
    group = all_status.group_by { |status| status }
    group.each { |key, value| group[key] = value.length }
  end

  def one_time_buyers
    @sales_engine.customers.all.map do |customer|
      customer if customer.fully_paid_invoices.length == 1
    end.compact
  end

  def one_time_buyers_top_items
    items = one_time_buyers.map { |customer| highest_volume_items(customer.id) }
    items.flatten.group_by(&:id).max_by { |_, v| v.length }[1].uniq
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

  def highest_volume_items(customer_id)
    high_volume = invoices_with_item_amounts(customer_id).group_by(&:last).max
    calculate_high_volume_items(high_volume)
  end

  def invoices_with_item_amounts(customer_id)
    invoices_by_customer_id(customer_id).map do |invoice|
      invoice.invoice_items.map do |invoice_item|
        [invoice_item.item_id, invoice_item.quantity]
      end
    end.compact.flatten(1)
  end

  def calculate_high_volume_items(high_volume_array)
    high_volume_array.flatten(1).drop(1).map do |item_array|
      @sales_engine.items.find_by_id(item_array[0])
    end
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


# Justine start work on iteration 4

  def transactions_by_date(date)
    date1 = date.to_date
    transactions = @sales_engine.transactions.all
    dated = transactions.find_all do |transaction|
      transaction.created_at.to_date == date1
    end
  end

  def successful_transactions
    @sales_engine.transactions.all.find_all do |transaction|
      transaction.result == 'success'
    end
  end

  def successful_invoices_by_date(date)
    dated = transactions_by_date(date)
    matches = dated & successful_transactions
  end

  def ids_of_successful_invoices_by_date(matches)
    matches.map do |transaction|
      transaction.invoice_id
    end.uniq
  end

  def successful_dated_invoice_ids(ids)
    ids.map { |id| @sales_engine.invoice_items.find_all_by_invoice_id(id) }
  end

  def quantity_by_unit_price(invoice_items)
    result = invoice_items.map do |invoice_item|
      quantity = invoice_item.quantity.to_s
      unit_price = invoice_item.unit_price.to_s
      quantity.to_f * unit_price.to_f
    end
    result.reduce(:+)
  end

  def total_revenue_by_date(date)
    invoices = successful_invoices_by_date(date)
    ids = ids_of_successful_invoices_by_date(invoices).uniq
    invoice_items = successful_dated_invoice_ids(ids).flatten
    quantity_by_unit_price(invoice_items)
  end
#Justine end work on iteration 4
end
