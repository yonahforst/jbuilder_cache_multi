require 'test_helper'
require 'mocha/setup'
require 'action_view'
require 'action_view/testing/resolvers'
require 'active_support/cache'
require 'jbuilder'
require 'jbuilder/jbuilder_template'
require 'jbuilder_cache_multi'
require 'active_record'
require 'sqlite3'

ActiveRecord::Base.establish_connection adapter: "sqlite3", database: ":memory:"
load File.dirname(__FILE__) + '/schema.rb'

POST_PARTIAL = <<-JBUILDER
  json.extract! post, :id, :body
  json.author do
    name = post.author.name.split(nil, 2)
    json.first_name name[0]
    json.last_name  name[1]
  end
JBUILDER

class Author < ActiveRecord::Base
  has_many :post
end
class Post < ActiveRecord::Base
  belongs_to :author
end

blog_authors = ['David Heinemeier Hansson', 'Pavel Pravosud' ].cycle
POST_COLLECTION = 10.times.map do |i|
  Post.create!(
    body: "post body #{i + 1}",
    author: Author.create!(name: blog_authors.next)
  )
end

module Rails
  def self.cache
    @cache ||= ActiveSupport::Cache::MemoryStore.new
  end
end

class JbuilderTemplateActiveRecordRelationTest < ActionView::TestCase

  def partials
    {
      '_post.json.jbuilder' => POST_PARTIAL
    }
  end

  def assert_collection_rendered(json, context = nil)
    result = MultiJson.load(json)
    result = result.fetch(context) if context

    assert_equal 10, Post.count
    assert_equal Array, result.class
    assert_equal 'post body 5', result[4]['body']
    assert_equal 'Heinemeier Hansson', result[2]['author']['last_name']
    assert_equal 'Pavel', result[5]['author']['first_name']
  end

  setup do
    @context = self
    Rails.cache.clear
  end

  test 'render ActiveRecord::Relation with default key' do
    json = render_jbuilder <<-JBUILDER
      json.cache_collection! Post.all do |post|
        json.partial! 'post', :post => post
      end
    JBUILDER

    assert_collection_rendered json
  end

  test 'render ActiveRecord::Relation with fields as key' do
    json = render_jbuilder <<-JBUILDER
      json.cache_collection! Post.joins(:author).includes(:author), key: %i[posts.updated_at authors.updated_at] do |post|
        json.partial! 'post', :post => post
      end
    JBUILDER

    assert_collection_rendered json
  end

  test 'render ActiveRecord::Relation with proc as key' do
    json = render_jbuilder <<-JBUILDER
      json.cache_collection! Post.all, key: Proc.new { |post| post.author } do |post|
        json.partial! 'post', :post => post
      end
    JBUILDER

    assert_collection_rendered json
  end

end
