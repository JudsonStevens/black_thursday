# frozen_string_literal: true

# Module to provide common methods to clean up SalesAnalyst.
module AnalysisHelper
  def total_number_of_items
    @sales_engine.items.all.length
  end

  def list_of_prices
    @sales_engine.items.all.map(&:unit_price)
  end

  def std_dev_and_average(average, std_dev)
    average + std_dev
  end

  def two_std_dev_and_average(average, std_dev)
    average + (std_dev * 2)
  end

  def all_items
    @sales_engine.merchants.all.map do |merchant|
      @sales_engine.merchants.find_by_id(merchant.id).items.length
    end
  end

  def all_invoices
    @sales_engine.merchants.all.map do |merchant|
      @sales_engine.merchants.find_by_id(merchant.id).invoices.length
    end
  end

  def find_max_price
    @sales_engine.items.unit_price.keys.max.to_i
  end

  def average_prices_over_all_merchants
    @sales_engine.merchants.all.map do |merchant|
      average_item_price_for_merchant(merchant.id)
    end
  end

  def average_items_per_merchant
    (total_number_of_items / @sales_engine.merchants.all.length.to_f).round(2)
  end
end
