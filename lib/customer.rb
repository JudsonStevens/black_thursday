# frozen_string_literal: true

# This class makes a new Customer object with the given parameters.
class Customer
  attr_reader :customer_specs
  def initialize(customers, parent)
    @customer_specs = {
      id:           customers[:id].to_i,
      first_name:   customers[:first_name],
      last_name:    customers[:last_name],
      created_at:   Time.parse(customers[:created_at].to_s),
      updated_at:   Time.parse(customers[:updated_at].to_s)
    }
    @parent = parent
  end

  def id
    @customer_specs[:id]
  end

  def first_name
    @customer_specs[:first_name]
  end

  def last_name
    @customer_specs[:last_name]
  end

  def searchable_first_name
    @customer_specs[:first_name].downcase
  end

  def searchable_last_name
    @customer_specs[:last_name].downcase
  end

  def created_at
    @customer_specs[:created_at]
  end

  def updated_at
    @customer_specs[:updated_at]
  end

  def invoices
    @parent.find_all_invoices_by_customer_id(id)
  end

  def fully_paid_invoices
    invoices.map do |invoice|
      invoice unless invoice.is_paid_in_full?.nil?
    end
  end
end
