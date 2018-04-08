# frozen_string_literal: true

require 'bigdecimal'
require 'time'
# This object stores all of the data that is connected to the items, along with
# a reference to the parent, which is the item repository. All of these
# variables are stored as instance variables so they can be read outside of
# the class.
class Item
  attr_accessor :item_specs
  def initialize(items)
    @item_specs = {
      id:                     items[:id].to_i,
      name:                   items[:name],
      description:            items[:description],
      unit_price:             BigDecimal(items[:unit_price]) / 100,
      merchant_id:            items[:merchant_id].to_i,
      created_at:             items[:created_at],
      updated_at:             items[:updated_at],
      searchable_desc:        items[:description].downcase
    }
  end

  def unit_price_to_dollars
    @item_specs[:unit_price].to_f
  end

  def unit_price
    @item_specs[:unit_price]
  end

  def id
    @item_specs[:id]
  end

  def name
    @item_specs[:name]
  end

  def description
    @item_specs[:description]
  end

  def merchant_id
    @item_specs[:merchant_id]
  end

  def created_at
    Time.parse(@item_specs[:created_at])
  end

  def updated_at
    Time.parse(@item_specs[:updated_at])
  end
end
