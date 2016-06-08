# This is a starting point. Feel free to add / modify, as long as the tests pass

require "pry"
require "sinatra/base"
require "sinatra/json"

require "./db/setup"
require "./lib/all"

class ShopDBApp < Sinatra::Base
  set :logging, true
  set :show_exceptions, false

  error do |e|
    #binding.pry
    raise e
  end

  def self.reset_database
    [User, Item, Purchase].each { |klass| klass.delete_all }
  end

  def user
    password = request.env["HTTP_AUTHORIZATION"]
    if password
      User.find_by(password: password)
    else
      halt 401
    end
  end

  post "/users" do
    User.create(first_name: params[:first_name], last_name: params[:last_name], password: params[:password])
  end

  post "/items" do
    Item.create(description: params[:description], price: params[:price], created_by: user.id)
  end

  post "/items/:id/buy" do
    if Item.find(params[:id])
      Purchase.create(user_id: user.id, item_id: params[:id], quantity: params[:quantity])
    else
      raise ActiveRecord::RecordNotFound
    end
  end

  get "/items/:id/purchases" do
    purchases = []
    Purchase.where(item_id: params[:id]).each do |p|
      purchases.push(p.user_id)
    end

    json purchases
  end


  delete "/items/:id" do
    if Item.find(params[:id]).created_by == user.id
      Item.delete_all(params[:id])
      200
    else
      403
    end
  end

end
