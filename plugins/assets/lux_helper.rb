ApplicationHelper.class_eval do

  def widget name, object=nil, opts=nil
    if object.is_a?(Hash)
      opts = object
    elsif object.is_a?(Sequel::Model)
      # = @project, field: :state_id -> id: 1, model: 'projects', value: 1, field: :state_id
      opts       ||= {}
      opts[:id]    = object.id
      opts[:model] = object.class.to_s
      opts[:table] = object.class.to_s.tableize

      if opts[:field] && opts[:value].nil? && object.respond_to?(opts[:field])
        opts[:value] = object.send(opts[:field])
      end
    end

    tag, name = name.split(':') if name === String

    tag = :div
    id  = Lux.current.uid

    data = block_given? ? yield : nil

    { id: id, 'data-json': opts.to_json }.tag('w-%s' % name, data)
  end

  # swelte widget gets props inline
  def svelte name, opts = {}
    opts[:html] = "#{yield}".chomp if block_given?
    tag = {'data-json-template': true }.tag('s-%s' % name)
    %[<textarea style="display:none">#{opts.to_jsonp.html_safe}</textarea>#{tag}]
  end

  # public asset from manifest
  #   = asset 'domain.css'
  # remote url
  #   = asset 'https://cdnjs.cloudflare.com/ajax/libs/marked/2.1.3/marked.min.js'
  # force css link type
  #   = asset 'https://cdn.com/fooliib', as: :css
  # dynamicly generated from controller
  #   = asset '/assets.js', dynamic: true
  def asset name, opts={}
    if name.include?('//') || name.start_with?('/') || opts.delete(:dynamic)
      asset_tag name, opts
    else
      if name[0,1] == '/'
        name += '?%s' % Digest::SHA1.hexdigest(File.read('./public%s' % name))[0,12]
      else
        name = if Lux.env.dev?
          # do not require asset file to exist if in cli env (console, testing)
          hash_data = Lux.env.cli? ? name : File.read('./public/assets/%s' % name)
          '/assets/%s?%s' % [name, Digest::SHA1.hexdigest(hash_data)[0,12]]
        else
          @json ||= JSON.load File.read('./public/manifestx.json')
          # cloudflare changes files on the fly and fcks up integrity check, have to disable
          # opts[:integrity] = @json['integrity'][name]
          file = @json['files'][name] || die('Asset error: File "%s" not found in manifest' % name)
          '/assets/%s' % file
        end
      end

      if root = Lux.secrets[:assets_root]
        name = [root, name].join
      end

      asset_tag name, opts
    end
  end

  def asset_tag name, opts={}
    opts[:crossorigin] = 'anonymous' if name.include?('http')

    if opts[:as] == :js || name.include?('.js')
      opts[:src] = name
      opts.tag(:script).sub('&lt;script', '<script')
    elsif opts[:as] == :css || name.include?('css')
      opts[:href]    = name
      opts[:media] ||= 'all'
      opts[:rel]   ||= 'stylesheet'
      opts.tag :link
    else
      raise 'Not supported asset extension'
    end
  end

end
