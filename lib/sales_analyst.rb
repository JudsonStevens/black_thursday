# frozen_string_literal: true

require_relative 'math_helper.rb'
require_relative 'analysis_helper.rb'
require_relative 'customer_analytics.rb'
require_relative 'sales_engine.rb'
require 'time'
require 'date'

# Sales analyst class to perform analysis.
class SalesAnalyst
  include CustomerAnalytics
  include MathHelper
  include AnalysisHelper
  attr_reader :sales_engine
  def initialize(sales_engine)
    @sales_engine = sales_engine
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
    price_range = (average + (2 * std_dev)).to_i..find_max_price
    @sales_engine.items.find_all_by_price_in_range(price_range)
  end

  def merchants_with_high_item_count
    std_dev = average_items_per_merchant_standard_deviation
    average = average_items_per_merchant
    @sales_engine.merchants.all.map do |merchant|
      amount = @sales_engine.merchants.find_by_id(merchant.id).items.length
      merchant if amount > (average + std_dev)
    end.compact
  end

  def average_average_price_per_merchant
    average_prices = average_prices_over_all_merchants
    (average_prices.inject(:+) / @sales_engine.merchants.all.length).round(2)
  end

  def average_invoices_per_merchant
    (all_invoices.inject(:+).to_f / @sales_engine.merchants.all.length).round(2)
  end

  def average_invoices_per_merchant_standard_deviation
    standard_deviation(all_invoices, average_invoices_per_merchant)
  end

  def top_merchants_by_invoice_count
    std_dev = average_invoices_per_merchant_standard_deviation
    average = average_invoices_per_merchant
    @sales_engine.merchants.all.map do |merchant|
      amount = @sales_engine.merchants.find_by_id(merchant.id).invoices.length
      merchant if amount > ((std_dev * 2) + average)
    end.compact
  end

  def bottom_merchants_by_invoice_count
    std_dev = average_invoices_per_merchant_standard_deviation
    average = average_invoices_per_merchant
    @sales_engine.merchants.all.map do |merchant|
      amount = @sales_engine.merchants.find_by_id(merchant.id).invoices.length
      merchant if amount < (average - (std_dev * 2))
    end.compact
  end

  def top_days_by_invoice_count
    find_top_days.keys.map { |day| Date::DAYNAMES[day] }
  end

  def find_top_days
    average = day_count_hash.values.inject(:+) / 7
    std_dev = standard_deviation_of_invoices_by_weekday
    day_count_hash.select do |_, value|
      value > (std_dev + average).round(0)
    end
  end

  def day_count_hash
    days = @sales_engine.invoices.all.map { |invoice| invoice.created_at.wday }
    group = days.group_by { |day| day }
    group.each { |key, value| group[key] = value.length }
  end

  def standard_deviation_of_invoices_by_weekday
    average = day_count_hash.values.inject(:+) / 7
    total_invoices_by_day = day_count_hash.values
    standard_deviation(total_invoices_by_day, average)
  end

  def invoice_status(status_symbol)
    amount = @sales_engine.invoices.status[status_symbol].length
    total = @sales_engine.invoices.status.values.flatten.length
    ((amount.to_f / total) * 100).round(2)
  end

  def invoice_total(invoice_id)
    items = @sales_engine.invoice_items.find_all_by_invoice_id(invoice_id)
    items.map(&:possible_revenue).inject(:+)
  end

  def invoice_paid_in_full?(invoice_id)
    invoice = @sales_engine.invoices.find_by_id(invoice_id)
    transactions = invoice.transactions
    transactions.any? { |transaction| transaction.result == :success }
  end

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
    matches.map(&:invoice_id).uniq
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
    ids = totaled_items.group_by(&:invoice_id)
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
    sorted = merchant_totals.sort_by { |_, value| value }.reverse.to_h
    top_earners = sorted.first(number).to_h
    top_earners.map do |key, _|
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

  def best_item_for_merchant(merchant_id)
    item_id_and_revenue = return_invoices_with_totals(merchant_id)
    item_id = item_id_and_revenue.flatten(1).max_by(&:last)[0]
    @sales_engine.items.find_by_id(item_id)
  end

  def return_invoices_with_totals(merchant_id)
    @sales_engine.invoices.merchant_id[merchant_id].map do |invoice|
      return_all_items_by_invoice_id(invoice.id) if invoice.is_paid_in_full?
    end.compact
  end

  def return_all_items_by_invoice_id(invoice_id)
    @sales_engine.invoice_items.invoice_id[invoice_id].map do |invoice_item|
      [invoice_item.item_id, invoice_item.possible_revenue]
    end.compact
  end
end
