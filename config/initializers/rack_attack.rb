Rack::Attack.cache.store = Rails.cache

class Rack::Attack
  # /ideas への企画生成リクエストを1IPあたり1分間3回まで制限
  throttle('ideas/generate', limit: 3, period: 60) do |req|
    req.ip if req.path == '/ideas' && req.post?
  end

  # 制限超過時に429を返す
  throttled_responder = lambda do |_req|
    [
      429,
      { 'Content-Type' => 'application/json' },
      [{ error: 'too_many_requests', retry_after: 60 }.to_json]
    ]
  end

  self.throttled_responder = throttled_responder
end
