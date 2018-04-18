require 'sinatra'
require 'sinatra/reloader'
require 'erb'
Dir['./lib/*.rb'].each { |file| require file }
def run_setup
  @sales_engine = SalesEngine.from_csv(
    items:      './data/items.csv',
    merchants:  './data/merchants.csv',
    invoices:   './data/invoices.csv',
    customers:  './data/customers.csv',
    transactions: './data/transactions.csv',
    invoice_items: './data/invoice_items.csv'
  )
  @sales_analyst = SalesAnalyst.new(@sales_engine)
end

get '/' do
  @message = 'Welcome to the customer analytics reporter'

  erb :welcome_page
end

get '/one-time-buyers' do
  run_setup
  @one_time_customers = @sales_analyst.one_time_buyers

  erb :one_time_buyers
end

get '/top-buyers:number' do
  run_setup
  num_of_customers = 20
  path = params[:number].split('-')[1]
  num_of_customers = path.to_i unless params[:number].nil?
  @top_buyers = @sales_analyst.top_buyers(num_of_customers)

  erb :top_buyers
end

def
