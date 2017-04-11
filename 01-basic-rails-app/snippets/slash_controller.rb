class SlashController < ApplicationController

  def index
    HitCounter.hit!
    render json: {"Hello" => "World", "Hit Count" => HitCounter.hits}
  end

end
