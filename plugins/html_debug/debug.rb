module Lux
  class Template
    def self.wrap_with_debug_info files, data
      return data unless Lux.current.request.env['QUERY_STRING'].include?('debug=render')

      files = [files] unless files.is_a?(Array)
      files = files.compact.map do |file|
        file, prefix = file.sub(/'$/, '').sub(Lux.root.to_s, '.').split(':in `')
        prefix = ' # %s' % prefix if prefix

        %[<a href="subl://open?url=file:/%s" style="color: #fff;">%s%s</a>] % [Url.escape(Lux.root.join(file).to_s), file.split(':').first, prefix]
      end.join(' &bull; ')

      Lux::DebugPlugin.wrap files, data
    end
  end
end

# HTML helpers
module ApplicationHelper
  def debug_toggle
    return if Lux.env.production?

    opts = {
      id: 'debug-toggle',
      style: 'position: fixed; right: 6px; top: 5px; text-align: right; z-index: 100;',
    }
    if current.request.env['QUERY_STRING'].include?('debug=render')
      opts.merge({
        class: 'direct btn btn-xs btn-primary',
        href: Url.qs(:debug, nil)
      }).tag(:a, '-')
    else
      opts.merge({
        id: 'debug-toggle',
        class: 'direct btn btn-xs',
        href: Url.qs(:debug, :render),
      }).tag(:a, '+')
    end
  end

  def files_in_use
    return unless Lux.config.auto_code_reload

    files = Lux.current.files_in_use.map do |file|
      if file[0,1] == '/'
        nil
      else
        file = Lux.root.join(file).to_s
        name = file.split(Lux.root.to_s+'/').last.sub(%r{/([^/]+)$}, '/<b>\1</b>')
        %[<a class="btn btn-xs" href="subl://open?url=file://#{CGI::escape(file.to_s)}">#{name}</a>]
      end
    end.compact

    Lux::DebugPlugin.wrap
    %[<div style="position: fixed; right: 6px; top: 5px; text-align: right; z-index: 100;">
      <button class="btn btn-xs" onclick="$('#lux-open-files').toggle();" style="padding:0 4px;">+</button>
      <div id="lux-open-files" style="display:none; background-color:#fff;">#{files.join('<br />')}</div>
    </div>]
  end
end

module Lux::DebugPlugin
  extend self

  def render *args, &block
    Lux::Template.wrap_with_debug_info @template, super
  end

  def wrap title, body, opts = {}
    opts[:color] ||= '#fff'
    opts[:bgcolor] ||= '#800'

    %[<div style="border: 1px solid #{opts[:bgcolor]}; margin: 3px; padding: 35px 5px 5px 5px;">
        <span style="position: absolute; background: #{opts[:bgcolor]}; color: #{opts[:color]}; font-weight: 400; font-size: 15px; margin: -36px 0 0 -5px; padding: 2px 5px;">#{title}</span>
        #{body}
    </div>]
  end

  # Lux::DebugPlugin.edit method(target).source_location
  def edit file, title = nil
    if file.class == Array
      file = file.join(':')
    end

    unless file.starts_with?('/')
      file = Lux.root.join(file).to_s
    end

    title ||= file
    title = title.sub(Lux.root.to_s, '.')

    # find location of method in a file
    # /file/location.rb#some_method
    if file.include?('#')
      file, method_name = file.split('#')

      data  = File.read(file)
      parts = data.split(/def\s#{method_name}\s/)
      parts = data.split(/def\sself\.#{method_name}\s/) unless parts[1]

      if parts[1]
        file += ':%s' % (parts[0].split($/).length)
      end
    end

    %[<a href="subl://open?url=file:/%s:104" style="color: #fff;">%s</a>] % [Url.escape(file), title]
  end
end

if Lux.env.dev?
  Lux::Template.prepend Lux::DebugPlugin
end
