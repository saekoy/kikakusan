Rack::Attack.cache.store = Rails.cache

class Rack::Attack
  # 1IPあたり1分間3回まで
  throttle('ideas/generate/minute', limit: 3, period: 60) do |req|
    req.ip if req.path == '/ideas' && req.post?
  end

  # 1IPあたり1日50回まで
  throttle('ideas/generate/day', limit: 50, period: 24 * 60 * 60) do |req|
    req.ip if req.path == '/ideas' && req.post?
  end

  # 制限超過時に429を返す
  self.throttled_responder = lambda do |_req|
    [
      429,
      { 'Content-Type' => 'application/json' },
      [{ error: 'too_many_requests', retry_after: 60 }.to_json]
    ]
  end
end
