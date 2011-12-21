# -*- encoding: utf-8 -*-

require 'webgen/common'
require File.join(File.dirname(__FILE__), 'templateplus')

module Webgen::ContentProcessor

  # Processes content in Haml markup using the +haml+ library.
  class HamlPlus

    # Convert the content in +haml+ markup to HTML.
    def call(context)
      require 'haml'

      locals = {:context => context}
      context.content = ::Haml::Engine.new(context.content, :filename => context.ref_node.alcn).
        render(Webgen::TemplatePlus::Context.new(context), locals)
      context
    rescue LoadError
      raise Webgen::LoadError.new('haml', self.class.name, context.dest_node, 'haml')
    rescue ::Haml::Error => e
      line = if e.line
               e.line + 1
             else
               Webgen::Common.error_line(e)
             end
      raise Webgen::RenderError.new(e, self.class.name, context.dest_node, context.ref_node, line)
    rescue Exception => e
      raise Webgen::RenderError.new(e, self.class.name, context.dest_node,
                                    Webgen::Common.error_file(e), Webgen::Common.error_line(e))
    end

  end

end

config = Webgen::WebsiteAccess.website.config
config['contentprocessor.map']['hamlplus'] = 'Webgen::ContentProcessor::HamlPlus'
