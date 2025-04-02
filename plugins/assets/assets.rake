# https://github.com/KaiHotz/react-rollup-boilerplate

require 'digest'

namespace :assets do
  desc 'Build and generate manifest'
  task :compile do
    Lux.run 'rm -rf public/assets'
    Lux.run 'bundle exec lux cerb'
    Lux.run 'npx rollup -c --compact' # --context window

    for css in Dir.files('app/assets').select { |it| it.ends_with?('.css') || it.ends_with?('.scss') }
      # Lux.run "npx node-sass app/assets/#{css} -o public/assets/ --output-style compressed"
      Lux.run "bun x sass app/assets/#{css} public/assets/#{css.sub('.scss', '.css')} -s compressed"
    end

    integrity = 'sha512'
    files     = Dir.entries('./public/assets').drop(2)
    manifest  = Pathname.new('./public/manifestx.json')
    json      = { integrity: {}, files: {} }

    for file in files
      local     = './public/assets/' + file
      sha1      = Digest::SHA1.hexdigest(File.read(local))[0,12]
      sha1_path = file.sub('.', '.%s.' % sha1)

      json[:integrity][file] = '%s-%s' % [integrity, `openssl dgst -#{integrity} -binary #{local} | openssl base64 -A`.chomp]
      json[:files][file] = sha1_path

      Lux.run "cp #{local} ./public/assets/#{sha1_path}"
    end

    manifest.write JSON.pretty_generate(json)

    # Lux.run "gzip -9 -k public/assets/*.*"
    # Lux.run 'ls -lSrh public/assets'

    totals = {}
    Dir['public/assets/*'].each do |file|
      size = File.size(file)

      if file.include?('.gz')
        root = totals[:zip] ||= {}
        if file.include?('.css')
          root[:css] ||= 0
          root[:css] += size
        elsif file.include?('.js')
          root[:js] ||= 0
          root[:js] += size
        end
      else
        root = totals[:raw] ||= {}
        if file.include?('.css')
          root[:css] ||= 0
          root[:css] += size
        elsif file.include?('.js')
          root[:js] ||= 0
          root[:js] += size
        end
      end
    end

    puts 'Assets (photos) totals:'
    totals.each do |kind, type|
      type.each do |ext, size|
        puts "  #{kind} #{ext.to_s.ljust(3)}: #{size.to_filesize}"
      end
    end
  end

  desc 'Install example rollup.config.js, package.json and Procfile'
  task :install do
    src = Lux.fw_root.join('plugins/assets/root')

    for file in Dir.files(src)
      target = Lux.root.join(file)

      print file.ljust(18)

      if target.exist?
        puts ' - exists'
      else
        Lux.run "cp %s %s" % [src.join(file), target]
        puts '-> copied'.green
      end
    end

    puts
    Lux.run 'cat %s' % src.join('Procfile')
  end

  desc 'Development server '
  task :server do

  end
end
