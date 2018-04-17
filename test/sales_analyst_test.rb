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
      invoices:   './fixtures/invoices_test.csv',
      customers:  './data/customers.csv',
      transactions: './fixtures/transactions_test.csv',
      invoice_items: './fixtures/invoice_items_test.csv'
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

  # Need to create mocks for testing
  def test_it_can_calculate_merchants_with_high_item_counts
    actual = @s.merchants_with_high_item_count.first.name
    expected = 'Keckenbauer'
    assert_equal expected, actual
  end

  def test_it_finds_max_price
    expected = 99999
    actual = @s.find_max_price

    assert_equal expected, actual
  end

  def test_it_returns_correct_standard_deviation_for_price
    expected = 2902.69
    actual = @s.standard_deviation_of_item_price.round(2)

    assert_equal expected, actual
  end

  def test_it_can_find_the_golden_items
    expected = 5
    actual = @s.golden_items.length

    assert_equal expected, actual
  end

  def test_it_can_find_one_time_buyers
    expected = 5
    actual = @s.one_time_buyers.length

    assert_equal expected, actual
  end

  def test_it_can_return_paid_in_full_invoice
    expected = false
    actual = @s.invoice_paid_in_full?(16)

    assert_equal expected, actual
  end

  def test_it_can_find_the_invoice_total
    expected = 485.08
    actual = @s.invoice_total(1).to_f.round(2)

    assert_equal expected, actual
  end
# Justine start work on iteration 4
  def test_it_can_find_transactions_by_date
    date = Time.parse('2012-03-27')
    expected = @s.transactions_by_date(date)

    assert_equal 3, expected.length
  end

  def test_it_can_return_successful_transactions
    expected = @s.successful_transactions

    assert_equal 11, expected.length
  end

  def test_it_can_return_successful_invoices_by_date
    expected = @s.successful_invoices_by_date(Time.parse('2012-03-27'))

    assert_equal Array, expected.class
    assert_equal 2, expected.length
  end

  def test_it_can_get_unique_ids_of_successful_transactions_on_date
    dated_success = @s.successful_invoices_by_date(Time.parse('2012-03-27'))
    expected = @s.ids_of_successful_invoices_by_date(dated_success)

    assert_equal 1, expected.length
  end

  def test_it_can_pull_invoice_items_of_ids_for_successful_dated
    dated_success = @s.successful_invoices_by_date(Time.parse('2012-03-27'))
    ids = @s.ids_of_successful_invoices_by_date(dated_success)
    invoice_items = @s.successful_dated_invoice_ids(ids)
    expected = invoice_items.flatten

    assert_instance_of InvoiceItem, expected[0]
    assert_equal 2, expected.length
  end

  def test_it_can_multiply_quantity_and_unit_price
    dated_success = @s.successful_invoices_by_date(Time.parse('2012-03-27'))
    ids = @s.ids_of_successful_invoices_by_date(dated_success)
    invoice_items = @s.successful_dated_invoice_ids(ids)
    items = invoice_items.flatten
    result = @s.quantity_by_unit_price(items)

    assert_equal 2, result.length
  end

  def test_it_can_add_results_of_quantity_by_unit_price
    dated_success = @s.successful_invoices_by_date(Time.parse('2012-03-27'))
    ids = @s.ids_of_successful_invoices_by_date(dated_success)
    invoice_items = @s.successful_dated_invoice_ids(ids)
    items = invoice_items.flatten
    result = @s.quantity_by_unit_price(items)

    assert_equal 3471.59, @s.add_totals(result)
  end

  def test_it_can_return_total_revenue_by_date
    date = Time.parse('2012-03-27')

    assert_equal 3471.59, @s.total_revenue_by_date(date)
  end

  def test_it_can_pull_successful_transactions_invoices
    expected = @s.invoices_by_transactions(@s.successful_transactions)

    assert_equal 3, expected.length
    assert_instance_of Invoice, expected[0]
  end

  def test_it_can_pull_invoices_items
    invoices = @s.invoices_by_transactions(@s.successful_transactions)
    expected = @s.invoice_items_by_invoices(invoices)

    assert_equal 5, expected.length
    assert_instance_of InvoiceItem, expected[0]
  end

  def test_it_can_find_total_cost_of_each_invoice_item
    invoices = @s.invoices_by_transactions(@s.successful_transactions)
    invoice_items = @s.invoice_items_by_invoices(invoices)
    expected = @s.invoice_items_total(invoice_items)

    assert_equal 5, expected.length
    assert_equal 444.68, expected[0].invoice_items_specs[:total]
  end

  def test_it_can_group_invoice_items_by_id
    invoices = @s.invoices_by_transactions(@s.successful_transactions)
    invoice_items = @s.invoice_items_by_invoices(invoices)
    totaled_items = @s.invoice_items_total(invoice_items)
    expected = @s.add_invoice_totals(totaled_items)

    assert_equal 2, expected.length
    assert_instance_of Hash, expected
    assert_equal 6943.18, expected[1]
  end

  def test_it_returns_ordered_highest_merchant_to_lowest
    invoices = @s.invoices_by_transactions(@s.successful_transactions)
    invoice_items = @s.invoice_items_by_invoices(invoices)
    totaled_items = @s.invoice_items_total(invoice_items)
    merchant_totals = @s.add_invoice_totals(totaled_items)
    expected = @s.merchants_high_to_low(merchant_totals, 2)

    assert_equal 2, expected.length
    assert_instance_of Array, expected
    assert_instance_of Merchant, expected[0]
  end

  def test_reports_top_revenue_earners_by_number_given
    expected = @s.top_revenue_earners(10)
    first = expected.first
    last = expected.last

    assert_equal 2, expected.length
    assert_equal Merchant, first.class
    assert_equal 1, first.id
    assert_equal 2179, last.id
  end
# Justine end work on iteration 4
end
