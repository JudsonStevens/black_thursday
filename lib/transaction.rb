# frozen_string_literal: true

require 'time'
# This class makes a new Transaction object with the given parameters.
class Transaction
  attr_reader :transaction_specs
  def initialize(transactions, parent)
    @transaction_specs = {
      id:                           transactions[:id].to_i,
      invoice_id:                   transactions[:invoice_id].to_i,
      credit_card_number:           transactions[:credit_card_number].to_i,
      credit_card_expiration_date:  transactions[:credit_card_expiration_date],
      result:                       transactions[:result],
      created_at:                   Time.parse(transactions[:created_at].to_s),
      updated_at:                   Time.parse(transactions[:updated_at].to_s)
    }
    @parent = parent
  end

  def id
    @transaction_specs[:id]
  end

  def invoice_id
    @transaction_specs[:invoice_id]
  end

  def credit_card_number
    @transaction_specs[:credit_card_number].to_s
  end

  def credit_card_expiration_date
    @transaction_specs[:credit_card_expiration_date]
  end

  def result
    @transaction_specs[:result].to_sym
  end

  def created_at
    @transaction_specs[:created_at]
  end

  def updated_at
    @transaction_specs[:updated_at]
  end

  def invoice
    @parent.find_invoice_by_invoice_id(@transaction_specs[:invoice_id])
  end
end
