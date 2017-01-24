class HealthcheckController < ApplicationController

  def show
    render head: :no_content
  end
end
