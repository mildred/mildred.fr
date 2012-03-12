# = webgen extensions directory
#
# All init.rb files anywhere under this directory get automatically loaded on a webgen run. This
# allows you to add your own extensions to webgen or to modify webgen's core!
#
# If you don't need this feature you can savely delete this file and the directory in which it is!
#
# The +config+ variable below can be used to access the Webgen::Configuration object for the current
# website.

# require 'awesome_print'

config = Webgen::WebsiteAccess.website.config

module Webgen
  class Configuration
    module Helpers

      def pre_exec(commands)
        Dir.chdir(File.join(File.dirname(__FILE__), '..')) do
          commands.each do |cmd|
            puts "Execute #{cmd}"
            system cmd
          end
        end
      end
    
    end
  end
end

require File.join(File.dirname(__FILE__), 'maildir_to_page')

maildir = File.join(File.dirname(__FILE__), "..", "maildir")
outdir  = File.join(File.dirname(__FILE__), "..", "src", "Blog")

maildir_to_page(maildir, outdir, "%Y-%m-%d-%%s.page")




