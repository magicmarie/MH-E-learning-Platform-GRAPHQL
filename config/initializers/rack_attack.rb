# frozen_string_literal: true

class Rack::Attack
  # Throttle reset requests per IP
  throttle("password_resets/ip", limit: 5, period: 60.minutes) do |req|
    if req.path == "/api/reset_password" && req.post?
      req.ip
    end
  end

  # Custom response
  self.throttled_responder = lambda do |env|
    [ 429, { "Content-Type" => "application/json" }, [ { error: "Too many requests" }.to_json ] ]
  end
end
