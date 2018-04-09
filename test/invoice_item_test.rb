# frozen_string_literal: true

require 'simplecov'
SimpleCov.start
require './lib/file_loader.rb'
require './lib/invoice_item.rb'
require './lib/item.rb'
require './lib/item_repository.rb'
require 'minitest'
require 'minitest/autorun'
require 'minitest/emoji'
require 'mocha/mini_test'
require 'ostruct'
require 'pry'

# Provides an API of invoice item repo for testing invoice item class
class MockInvoiceItemRepo
end

# Tests invoice item class and functionality with invoice item repo
class InvoiceItemTest < Minitest::Test
  INVOICE_ITEM_BODY = {
    id: '1',
    item_id: '263519844',
    invoice_id: '1',
    quantity: '5',
    unit_price: '13635',
    created_at: '2012-03-27 14:54:09 UTC',
    updated_at: '2012-03-27 14:54:09 UTC'
  }.freeze

  attr_reader :invoice_item

  def setup
    @invoice_item = InvoiceItem.new(INVOICE_ITEM_BODY, MockInvoiceItemRepo.new)
  end

  def test_invoice_item_exists
    assert_instance_of InvoiceItem, @invoice_item
  end

  def test_it_intializes_with_item_spec_hash
    assert_instance_of Hash, invoice_item.invoice_items_specs
  end

  def test_it_initializes_with_parent
    assert_equal MockInvoiceItemRepo, invoice_item.parent.class
  end

  def test_it_returns_integer_id
    assert_equal 1, invoice_item.id
  end

  def test_it_returns_items_id
    assert_equal 263519844, invoice_item.item_id
  end

  def test_it_returns_invoice_id
    assert_equal 1, invoice_item.invoice_id
  end
end
