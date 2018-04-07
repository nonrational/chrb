require 'active_support'
require 'clubhouse_ruby'
require 'csv'
require 'faraday_middleware'
require 'her'
require 'json'
require 'parallel'
require 'pry'
require 'dotenv'

module Clubhouse
  ORG_NAME = 'nonrational'.upcase

  Dotenv.load

  BETA_API = Her::API.new
  BETA_API.setup url: "https://app.clubhouse.io/backend/api/beta/", send_only_modified_attributes: true do |conn|
    conn.request :curl, Logger.new(STDOUT), :info

    conn.request :json
    conn.params[:token] = ENV.fetch("CHRB_#{ORG_NAME}_CLUBHOUSE_API_TOKEN")

    conn.use Her::Middleware::DefaultParseJSON
    conn.use Faraday::Adapter::NetHttp
  end

  Her::API.setup url: "https://api.clubhouse.io/api/v2/", send_only_modified_attributes: true do |conn|
    conn.request :curl, Logger.new(STDOUT), :info

    conn.request :json
    conn.params[:token] = ENV.fetch("CHRB_#{ORG_NAME}_CLUBHOUSE_API_TOKEN")
    # conn.params[:page] = 0

    conn.use Her::Middleware::DefaultParseJSON
    conn.use Faraday::Adapter::NetHttp
  end

  COLORS = {
    wheat: '#f5e6ad',
    chestnut_rose: '#cc5856',
    lavender_magenta: "#e885d1",
    fire_bush: "#e69235",
    apple: "#49a940",
    cornflower_blue: "#6db5ec",
    cerulean_blue: "#4641d2",
    dusty_gray: "#999999",
    # unorthodox
    cornflower_lilac: "#6db5ec",
    burnt_sienna: "#6db5ec",
    thunderbird: "#c02b18",
    olive_drab: "#6b8e23"
  }

  class UnsupportedApiError < RuntimeError
  end

  class Resource
    include Her::Model

    def self.raise_unsupported!
      raise UnsupportedApiError.new("#{self.name}.#{caller_locations.first.label} is not supported")
    end

    def self.where(_)
      raise_unsupported!
    end

    def self.first
      all.first
    end
  end

  class Repository < Resource
  end

  class Project < Resource
  end

  class Iteration < Resource
    attributes :name
    use_api BETA_API

    has_many :comments

    # def browse_url
    #   super + { page: 1 }.to_query
    # end
  end

  class Label < Resource
    attributes :name, :color, :archived

    def self.named_like(pattern)
      all.select { |l| l.name =~ pattern }
    end

    def color!(name)
      raise "Unknown color #{color}" unless Clubhouse::COLORS[name.to_sym].present?
      self.tap { |l| l.color = Clubhouse::COLORS[name.to_sym] }.save
    end

    def archive!
      self.tap { |l| l.archived = true }.save unless archived?
    end

    def unarchive!
      self.tap { |l| l.archived = false }.save if archived?
    end

    def in_progress?
      stats['num_stories_in_progress'].positive?
    end

    def finished?
      stats['num_stories_in_progress'].zero?
    end
  end

  class Epic < Resource
    has_many :labels

    def archive!
      self.tap { |l| l.archived = true }.save unless archived?
    end

    def unarchive!
      self.tap { |l| l.archived = false }.save if archived?
    end
  end

  class Comment < Resource
  end

  class Story < Resource
    has_many :labels

    def self.all
      raise_unsupported!
    end
  end

  class StorySearch < Resource
    attributes :next, :page_size, :query

    collection_path "search/stories"
  end
end

