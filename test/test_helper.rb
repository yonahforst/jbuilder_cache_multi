require "bundler/setup"
require "rails/version"

if Rails::VERSION::STRING > "4.0"
  require "active_support/testing/autorun"
else
  require "test/unit"
end

require "active_support/test_case"

module Rails
  def self.cache
    @cache ||= ActiveSupport::Cache::MemoryStore.new
  end
  def self.env
    ENV["RAILS_ENV"] || ENV["RACK_ENV"] || 'test'
  end
end

module ActiveSupport
  class TestCase

    # Stub out a couple of methods that'll get called from cache_fragment_name
    def view_cache_dependencies
      []
    end

    def formats
      [:json]
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
  end
end
