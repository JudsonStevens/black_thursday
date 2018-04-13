# frozen_string_literal: true

require_relative 'transaction'
require_relative 'repository_helper'
# This class holds our transactions and gives us methods to interact with them.
class TransactionRepository
  include RepositoryHelper
  attr_reader :repository,
              :parent
  def initialize(transactions, parent)
    @repository = transactions.map do |transaction|
      Transaction.new(transaction, parent)
    end
    @parent = parent
    build_hash_table
  end

  def build_hash_table
    @id = @repository.group_by(&:id)
    @invoice_id = @repository.group_by(&:invoice_id)
    @credit_card_number = @repository.group_by(&:credit_card_number)
    @credit_card_expiration_date = @repository.group_by(
      &:credit_card_expiration_date
    )
    @result = @repository.group_by(&:result)
    @created_at = @repository.group_by(&:created_at)
    @updated_at = @repository.group_by(&:updated_at)
  end

  def find_all_by_credit_card_number(credit_card_num)
    return [] if @credit_card_number[credit_card_num].nil?
    @credit_card_number[credit_card_num]
  end

  def find_all_by_result(result)
    return [] if @result[result].nil?
    @result[result]
  end

  def update(id, attributes)
    transaction = find_by_id(id)
    unchangeable_keys = %i[id transaction_id created_at]
    attributes.each do |key, value|
      next if (attributes.keys & unchangeable_keys).any?
      if transaction.transaction_specs.keys.include?(key)
        transaction.transaction_specs[key] = value
        transaction.transaction_specs[:updated_at] = Time.now
      end
    end
    build_hash_table
  end

  def create(attributes)
    attributes[:id] = (@id.keys.last + 1)
    @repository << Transaction.new(attributes, self)
    build_hash_table
  end

  def delete(id)
    transaction_to_delete = find_by_id(id)
    @repository.delete(transaction_to_delete)
    build_hash_table
  end

  def group_transactions
    @repository.group_by(&:result)
  end

  def find_invoice_by_invoice_id(invoice_id)
    @parent.find_invoice_by_invoice_id(invoice_id)
  end

  def inspect
    "<#{self.class} #{@repository.size} rows>"
  end
end
