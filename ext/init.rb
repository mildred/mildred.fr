# = webgen extensions directory
#
# All init.rb files anywhere under this directory get automatically loaded on a webgen run. This
# allows you to add your own extensions to webgen or to modify webgen's core!
#
# If you don't need this feature you can savely delete this file and the directory in which it is!
#
# The +config+ variable below can be used to access the Webgen::Configuration object for the current
# website.
config = Webgen::WebsiteAccess.website.config


module Webgen

  module Template
  
    attr_reader :context
    
    
    def link_item(path)
      path = path.path if path.kind_of? Webgen::Node
      tag = Webgen::Tag::Link.new
      tag.set_params 'tag.link.path' => path
      tag.call(nil, nil, @context)
    end
  
    # Link a path or a node. If the path is a string, it is not checked to see
    # if it exists. The link is relative.
    def link_path(path)
      path = path.path if path.kind_of? Webgen::Node
      tag = Webgen::Tag::Relocatable.new
      tag.set_params 'tag.relocatable.path' => path
      tag.call(nil, nil, @context)
    end
    
    # Link a path or a node. If the path is a string, it is not checked to see
    # if it exists. The link is absolute.
    def link_absolute(path)
      path = path.path if path.kind_of? Webgen::Node
      Webgen::Node.url(path, true)
    end
    
    def node
      @context.node
    end
    
    def content_node
      @context.content_node
    end
    
    def ref_node
      @context.ref_node
    end
    
    def dest_node
      @context.dest_node
    end
    
    def block(name, attrs = {})
      attrs[:name]     = name.to_s
      unless attrs[:render].nil?
        attrs[:chain] = [attrs[:render]] + @context[:chain][1..-1]
      end
      if attrs[:chain].kind_of?(Array)
        attrs[:chain].map! do |item|
          if item.kind_of? String
            temp_node = @context.ref_node.resolve(item, @context.dest_node.lang)
            if temp_node.nil?
              raise Webgen::RenderError.new("Could not resolve <#{item}>",
                                            self.class.name, @context.dest_node,
                                            @context.ref_node, (options[:line_nr_proc].call if options[:line_nr_proc]))
            end
            temp_node
          else
            item
          end
        end
      end
      attrs[:node]     = attrs[:node].to_s     unless attrs[:node].nil?
      attrs[:notfound] = attrs[:notfound].to_s unless attrs[:notfound].nil?
      block = Webgen::ContentProcessor::Blocks.new
      block.render_block(@context, attrs)
    end
  
  end

end
