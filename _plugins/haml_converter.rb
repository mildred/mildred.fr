# https://gist.github.com/481456

module Jekyll

  class Converter
    attr_accessor :item
  end

  module Convertible
    alias old_transform transform

    def transform(*args)
      converter.item = self
      old_transform(*args)
    end
  end

  require 'haml'
  class HamlConverter < Converter
    safe true
    priority :low

    def matches(ext)
      ext =~ /haml/i
    end

    def output_ext(ext)
      ".html"
    end

    def run(content, item)
      engine = Haml::Engine.new(content)
      engine.render Object.new, :config => @config, :item => item
    end
  end

  require 'sass'
  class SassConverter < Converter
    safe true
    priority :low

    def matches(ext)
      ext =~ /sass/i
    end

    def output_ext(ext)
      ".css"
    end

    def convert(content)
      engine = Sass::Engine.new(content)
      engine.render
    end
  end
end

