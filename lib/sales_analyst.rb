# frozen_string_literal: true

require_relative 'math_helper.rb'
require_relative 'analysis_helper.rb'
require_relative 'customer_analytics.rb'
require 'time'
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

  def average_invoices_per_merchant
    (all_invoices.inject(:+).to_f / @sales_engine.merchants.all.length).round(2)
  end

  def average_invoices_per_merchant_standard_deviation
    standard_deviation(all_invoices, average_invoices_per_merchant)
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

  def top_days_by_invoice_count
    find_top_days.keys.map { |day| Date::DAYNAMES[day] }
  end

  def find_top_days
    average = day_count_hash.values.inject(:+) / 7
    std_dev = standard_deviation_of_invoices_by_weekday
    amount = std_dev + average
    day_count_hash.select do |_, value|
      value > amount.round(0)
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
    status_hash = find_status_hash
    value = status_hash.select { |key, _| key == status_symbol }.values
    ((value[0].to_f / status_hash.values.inject(:+)) * 100).round(2)
  end

  def find_status_hash
    all_status = @sales_engine.invoices.all.map(&:status)
    group = all_status.group_by { |status| status }
    group.each { |key, value| group[key] = value.length }
  end

  def invoice_total(invoice_id)
    items = @sales_engine.invoice_items.find_all_by_invoice_id(invoice_id)
    items.map(&:possible_revenue).inject(:+)
  end
end
