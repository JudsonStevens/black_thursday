module AnalysisHelper
  def all_items
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
end
