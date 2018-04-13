# frozen_string_literal: true

# Module with funtions to help search objects.
module RepositoryHelper
  def all
    @repository
  end

  def find_by_id(id)
    return nil if @id[id].nil?
    @id[id].first
  end

  def find_all_by_merchant_id(merchant_id)
    return [] if @merchant_id[merchant_id].nil?
    @merchant_id[merchant_id]
  end

  def find_all_by_customer_id(cust_id)
    return [] if @customer_id[cust_id].nil?
    @customer_id[cust_id]
  end

  def find_all_by_created_at(date)
    @created_at[date]
  end

  def find_by_created_at(date)
    return nil if @created_at[date].nil?
    @created_at[date].first
  end

  def find_all_by_invoice_id(invoice_id)
    return [] if @invoice_id[invoice_id].nil?
    @invoice_id[invoice_id]
  end
end
