#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

require 'mail'
require 'fileutils'
require 'optparse'
require 'yaml'

$dir = File.join(FileUtils.pwd, "src", "Blog")
$outtmpl = "%Y-%m-%d-%%s.page"

OptionParser.new do |o|
  o.on('-dir DIR')       { |dir|  $dir     = dir  }
  o.on('-file FILETMPL') { |file| $outtmpl = file }
  o.on('-h')             { puts o; exit }
  o.parse!
end

def file_content(mail)
  meta = {
    'title'      => mail.subject,
    'created_at' => mail.date.to_time,
    'kind'       => 'article',
    'publish'    => true,
    'message_id' => mail.message_id}

  meta.merge! meta_author(mail['from'].decoded)
  body = mail_body(mail)
  body = body_meta(body) { |head| meta.merge! head }

  body = "---\n" + body unless body.start_with? "--- " or body.start_with? "---\n"
  return YAML::dump(meta) + body
end

def meta_author(from)
  m = from.match /^(.*)\s+<(.*)>$/
  meta = {}
  if m then
    meta['author'] = m[1]
    meta['author_email'] = m[2]
  else
    m = from.match /^\s*((.*)@.*)\s*$/
    if m then
      meta['author'] = m[0].capitalize
      meta['author_email'] = m[1]
    else
      meta['author'] = from
    end
  end
  return meta
end

def mail_body(mail)
  if mail.multipart? then
    message_parts = mail.parts.select { |p| p.class == Mail::Part }
    body = message_parts.select{ |p| p.content_type =~ /^text\/plain/ }.map { |p| p.body.decoded }.join '\n'
  else
    body = mail.body.decoded
  end
  body.lstrip
end

def body_meta(body, &block)
  if body.start_with? "---\n"
    begin
      head = YAML::load(body)
    rescue Exception
    else
      block.call(head)
      m = body[4..-1].match(/^---(\s+.*)?$/)
      body = if m then body[4+m.begin(0)..-1] else "" end
    end
  end
  body
end

$stdin.binmode
mail = Mail.read_from_string($stdin.read())
title = mail.subject.tr("A-Z", "a-z").gsub(/[^a-z0-9_-]+/, '_').gsub(/^_*/, "").gsub(/_*$/, "")
filepath = File.join($dir, mail.date.strftime($outtmpl) % [title])
if File.exists? filepath
  warn "#{filepath}: overriding existing file"
end
File.open(filepath, 'w') do |f|
  f.write(file_content(mail))
end
Dir.chdir(File.dirname(filepath)) do
  f = File.basename(filepath)
  system "git", "add", "--", f
  system "git", "commit", "-m", "Automatically add #{f}", "--", f
  system "git", "push"
end

