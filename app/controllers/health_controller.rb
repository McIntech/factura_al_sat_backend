class HealthController < ActionController::API
  def index
    render json: { status: "ok", timestamp: Time.current }
  end
end
