# encoding: utf-8
require "logstash/filters/base"
require "logstash/namespace"
require "lru_redux"

# This filter provides https://en.wikipedia.org/wiki/Memoization[memoization] to wrapped filter.
# Internally, It based on https://en.wikipedia.org/wiki/Cache_replacement_policies#LRU[LRU] cache algorithm.
#
# See below an example of how this filter might be used.
# [source,ruby]
# --------------------------------------------------
# filter {
#   memoize {
#     key => "%{host}" <1>
#     fields => ["host_owner", "host_location"] <2>
#     filter_name => "elasticsearch" <3>
#     filter_options => { <4>
#       query => "host:%{host}"
#       index => "known_host"
#       fields => {
#         "host_owner" => "host_owner"
#         "host_location" => "host_location"
#       }
#     }
#   }
# }
# --------------------------------------------------
# 
# * When an event with a new <1> key comes in, execute wrapped <3> <4> filter and caches the <2> fields value.
# * When an event with a same <1> key comes in, sets cached value to target <2> fields without wrapped <3> <4> filter execution.
#
class LogStash::Filters::Memoize < LogStash::Filters::Base

  config_name "memoize"

  # The key to use caching and retrieving values. It can be dynamic and include parts of the event using the %{field}.
  config :key, :validate => :string, :required => true

  # The fields to be cached from result, or to be set cached value.
  config :fields, :validate => :array, :required => true

  # The filter name what you want to use.
  config :filter_name, :validate => :string, :required => true

  # The filter options what you want to use. You can use all of options in the `filter_name` filter.
  config :filter_options, :validate => :hash, :default => {}

  # Maximum size of cache.
  config :cache_size, :validate => :number, :default => 1000

  # The TTL(Time To Live) of cached value.
  config :ttl, :validate => :number
  
  public
  def register
    @filter = LogStash::Plugin.lookup("filter", @filter_name).new(@filter_options)
    @filter.register
    @cache = ::LruRedux::TTL::ThreadSafeCache.new(@cache_size, @ttl)
  end # def register

  public
  def filter(event)
    formattedKey = event.sprintf(@key);
    result = @cache[formattedKey]

    if !result.nil?
      @logger.debug("Cached value found.", :key => formattedKey, :value => result) if @logger.debug?
      @fields.each { |field| event.set(field, result[field]) }
    else
      @logger.debug("Cached value not found. Do filter.", :key => formattedKey, :filter => @filter) if @logger.debug?
      @filter.filter(event)
      @fields.each { |field| (result ||= {})[field] = event.get(field) }
      @cache[formattedKey] = result
    end

    # filter_matched should go in the last line of our successful code
    filter_matched(event)
  end # def filter
end # class LogStash::Filters::Memoize
