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
  
  def _keys_to_collection_map(collection, options)
    key = options.delete(:key)

    collection.inject({}) do |result, item|
      cache_key = key ? [key, item] : item
      result[_cache_key(cache_key, options)] = item
      result
    end
  end
  
  def _process_collection_results(results)
    case results
    when ::Hash
      merge! results.values
    else
      merge! results
    end  
  end
  
  
end