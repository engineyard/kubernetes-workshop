class SlashController < ApplicationController

  def index
    HitCounter.hit!
    render json: {"Hit Count" => HitCounter.hits}
  end

end
