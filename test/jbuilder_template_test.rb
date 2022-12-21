require 'test_helper'
require 'mocha/setup'
require 'action_view'
require 'action_view/testing/resolvers'
require 'active_support/cache'
require 'jbuilder'
require 'jbuilder/jbuilder_template'
require 'jbuilder_cache_multi'


BLOG_POST_PARTIAL = <<-JBUILDER
  json.extract! blog_post, :id, :body
  json.author do
    name = blog_post.author_name.split(nil, 2)
    json.first_name name[0]
    json.last_name  name[1]
  end
JBUILDER

CACHE_KEY_PROC = Proc.new { |blog_post| blog_post.id }

BlogPost = Struct.new(:id, :body, :author_name)
blog_authors = [ 'David Heinemeier Hansson', 'Pavel Pravosud' ].cycle
BLOG_POST_COLLECTION = 10.times.map{ |i| BlogPost.new(i+1, "post body #{i+1}", blog_authors.next) }

class JbuilderTemplateTest < ActionView::TestCase
  def partials
    {
      '_partial.json.jbuilder' => 'json.content "hello"',
      '_blog_post.json.jbuilder' => BLOG_POST_PARTIAL
    }
  end

  def assert_collection_rendered(json, context = nil)
    result = MultiJson.load(json)
    result = result.fetch(context) if context
    assert_equal 10, result.length
    assert_equal Array, result.class
    assert_equal 'post body 5', result[4]['body']
    assert_equal 'Heinemeier Hansson', result[2]['author']['last_name']
    assert_equal 'Pavel', result[5]['author']['first_name']
  end

  test 'renders cached array of block partials' do
    undef_context_methods :fragment_name_with_digest, :cache_fragment_name

    json = render_jbuilder <<-JBUILDER
      json.cache_collection! BLOG_POST_COLLECTION do |blog_post|
        json.partial! 'blog_post', :blog_post => blog_post
      end
    JBUILDER

    assert_collection_rendered json
  end

  test 'allows additional options' do
    json = render_jbuilder <<-JBUILDER
      json.cache_collection! BLOG_POST_COLLECTION, expires_in: 1.hour do |blog_post|
        json.partial! 'blog_post', :blog_post => blog_post
      end
    JBUILDER

    assert_collection_rendered json
  end

  test 'renders cached array with a key specified as a proc' do
    undef_context_methods :fragment_name_with_digest, :cache_fragment_name

    json = render_jbuilder <<-JBUILDER
      json.cache_collection! BLOG_POST_COLLECTION, key: CACHE_KEY_PROC do |blog_post|
        json.partial! 'blog_post', :blog_post => blog_post
      end
    JBUILDER

    assert_collection_rendered json
  end

  test 'reverts to cache! if cache does not support fetch_multi' do
    undef_context_methods :fragment_name_with_digest, :cache_fragment_name
    ActiveSupport::Cache::Store.send(:undef_method, :fetch_multi) if ActiveSupport::Cache::Store.method_defined?(:fetch_multi)

    json = render_jbuilder <<-JBUILDER
      json.cache_collection! BLOG_POST_COLLECTION do |blog_post|
        json.partial! 'blog_post', :blog_post => blog_post
      end
    JBUILDER

    assert_collection_rendered json
  end

  test 'reverts to array! when controller.perform_caching is false' do
    controller.perform_caching = false

    json = render_jbuilder <<-JBUILDER
      json.cache_collection! BLOG_POST_COLLECTION do |blog_post|
        json.partial! 'blog_post', :blog_post => blog_post
      end
    JBUILDER

    assert_collection_rendered json
  end

  test 'reverts to array! when collection is empty' do
    json = render_jbuilder <<-JBUILDER
      json.cache_collection! [] do |blog_post|
        json.partial! 'blog_post', :blog_post => blog_post
      end
    JBUILDER

    assert_equal '[]', json
  end

  test 'conditionally fragment caching a JSON object' do
    undef_context_methods :fragment_name_with_digest, :cache_fragment_name

    render_jbuilder <<-JBUILDER
      json.cache_collection_if! true, BLOG_POST_COLLECTION, key: 'cachekey' do |blog_post|
        json.partial! 'blog_post', :blog_post => blog_post
      end
    JBUILDER

    json = render_jbuilder <<-JBUILDER
      json.cache_collection_if! true, BLOG_POST_COLLECTION, key: 'cachekey' do |blog_post|
        json.test 'Miss'
      end
    JBUILDER

    assert_collection_rendered json

    json = render_jbuilder <<-JBUILDER
      json.cache_collection_if! false, BLOG_POST_COLLECTION, key: 'cachekey' do |blog_post|
        json.test 'Miss'
      end
    JBUILDER

    result = MultiJson.load(json)
    assert_equal 'Miss',        result[4]['test']
  end
end
