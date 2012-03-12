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
      filename = File.join(outdir, filename)
      # TODO: if the file already exists, check that it has the same mesage-id
      # TODO: else, reply saying the message could not be processed.
      next if File.exist? filename
      meta = {
        'title'      => mail.subject,
        'created_at' => mail.date,
        'kind'       => 'article',
        'publish'    => true,
        'tags'       => [],
        'message_id' => mail.message_id}
      from = mail['from'].decoded
      m = from.match /^(.*)\s+<(.*)>$/
      if m then
        meta['author'] = m[1]
        meta['author_email'] = m[2]
      else
        meta['author'] = from
      end
      if mail.multipart? then
        message_parts = mail.parts.select { |p| p.class == Mail::Part }
        body = message_parts.select{ |p| p.content_type =~ /^text\/plain/ }.map { |p| p.body.decoded }.join '\n'
      else
        body = mail.body.decoded
      end
      # Merge meta from body
      body.lstrip!
      if body.start_with? "---\n"
        begin
          head = YAML::load(body)
        rescue
        else
          meta.merge! head
          m = body[4..-1].match(/^---(\s+.*)?$/)
          body = if m then body[4+m.begin(0)..-1] else "" end
        end
      end
      # Body
      body = "---\n" + body unless body.start_with? "--- " or body.start_with? "---\n"
      template = YAML::dump(meta) + body
      File.open(filename, 'w') { |fh| fh.write(template) }
    end
  end
end


