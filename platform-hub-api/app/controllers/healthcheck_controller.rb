class HealthcheckController < ApplicationController

  def show
    head :no_content
  end
end
