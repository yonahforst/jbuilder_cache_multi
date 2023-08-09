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
    if @context.controller.perform_caching && !collection.to_a.empty?
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

  # Conditionally caches a collection of objects depending in the condition given as first parameter.
  #
  # Example:
  #
  # json.cache_collection_if! do_cache?, @people, expires_in: 10.minutes do |person|
  #   json.partial! 'person', :person => person
  # end
  def cache_collection_if!(condition, collection, options = {}, &block)
    condition ?
        cache_collection!(collection, options, &block) :
        array!(collection, options, &block)
  end

  protected

  ## Implementing our own version of _cache_key because jbuilder's is protected
  def _cache_key_fetch_multi(key, options)
    key = _fragment_name_with_digest_fetch_multi(key, options)
    key = url_for(key).split('://', 2).last if ::Hash === key
    ::ActiveSupport::Cache.expand_cache_key(key, :jbuilder)
  end

  def _fragment_name_with_digest_fetch_multi(key, options)
    if @context.respond_to?(:cache_fragment_name)
      # Current compatibility, fragment_name_with_digest is private again and cache_fragment_name
      # should be used instead.
      @context.cache_fragment_name(key, **options.slice(:skip_digest, :virtual_path))
    elsif @context.respond_to?(:fragment_name_with_digest)
      # Backwards compatibility for period of time when fragment_name_with_digest was made public.
      @context.fragment_name_with_digest(key)
    else
      key
    end
  end

  def _keys_to_collection_map(collection, options)
    key = options.delete(:key)

    collection.inject({}) do |result, item|
      cache_key =
          if key.respond_to?(:call)
            key.call(item)
          elsif key
            [key, item]
          else
            item
          end
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
