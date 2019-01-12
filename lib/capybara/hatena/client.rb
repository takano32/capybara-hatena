# vim: et sts=2:ts=2:sw=2

# require 'headless'
require 'capybara'
require 'capybara/dsl'
require 'capybara/poltergeist'
require 'selenium/webdriver'

Capybara.register_driver :poltergeist do |app|
  # Capybara::Poltergeist::Driver.new(app, inspector: true)
  opts = {
    js_errors: false,
    phantomjs_logger: File.open(IO::NULL),
  }
  Capybara::Poltergeist::Driver.new(app, opts)
end

Capybara.register_driver :chrome do |app|
  # Capybara::Poltergeist::Driver.new(app, inspector: true)
  # Capybara::Poltergeist::Driver.new(app, js_errors: false)
  Capybara::Selenium::Driver.new(app, browser: :chrome)
end

Capybara.register_driver :headless_chrome do |app|
  capabilities = Selenium::WebDriver::Remote::Capabilities.chrome(
    chromeOptions: { args: %w[headless no-sandbox disable-gpu disable-dev-shm-usage disable-setuid-sandbox] }
  )

  Capybara::Selenium::Driver.new(
    app,
    browser: :chrome,
    desired_capabilities: capabilities
  )
end

Capybara.default_driver = :chrome
Capybara.javascript_driver = :chrome

if ENV['QT_QPA_PLATFORM'] # == 'offscreen'
  Capybara.default_driver = :poltergeist
  Capybara.javascript_driver = :poltergeist
end

if ENV['HEADLESS']
  # Capybara::default_driver = :chrome
  Capybara.default_driver = :headless_chrome
  Capybara.javascript_driver = :headless_chrome
end

module Capybara
  module Hatena
    class Client
    end
  end
end

# Capybara::Hatena::Client
class Capybara::Hatena::Client
  include Capybara::DSL

  def self.start(login_name = ENV['LOGIN_NAME'], password = ENV['PASSWORD'], &block)
    require 'time'
    Capybara.using_session Time.now.iso8601(3) do
      block.yield(self.new)
    end
  end

  def initialize(login_name = ENV['LOGIN_NAME'], password = ENV['PASSWORD'])
    @login_name = login_name
    @password = password
  end

  def login
    url = 'https://www.hatena.ne.jp/login'
    uri = URI.parse url

    visit uri
    sleep 5

    fill_in 'login-name', with: @login_name
    fill_in 'password', with: @password
    find('input[type=submit]').click
  end

  def account!(id)
    url = 'https://www.hatena.ne.jp/my/config/account'
    uri = URI.parse url

    visit uri
    sleep 5

    forms = find_all(:xpath, '//form')
    forms.each do |form|
      inputs = form.find_all(:xpath, 'input', visible: false)
      inputs.each do |input|
        if input[:name] == 'name' and input.value == id
          form.find('input[type=submit]').click
          return
        end
      end
    end
  end

end

if $PROGRAM_NAME == __FILE__
  Capybara::Hatena::Client.start do |client|
    client.login
    client.account! 'chatwork'
    sleep 5
  end
end

