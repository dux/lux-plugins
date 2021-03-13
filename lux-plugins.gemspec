gem_files = [:plugins]
  .inject([]) { |t, el| t + `find ./#{el}`.split($/) }

last_modified = `ls -1rt $(find ./plugins -type f)`.split($/).last

Gem::Specification.new 'lux-plugins' do |gem|
  gem.version     = File.mtime(last_modified).to_i
  gem.summary     = 'Lux plugins by dux'
  gem.description = 'private plugins'
  gem.homepage    = 'http://github.com/dux/lux-plugins'
  gem.license     = 'MIT'
  gem.author      = 'Dino Reic'
  gem.email       = 'rejotl@gmail.com'
  gem.files       = gem_files
end