module Lux
  class Error
    module Logger
      extend self

      ERROR_FOLDER ||= './log/exceptions'

      def log exception
        return if Lux.env == 'test'
        return unless Lux.current
        return if exception.class.to_s == 'DebugRaiseError'

        history = exception.backtrace || []
        history = history
          .map{ |el| el.sub(Lux.root.to_s, '') }
          .join("\n")

        key  = Digest::SHA1.hexdigest history

        data = '%s in %s (user: %s, time: %s)' % [exception.class, Lux.current.request.url, (Lux.current.var.user.email rescue 'guest'), Time.now.long]
        data = [data, 'REFER: %s' % Lux.current.request.env['HTTP_REFERER'].or(':unknown'), exception.message, history].join("\n\n")

        folder = Lux.root.join('log/exceptions').to_s
        Dir.mkdir(folder) unless Dir.exists?(folder)

        File.write("#{folder}/#{key}.txt", data)

        Lux.logger(:exceptions).error [key, User.current.try(:email).or('guest'), exception.message].join(' - ')

        key
      end

      def list
        error_files = Dir['%s/*.txt' % ERROR_FOLDER].sort_by { |x| File.mtime(x) }.reverse

        error_files[0, 100].map do |file|
          last_update = (Time.now - File.mtime(file)).to_i

          age = if last_update < 60
            '%s sec ago' % last_update
          elsif last_update < 60*60
            '%s mins ago' % (last_update/60).to_i
          elsif last_update < 60*60*24
            '%s hours ago' % (last_update/(60*60)).to_i
          else
            '%s days ago' % (last_update/(60*60*24)).to_i
          end

          {
            file: file,
            last_update: last_update,
            desc: File.read(file).split("\n").first,
            code: file.split('/').last.split('.').first,
            age: age
          }
        end
      end

      def get code
        for el in list
          return el if el[:code] == code
        end
      end

      def clear
        system 'rm -rf "%s"' % ERROR_FOLDER
      end

      def load code
        file = get(code)[:file]
        File.read(file)
      end
    end
  end
end

Lux.config.error_logger = Proc.new do |error|
  if Lux.env.dev?
    ap [error.message, error.class, Lux::Error.mark_backtrace(error)]
  end

  Lux::Error::Logger.log error
end

