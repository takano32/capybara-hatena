require "capybara/hatena/client"

require 'capybara'
require 'capybara/dsl'

module Capybara
  module Hatena
    class Bookmark < Client
    end
  end
end

# Capybara::Hatena::Bookmark
class Capybara::Hatena::Bookmark < Capybara::Hatena::Client
  include Capybara::DSL

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

if $PROGRAM_NAME == __FILE__
  Capybara::Hatena::Bookmark.start do |client|
    client.login
    client.account! 'chatwork'
    client.get('http://go.chatwork.com/')
    client.post('http://go.chatwork.com/', 'ちゃっとわ〜く…')
    sleep 3
  end
end

