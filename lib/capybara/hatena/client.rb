# vim: et sts=2:ts=2:sw=2

# require 'headless'
require 'capybara'
require 'capybara/dsl'
require 'capybara/poltergeist'
require 'selenium/webdriver'

Capybara.register_driver :poltergeist do |app|
  # Capybara::Poltergeist::Driver.new(app, inspector: true)
  Capybara::Poltergeist::Driver.new(app, js_errors: false)
end

Capybara.register_driver :chrome do |app|
  # Capybara::Poltergeist::Driver.new(app, inspector: true)
  # Capybara::Poltergeist::Driver.new(app, js_errors: false)
  Capybara::Selenium::Driver.new(app, browser: :chrome)
end

Capybara.register_driver :headless_chrome do |app|
  capabilities = Selenium::WebDriver::Remote::Capabilities.chrome(
    chromeOptions: { args: %w[headless disable-gpu disable-dev-shm-usage] }
  )

  Capybara::Selenium::Driver.new(
    app,
    browser: :chrome,
    desired_capabilities: capabilities
  )
end

Capybara.default_driver = :chrome
Capybara.javascript_driver = :chrome

if ENV['QT_QPA_PLATFORM']
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
    # Capybara::Hatena::Client
    class Client
      include Capybara::DSL

      def self.start(login_name = ENV['LOGIN_NAME'], password = ENV['PASSWORD'], &block)
        require 'time'
        Capybara.using_session Time.now.iso8601(3) do
          block.yield(Capybara::Hatena::Client.new)
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

        fill_in 'login-name', with: @login_name
        fill_in 'password', with: @password
        find('input[type=submit]').click
      end

      def account!(id)
        url = 'https://www.hatena.ne.jp/my/config/account'
        uri = URI.parse url

        visit uri

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

      def get(url)
        entry_url = 'https://b.hatena.ne.jp/my/add'
        uri = URI.parse entry_url

        visit uri

        fill_in 'url', with: url
        all('input[type=submit]').last.click

        users = find(:xpath, '//*[@id="container"]/div/div[2]/div/p[1]/a/span').text.to_i
        tags = all(:xpath, '//*[@id="container"]/div/div[3]/div/div/div/ul[2]/li').map do |e|
          e.text
        end
        
        [users, tags]
        comment = find(:xpath, '//*[@id="container"]/div/div[3]/div/div/form/div[1]/textarea').text
        comment
      end

      def post(url, comment)
        entry_url = 'https://b.hatena.ne.jp/my/add'
        uri = URI.parse entry_url

        visit uri

        fill_in 'url', with: url
        all('input[type=submit]').last.click

        # fill_in 'annotation', with: ''
        # fill_in 'annotation', with: comment
        textarea = all(:xpath, '//textarea').last
        textarea.set ''
        textarea.set comment
        all('input[type=submit]').last.click
      end

    end
  end
end

if $PROGRAM_NAME == __FILE__
  Capybara::Hatena::Client.start do |client|
    client.login
    client.account! 'chatwork'
    client.get('http://go.chatwork.com/')
    client.post('http://go.chatwork.com/', 'ちゃっとわ〜く…')
  end
end

