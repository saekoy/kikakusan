require_relative "boot"

require "rails/all"

Bundler.require(*Rails.groups)

module Kikakusan
  class Application < Rails::Application
    config.load_defaults 8.1
    config.autoload_lib(ignore: %w[assets tasks])

    config.generators do |g|
      g.assets false          # CSS, JavaScriptファイルを自動生成しない
      g.helper false      # helperファイルを自動生成しない
      g.test_framework :rspec # テストフレームワークをrspecに設定
    end
  end
end
