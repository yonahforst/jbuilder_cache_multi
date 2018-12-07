# JbuilderCacheMulti

Useful when you need to retrieve fragments for a collection of objects from the cache. This plugin gives you method called 'cache_collection!' which uses fetch_multi (new in Rails 4.1) to retrieve multiple keys in a single go.

This means less queries to the cache == faster responses. If items are not found, they are writen to the cache (individualy in the case of memcache which doesn't support writing items in batch...yet). For some cache stores, multi-write is supported (Redis/Memory cache).

## Installation

Add this line to your application's Gemfile:

    gem 'jbuilder_cache_multi'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install jbuilder_cache_multi

## Usage

Renders the given block for each item in the collection. Accepts optional 'key' attribute in options (e.g. key: 'v1').

Note: At the moment, does not accept the partial name as an argument (#todo)

Examples:

	json.cache_collection! @people, expires_in: 10.minutes do |person|
	  json.partial! 'person', :person => person
	end

	# Or with optional key

	json.cache_collection! @people, expires_in: 10.minutes, key: 'v1' do |person|
	  json.partial! 'person', :person => person
	end
	
	# Or with a proc as a key 
	
	json.cache_collection! @people, expires_in: 10.minutes, key: proc {|person| person.last_posted_at } do |person|
      json.partial! 'person', :person => person
    end
  
NOTE: If the items in your collection don't change frequently, it might be better to cache the entire collection like this:
(in which case you don't need this gem)

	json.cache! @people do
	  json.partial! 'person', collection: @people, as: :person
	end

Or you can use a combination of both!
This will cache the entire collection. If a single item changes it will use read_multi to get all unchanged items and regenerate only the changed item(s).

	json.cache! @people do
	  json.cache_collection! @people do |person|
	    json.partial! 'person', :person => person
	  end
	end
	
Last thing: If you are using a collection for the cache key, may I recommend the 'scope_cache_key' gem? (check out my fork for a Rails 4 version: https://github.com/joshblour/scope_cache_key). It very quickly calculates a hash for all items in the collection (MD5 hash of updated_at + IDs).

You can also conditionally cache a block by using `cache_collection_if!` like this:

	json.cache_collection_if! do_cache?, @people, expires_in: 10.minutes do |person|
	  json.partial! 'person', :person => person
	end
	
## Todo

- Add support for passing a partial name as an argument (e.g. json.cache_collection! @people, partial: 'person') or maybe even just "json.cache_collection! @people" and infer the partial name from the collection...

- When rendering other partials, use the hash of THAT partial for the cache_key (I beleieve it currently uses the view from where cache_collection! is called to calculate the cache_key) #not_good

## Contributing

1. Fork it ( https://github.com/joshblour/jbuilder_cache_multi/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Testing
    bundle install
    appraisal install
    appraisal rake test

## Credit
Inspired by https://github.com/n8/multi_fetch_fragments. Thank you!
And of course https://github.com/rails/jbuilder
