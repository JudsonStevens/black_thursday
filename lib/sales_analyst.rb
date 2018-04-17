# frozen_string_literal: true

require 'time'
require 'date'
require 'pry'
require 'sales_engine'
# Sales analyst class to perform analysis.
class SalesAnalyst
  attr_reader :sales_engine
  def initialize(sales_engine)
    @sales_engine = sales_engine
  end

  def average_items_per_merchant
    all_items = list_of_number_of_items_per_merchant
    (all_items.inject(:+).to_f / @sales_engine.merchants.all.length).round(2)
  end

  def average_items_per_merchant_standard_deviation
    all_items = list_of_number_of_items_per_merchant
    average_items = average_items_per_merchant
    squared_num_items = all_items.map do |num_of_items|
      (num_of_items - average_items)**2
    end
    math = squared_num_items.inject(:+) / (all_items.length - 1)
    Math.sqrt(math).round(2)
  end

  def list_of_number_of_items_per_merchant
    @sales_engine.merchants.all.map do |merchant|
      @sales_engine.merchants.find_by_id(merchant.id).items.length
    end
  end

  def standard_deviation_of_item_price
    average_price = average_average_price_per_merchant
    list_of_prices = @sales_engine.items.all.map(&:unit_price)
    squared_num_items = list_of_prices.map do |price|
      (price.to_f - average_price.to_f)**2
    end
    Math.sqrt(squared_num_items.inject(:+) / (list_of_prices.length - 1))
  end

  def golden_items
    std_dev = standard_deviation_of_item_price
    average = average_average_price_per_merchant
    price_of_item = average + (2 * std_dev)
    price_range = price_of_item.to_i..find_max_price
    @sales_engine.items.find_all_by_price_in_range(price_range)
  end

  def average_item_price_for_merchant(merchant_id)
    merchant = @sales_engine.merchants.find_by_id(merchant_id)
    all_items = merchant.items.map(&:unit_price)
    (all_items.inject(:+) / all_items.length).round(2)
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
    @sales_engine.items.all.map(&:unit_price).max.to_i
  end

  def average_invoices_per_merchant
    all_invoices = total_number_of_invoices_for_all_merchants
    (all_invoices.inject(:+).to_f / @sales_engine.merchants.all.length).round(2)
  end

  def total_number_of_invoices_for_all_merchants
    @sales_engine.merchants.all.map do |merchant|
      @sales_engine.merchants.find_by_id(merchant.id).invoices.length
    end
  end

  def average_invoices_per_merchant_standard_deviation
    average_num_of_invoices = average_invoices_per_merchant
    list_of_invoices = total_number_of_invoices_for_all_merchants
    squared_num_items = list_of_invoices.map do |invoices|
      (invoices.to_f - average_num_of_invoices.to_f)**2
    end
    calculation = squared_num_items.inject(:+) / (list_of_invoices.length - 1)
    Math.sqrt(calculation).round(2)
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
    all_customer_ids = @sales_engine.invoices.all.map(&:customer_id)
    group = all_customer_ids.group_by { |customer_id| customer_id }
    single_invoice_customer_ids = group.keep_if { |_, value| value.length == 1 }
    single_invoice_customer_ids.keys.map do |id|
      @sales_engine.customers.find_by_id(id)
    end
  end

  def one_time_buyers_item
  end

  def invoice_total(invoice_id)
    all_items = @sales_engine.invoice_items.find_all_by_invoice_id(invoice_id)
    all_items.map(&:unit_price).inject(:+)
  end

  def invoice_paid_in_full?(invoice_id)
    invoice = @sales_engine.invoices.find_by_id(invoice_id)
    transactions1 = invoice.transactions
    transactions1.any? { |transaction| transaction.result == 'success' }
  end
# Justine start work on iteration 4

  def transactions_by_date(date)
    transactions = @sales_engine.transactions.all
    transactions.find_all do |transaction|
      transaction.created_at.to_date == date.to_date
    end
  end

  def successful_transactions
    @sales_engine.transactions.all.find_all do |transaction|
      transaction.result == 'success'
    end
  end

  def successful_invoices_by_date(date)
    dated = transactions_by_date(date)
    dated & successful_transactions
  end

  def ids_of_successful_invoices_by_date(matches)
    matches.map do |transaction|
      transaction.invoice_id
    end.uniq
  end

  def successful_dated_invoice_ids(ids)
    ids.map { |id| @sales_engine.invoice_items.find_all_by_invoice_id(id) }
  end

  def quantity_by_unit_price_math(invoice_item)
    quantity = invoice_item.quantity.to_s
    unit_price = invoice_item.unit_price.to_s
    quantity.to_f * unit_price.to_f
  end

  def quantity_by_unit_price(invoice_items)
    invoice_items.map do |invoice_item|
      quantity_by_unit_price_math(invoice_item)
    end
  end

  def add_totals(results)
    results.reduce(:+)
  end

  def total_revenue_by_date(date)
    invoices = successful_invoices_by_date(date)
    ids = ids_of_successful_invoices_by_date(invoices).uniq
    invoice_items = successful_dated_invoice_ids(ids).flatten
    results = quantity_by_unit_price(invoice_items)
    add_totals(results).round(2)
  end

  def invoices_by_transactions(transactions)
    transactions.map do |transaction|
      id = transaction.invoice_id
      @sales_engine.invoices.find_by_id(id)
    end.compact
  end

  def invoice_items_by_invoices(invoices)
    invoices.map do |invoice|
      invoice_id = invoice.id
      @sales_engine.invoice_items.find_all_by_invoice_id(invoice_id)
    end.flatten
  end

  def invoice_items_total(invoice_items)
    invoice_items.map do |invoice_item|
      total_amount = quantity_by_unit_price_math(invoice_item)
      invoice_item.invoice_items_specs.store(:total, total_amount)
      invoice_item
    end
  end

  def add_invoice_totals(totaled_items)
    ids = totaled_items.group_by do |invoice_item|
      invoice_item.invoice_id
    end
     totals_by_invoice(ids)
  end

  def totals_by_invoice(merchant_ids)
    merchant_totals = {}
    merchant_ids.each do |key, value|
      totals = value.map { |item| item.invoice_items_specs[:total] }
      value = add_totals(totals)
      merchant_totals[key] = value
    end
    merchant_totals
  end

  def merchants_high_to_low(merchant_totals, number)
    sorted = merchant_totals.sort_by { |key, value| value }.reverse.to_h
    top_earners = sorted.first(number).to_h
    top_earners.map do |key, value|
      @sales_engine.merchants.find_by_id(key)
    end
  end

  def top_revenue_earners(number_of_earners = 20)
    invoices = invoices_by_transactions(successful_transactions)
    invoice_items = invoice_items_by_invoices(invoices)
    totaled_invoice_items = invoice_items_total(invoice_items)
    merchant_totals = add_invoice_totals(totaled_invoice_items)
    merchants_high_to_low(merchant_totals, number_of_earners)
  end
#Justine end work on iteration 4
end
