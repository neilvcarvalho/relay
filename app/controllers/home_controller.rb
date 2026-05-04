class HomeController < ApplicationController
  def index
    @ynab_connection = Current.user.ynab_connection
  end
end
