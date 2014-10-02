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

CACHE_KEY_PROC = Proc.new { |blog_post| true }

BlogPost = Struct.new(:id, :body, :author_name)
blog_authors = [ 'David Heinemeier Hansson', 'Pavel Pravosud' ].cycle
BLOG_POST_COLLECTION = 10.times.map{ |i| BlogPost.new(i+1, "post body #{i+1}", blog_authors.next) }

module Rails
  def self.cache
    @cache ||= ActiveSupport::Cache::MemoryStore.new
  end
end

class JbuilderTemplateTest < ActionView::TestCase
  setup do
    @context = self
    Rails.cache.clear
  end

  def partials
    {
      '_partial.json.jbuilder'  => 'json.content "hello"',
      '_blog_post.json.jbuilder' => BLOG_POST_PARTIAL
    }
  end

  def render_jbuilder(source)
    @rendered = []
    lookup_context.view_paths = [ActionView::FixtureResolver.new(partials.merge('test.json.jbuilder' => source))]
    ActionView::Template.new(source, 'test', JbuilderHandler, :virtual_path => 'test').render(self, {}).strip
  end

  def undef_context_methods(*names)
    self.class_eval do
      names.each do |name|
        undef_method name.to_sym if self.method_defined?(name.to_sym)
      end
    end
  end

  def assert_collection_rendered(json, context = nil)
    result = MultiJson.load(json)
    result = result.fetch(context) if context
    
    assert_equal 10, result.length
    assert_equal Array, result.class
    assert_equal 'post body 5',        result[4]['body']
    assert_equal 'Heinemeier Hansson', result[2]['author']['last_name']
    assert_equal 'Pavel',              result[5]['author']['first_name']
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

  test 'renders cached array with a key specified as a proc' do
    undef_context_methods :fragment_name_with_digest, :cache_fragment_name
    CACHE_KEY_PROC.expects(:call)

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

end
