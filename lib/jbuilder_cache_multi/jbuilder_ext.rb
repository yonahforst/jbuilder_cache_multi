JbuilderTemplate.class_eval do
  # Caches a collection of objects using fetch_multi, if supported.
  # Requires a block for each item in the array. Accepts optional 'key' attribute in options (e.g. key: 'v1').
  #
  # Example:
  #
  # json.cache_collection! @people, expires_in: 10.minutes do |person|
  #   json.partial! 'person', :person => person
  # end
  def cache_collection!(collection, options = {}, &block)    
    if @context.controller.perform_caching
      keys_to_collection_map = _keys_to_collection_map(collection, options)  

      if ::Rails.cache.respond_to?(:fetch_multi)
        results = ::Rails.cache.fetch_multi(*keys_to_collection_map.keys, options) do |key|
          _scope { yield keys_to_collection_map[key] }
        end        
      else
        results = keys_to_collection_map.map do |key, item|
          ::Rails.cache.fetch(key, options) { _scope { yield item } }
        end
      end
      
      _process_collection_results(results)
    else
      array! collection, options, &block
    end
  end
  
  
  
  protected
  
  ## Implementing our own version of _cache_key because jbuilder's is protected
  def _cache_key_fetch_multi(key, options)
    if @context.respond_to?(:cache_fragment_name)
      # Current compatibility, fragment_name_with_digest is private again and cache_fragment_name
      # should be used instead.
      @context.cache_fragment_name(key, options)
    elsif @context.respond_to?(:fragment_name_with_digest)
      # Backwards compatibility for period of time when fragment_name_with_digest was made public.
      @context.fragment_name_with_digest(key)
    else
      ::ActiveSupport::Cache.expand_cache_key(key.is_a?(::Hash) ? url_for(key).split('://').last : key, :jbuilder)
    end
  end
  
  def _keys_to_collection_map(collection, options)
    key = options.delete(:key)

    collection.inject({}) do |result, item|
      cache_key = key ? [key, item] : item
      result[_cache_key_fetch_multi(cache_key, options)] = item
      result
    end
  end
  
  def _process_collection_results(results)
    _results = results.class == Hash ? results.values : results
    #support pre 2.0 versions of jbuilder where merge! is still private
    if Jbuilder.instance_methods.include? :merge!
      merge! _results
    elsif Jbuilder.private_instance_methods.include? :_merge
      _merge _results
    else
      _results
    end
  end
  
end