# frozen_string_literal: true

require_relative 'merchant.rb'
require_relative 'repository_helper.rb'
# This object holds all of the merchants. On initialization, we feed in the
# seperated out list of merchants, which we obtained from the CSV file. For each
# row, denoted here by the merchant variable, we insantiate a new item object
# that includes a reference to it's parent. We store this list in the
# merchant_list isntance variable, allowing us to reference the list outside of
# this class. The list is stored as an array.
class MerchantRepository
  include RepositoryHelper
  attr_reader :merchant_list,
              :parent,
              :id,
              :name,
              :created_at,
              :updated_at
  def initialize(merchants, parent)
    @repository = merchants.map { |merchant| Merchant.new(merchant, self) }
    @parent = parent
    build_hash_table
  end

  def build_hash_table
    @id = @repository.group_by(&:id)
    @name = @repository.group_by(&:name)
    @created_at = @repository.group_by(&:created_at)
    @updated_at = @repository.group_by(&:updated_at)
  end

  def create(attributes)
    attributes[:id] = (@id.keys.sort.last + 1)
    attributes[:created_at] = Time.now
    attributes[:updated_at] = Time.now
    @repository << Merchant.new(attributes, self)
    build_hash_table
  end

  def find_by_name(name)
    @repository.find { |merchant| merchant.searchable_name == name.downcase }
  end

  def find_all_by_name(name)
    @repository.find_all do |merchant|
      merchant.searchable_name.include?(name.downcase)
    end
  end

  def delete(id)
    merchant_to_delete = find_by_id(id)
    @repository.delete(merchant_to_delete)
    build_hash_table
  end

  def update(id, attributes)
    merchant = find_by_id(id)
    unchangeable_keys = %i[id created_at]
    attributes.each do |key, value|
      next if (attributes.keys & unchangeable_keys).any?
      if merchant.merchant_specs.keys.include?(key)
        merchant.merchant_specs[key] = value
        merchant.merchant_specs[:updated_at] = Time.now
      end
    end
    build_hash_table
  end

  def find_items_by_merchant_id(merchant_id)
    @parent.find_all_items_by_merchant_id(merchant_id)
  end

  def find_invoices_by_merchant_id(merchant_id)
    @parent.find_invoices_by_merchant_id(merchant_id)
  end

  def find_customers_by_merchant_id(merchant_id)
    @parent.find_customers_by_merchant_id(merchant_id)
  end

  def inspect
    "<#{self.class} #{@repository.size} rows>"
  end
end
