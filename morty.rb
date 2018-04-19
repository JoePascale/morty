require "rack"

module Morty
  class Base
      def initialize
        @routes = {}
      end

      attr_reader :routes

      def get(path, &handler)
        route("GET", path, &handler)
      end

      def post(path, &handler)
        route("POST", path, &handler)
      end

      def put(path, &handler)
        route("PUT", path, &handler)
      end

      def patch(path, &handler)
        route("PATCH", path, &handler)
      end

      def delete(path, &handler)
        route("DELETE", path, &handler)
      end

      def call(env)
        @request = Rack::Request.new(env)
        verb = @request.request_method
        requested_path = @request.path_info

        handler = @routes.fetch(verb, {}).fetch(requested_path, nil)

        if handler
          result = instance_eval(&handler)
          if result.class == String
            [200, {}, [result]]
          else
            result
          end
        else
          [404, {}, ["Oops! No route for #{verb} #{requested_path}"]]
        end
      end

      attr_reader :request

      private

      def route(verb, path, &handler)
        @routes[verb] ||= {}
        @routes[verb][path] = handler
      end

      def params
        @request.params
      end
  end

  Application = Base.new

  module Delegator
    def self.delegate(*methods, to:)
      Array(methods).each do |method_name|
        define_method(method_name) do |*args, &block|
          to.send(method_name, *args, &block)
        end

        private method_name
      end
    end

    delegate :get, :patch, :put, :post, :delete, :head, to: Application
  end
end

include Morty::Delegator

require "./morty"

get "/" do
  "Wubba Lubba Dub Dub!!!"
end

get "/fuckrick" do
  "Morty says fuck you Rick"
end

get "/hello" do
  "Morty says 'I guess I'll hang with you Rick'"
end

get "/picklerick" do
  "Morty hates Pickle Rick!!!"""
end

post "/" do
  [200, {}, request.body]
end

Rack::Handler::WEBrick.run Morty::Application, Port: 9292
