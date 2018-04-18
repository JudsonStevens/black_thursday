# frozen_string_literal: true

require 'simplecov'
SimpleCov.start
require 'bigdecimal'
require 'minitest'
require 'minitest/emoji'
require 'minitest/autorun'
require './lib/sales_engine.rb'
require './lib/sales_analyst.rb'
require 'pry'

class SalesAnalystTest < MiniTest::Test
  def setup
    @se = SalesEngine.from_csv(
      items:      './data/items.csv',
      merchants:  './data/merchants.csv',
      invoices:   './data/invoices.csv',
      customers:  './data/customers.csv',
      transactions: './data/transactions.csv',
      invoice_items: './data/invoice_items.csv'
    )
    @s = SalesAnalyst.new(@se)
  end

  def test_it_exists
    assert_instance_of SalesAnalyst, @s
  end

  def test_it_gives_average_items_per_merchant
    expected = 2.88
    actual = BigDecimal(@s.average_items_per_merchant, 3)

    assert_equal expected, actual
  end

  def test_it_can_calculate_standard_deviation
    expected = 3.26
    actual = BigDecimal(@s.average_items_per_merchant_standard_deviation, 3)

    assert_equal expected, actual
  end

  def test_it_can_return_the_list_of_average_item_prices
    expected = 6.0
    actual = @s.average_prices_over_all_merchants[14].to_f

    assert_equal expected, actual
  end

  def test_it_can_calculate_merchants_with_high_item_counts
    expected = 'Keckenbauer'
    actual = @s.merchants_with_high_item_count.first.name
    assert_equal expected, actual
  end

  def test_it_finds_max_price
    expected = 99999

    actual = @s.find_max_price

    assert_equal expected, actual
  end

  def test_it_returns_correct_standard_deviation_for_price
    expected = 2901.63
    actual = @s.standard_deviation_of_item_price.round(2)

    assert_equal expected, actual
  end

  def test_it_can_return_average_invoices_per_merchant
    expected = 10.49
    actual = @s.average_invoices_per_merchant

    assert_equal expected, actual
  end

  def test_it_can_return_average_invoices_per_merchant_standard_deviation
    expected = 3.29
    actual = @s.average_invoices_per_merchant_standard_deviation

    assert_equal expected, actual
  end

  def test_it_can_find_the_golden_items
    expected = 5
    actual = @s.golden_items.length

    assert_equal expected, actual
  end

  def test_it_can_find_one_time_buyers
    expected = 76
    actual = @s.one_time_buyers.length

    assert_equal expected, actual
  end

  def test_it_can_return_paid_in_full_invoice
    expected = true
    actual = @s.invoice_paid_in_full?(16)

    assert_equal expected, actual
  end

  def test_it_can_find_the_invoice_total
    expected = 21067.77
    actual = @s.invoice_total(1).to_f.round(2)

    assert_equal expected, actual
  end

  def test_it_can_return_top_merchant_by_invoice_count
    expected = 12334141
    actual = @s.top_merchants_by_invoice_count.first.id

    assert_equal expected, actual
  end

  def test_it_can_return_bottom_merchants_by_invoice_count
    expected = 12334235
    actual = @s.bottom_merchants_by_invoice_count.first.id

    assert_equal expected, actual
  end

  def test_it_can_find_top_days_by_invoice_count
    expected = 'Wednesday'
    actual = @s.top_days_by_invoice_count.first

    assert_equal expected, actual
  end

  def test_it_can_find_top_days_hash_by_invoie_count
    expected = { 3 => 741 }
    actual = @s.find_top_days

    assert_equal expected, actual
  end

  def test_it_can_return_a_hash_of_invoice_count_by_day
    expected = [6, 729]
    actual = @s.day_count_hash.first

    assert_equal expected, actual
  end

  def test_it_can_return_the_standard_deviation_of_invoices_by_weekday
    expected = 16.73
    actual = @s.standard_deviation_of_invoices_by_weekday

    assert_equal expected, actual
  end

  def test_it_can_return_invoice_status
    expected = 13.5
    actual = @s.invoice_status(:returned)

    assert_equal expected, actual
  end

  def test_it_can_return_one_time_buyers
    expected = 27
    actual = @s.one_time_buyers.first.id

    assert_equal expected, actual
  end

  def test_it_can_return_one_time_buyers_top_item
    expected = 263505548
    actual = @s.one_time_buyers_top_item.id

    assert_equal expected, actual
  end

  def test_it_returns_top_twenty_buyers
    expected = 20
    actual = @s.top_buyers.length

    assert_equal expected, actual
  end

  def test_it_returns_top_spenders
    expected = 1
    actual = @s.top_spenders.first[0].id

    assert_equal expected, actual
  end

  def test_it_returns_top_merchants_by_customer_id
    expected = 12335319
    actual = @s.top_merchant_for_customer(15).id

    assert_equal expected, actual
  end

  def test_invoices_can_return_successful_transactions
    expected = true
    invoice = @se.invoices.find_by_id(1)
    actual = invoice.is_paid_in_full?

    assert_equal expected, actual
  end

  def test_it_can_return_total_revenue_by_merchant
    expected = 123696.45
    actual = @s.revenue_by_merchant(12334141).to_f

    assert_equal expected, actual
  end

  def test_it_can_find_best_item_for_merchant
    expected = 263553486
    actual = @s.best_item_for_merchant(12334141).id

    assert_equal expected, actual
  end

  def test_it_returns_most_sold_item_for_merchant
    expected = @s.most_sold_item_for_merchant(12334112)

    assert_instance_of Array, expected
    assert_instance_of Item, expected[0]
    assert_equal 1, expected.length
  end

  def test_it_returns_item_hash_with_ids_and_quantities
    expected = @s.return_item_hash_with_ids_and_quantities(12334112)

    assert_instance_of Hash, expected
    assert_equal 20, expected.length
    assert_equal 263425975, expected.keys[0]
  end

  def test_it_returns_revenue_by_merchant
    expected = @s.revenue_by_merchant(12334112)

    assert_equal 0.6729583e5, expected
  end
end
