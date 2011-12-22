# -*- ruby -*-

$:.unshift File.expand_path(File.join(File.dirname(__FILE__), '..', 'webgen', 'lib'))

#
# This is a sample Rakefile to which you can add tasks to manage your website. For example, users
# may use this file for specifying an upload task for their website (copying the output to a server
# via rsync, ftp, scp, ...).
#
# It also provides some tasks out of the box, for example, rendering the website, clobbering the
# generated files, an auto render task,...
#

require 'webgen/webgentask'
require 'webgen/website'

task :default => :webgen

webgen_config = lambda do |config|
  # you can set configuration options here
end

Webgen::WebgenTask.new do |website|
  website.clobber_outdir = true
  website.config_block = webgen_config
end

desc "Show outdated translations"
task :outdated do
  puts "Listing outdated translations"
  puts
  puts "(Note: Information is taken from the last webgen run. To get the"
  puts "       useful information, run webgen once before this task!)"
  puts

  website = Webgen::Website.new(Dir.pwd, Webgen::Logger.new($stdout), &webgen_config)
  website.execute_in_env do
    website.init
    website.tree.node_access[:acn].each do |acn, versions|
      main = versions.find {|v| v.lang == website.config['website.lang']}
      next unless main
      outdated = versions.select do |v|
         main != v && main['modified_at'] > v['modified_at']
      end.map {|v| v.lang}.join(', ')
      puts "ACN #{acn}: #{outdated}" if outdated.length > 0
    end
  end
end

desc "Render the website automatically on changes"
task :auto_webgen do
  puts 'Starting auto-render mode'
  time = Time.now
  abort = false
  old_paths = []
  Signal.trap('INT') {abort = true}

  while !abort
    # you may need to adjust the glob so that all your sources are included
    paths = Dir['src/**/*'].sort
    if old_paths != paths || paths.any? {|p| File.mtime(p) > time}
      begin
        Rake::Task['webgen'].execute({})
      rescue Webgen::Error => e
        puts e.message
      end
    end
    time = Time.now
    old_paths = paths
    sleep 2
  end
end



########################################
## nanoc ##
###########

require 'nanoc3/tasks'
require 'fileutils'

namespace :create do

  desc "Creates a new article"
  task :article do
    $KCODE = 'UTF8'
    #require 'active_support/core_ext'
    #require 'active_support/multibyte'
    @ymd = Time.now.strftime("%Y-%m-%d")
    @datetime = Time.now.strftime("%F %T %z").gsub(/([0-2][0-9])([0-6][0-9])$/, "\\1:\\2")
    if !ENV['title']
      $stderr.puts "\t[error] Missing title argument.\n\tusage: rake create:article title='article title'"
      exit 1
    end

    title = ENV['title'].capitalize
    path, filename, full_path = calc_path(title)

    if File.exists?(full_path)
      $stderr.puts "\t[error] Exists #{full_path}"
      exit 1
    end

    template = <<TEMPLATE
---
title:      "#{title}"
created_at: #{@datetime}
excerpt:
author:     #{`whoami`.strip.capitalize}
kind:       article
publish:    true
tags:
  - misc
---

TODO: Add content to `#{full_path}.`
TEMPLATE

    FileUtils.mkdir_p(path) if !File.exists?(path)
    File.open(full_path, 'w') { |f| f.write(template) }
    $stdout.puts "\t[ok] Edit #{full_path}"
  end

  def calc_path(title)
    #year, month_day = @ymd.split('-', 2)
    path = "content/Blog/"
    filename = @ymd + "-" + title.tr("A-Z", "a-z").gsub(/[^a-z0-9_-]+/, '_').gsub(/^_*/, "").gsub(/_*$/, "") + ".md"
    [path, filename, path + filename]
  end
end

