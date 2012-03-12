#!/usr/bin/env ruby

require 'mail'

def maildir_to_page(maildir, outdir, filename_template)
  return unless File.directory? maildir
  throw Exception unless File.directory? outdir
  outdir = File.expand_path outdir
  Dir.chdir(maildir) do
    Dir["./{new,cur}/*"].delete_if { |f| f == '.' or f == '..' }.each do |f|
      mail = Mail.read f
      title = mail.subject.tr("A-Z", "a-z").gsub(/[^a-z0-9_-]+/, '_').gsub(/^_*/, "").gsub(/_*$/, "")
      filename = mail.date.strftime(filename_template) % [title]
      meta = {
        'title'      => mail.subject,
        'created_at' => mail.date,
        'author'     => mail.sender,
        'kind'       => 'article',
        'publish'    => true,
        'tags'       => []}
      if mail.multipart? then
        message_parts = mail.parts.select { |p| p.class == Mail::Part }
        body = message_parts.select{ |p| p.content_type =~ /^text\/plain/ }.map { |p| p.body.decoded }.join '\n'
      else
        body = mail.body.decoded
      end
      template = "#{YAML::dump(meta)}\n--- name:excerpt\nTODO\n--- name:content\n#{body}"
      # TODO: do not override file
      File.open(File.join(outdir, filename), 'w') { |fh| fh.write(template) }
    end
  end
end


