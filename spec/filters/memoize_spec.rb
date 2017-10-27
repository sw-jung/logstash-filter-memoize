# encoding: utf-8
require_relative '../spec_helper'
require "logstash/filters/memoize"

describe LogStash::Filters::Memoize do
  describe "basic work" do
    let(:config) do <<-CONFIG
      filter {
        ruby {
          code => "event.set('time', Time.now.to_f)"
        }

        memoize {
          key => "%{key}"
          fields => ["result"]
          filter_name => "ruby"
          filter_options => {
            code => "event.set('result', event.get('time'))"
          }
        }
      }
    CONFIG
    end

    sample([
      {"key" => "cache_key"},
      {"key" => "cache_key2"},
      {"key" => "cache_key"}
    ]) do
      # If key is different, result different also.
      expect(subject[0].get("time")).to eq(subject[0].get("result"))
      expect(subject[1].get("time")).to eq(subject[1].get("result"))
      expect(subject[0].get("time")).not_to eq(subject[1].get("result"))
      
      # If key is same, cache works
      expect(subject[0].get("time")).to eq(subject[0].get("result"))
      expect(subject[2].get("time")).not_to eq(subject[2].get("result"))
      expect(subject[0].get("time")).to eq(subject[2].get("result"))
    end
  end

  describe "ttl work" do
    let(:config) do <<-CONFIG
      filter {
        ruby {
          code => "event.set('time', Time.now.to_f)"
        }

        memoize {
          key => "%{key}"
          fields => ["result"]
          filter_name => "ruby"
          filter_options => {
            code => "event.set('result', event.get('time'))"
          }
          ttl => 1
        }

        sleep {
          time => "2"
        }
      }
    CONFIG
    end

    sample([
      {"key" => "cache_key"},
      {"key" => "cache_key"}
    ]) do
      # After ttl seconds, cached value are delete
      expect(subject[0].get("time")).to eq(subject[0].get("result"))
      expect(subject[1].get("time")).to eq(subject[1].get("result"))
      expect(subject[0].get("time")).not_to eq(subject[1].get("result"))
    end
  end

  describe "cache_size work" do
    let(:config) do <<-CONFIG
      filter {
        ruby {
          code => "event.set('time', Time.now.to_f)"
        }

        memoize {
          key => "%{key}"
          fields => ["result"]
          filter_name => "ruby"
          filter_options => {
            code => "event.set('result', event.get('time'))"
          }
          cache_size => 1
        }
      }
    CONFIG
    end

    sample([
      {"key" => "cache_key"},
      {"key" => "cache_key2"},
      {"key" => "cache_key"}
    ]) do
      # If cache over cache size, old cached value are delete first
      expect(subject[0].get("time")).to eq(subject[0].get("result"))
      expect(subject[1].get("time")).to eq(subject[1].get("result"))
      expect(subject[2].get("time")).to eq(subject[2].get("result"))
      expect(subject[0].get("time")).not_to eq(subject[2].get("result"))
    end
  end
end
