def db_backup_file_location args
  folder = './tmp/db_dump'
  Dir.mkdir(folder) unless Dir.exist?(folder)
  name = args[:name] || Lux.config.db_url.split('/').last
  "%s/%s.sql" % [folder, name]
end

def load_file file, external: false
  info = 'auto_migrate: %s' % file

  if !File.exist?(file)
    if block_given?
      yield
    else
      info += ' (skipping)'
    end

    Lux.info info
  elsif external
    Lux.info info
    Lux.run "bundle exec lux e #{file}"
  else
    Lux.info info
    load file
  end
end

db_name = Lux.config.db_url.split('/').last

###

namespace :db do
  desc 'Dump/backup database backup'
  task :dump, [:name] => :env do |_, args|
    sql_file = db_backup_file_location args

    Lux.run "pg_dump --no-privileges --no-owner --no-reconnect #{Lux.config.db_url} > #{sql_file}"
    system 'ls -lh %s' % sql_file
  end

  desc 'Restore database backup'
  task :restore, [:name] => :env do |_, args|
    sql_file = db_backup_file_location args

    invoke 'db:drop'
    # invoke 'db:create'
    Lux.run 'psql %s < %s' % [db_name, sql_file]
  end

  desc 'Reset database from db/seed.sql'
  task :reset, [:fast] do |_, args|
    invoke 'db:drop'
    run 'rake db:am'
    run 'rake db:am'
  end

  desc 'Drop database'
  task :drop do
    Lux.run "DB_DROP=true lux e 1"
  end

  # desc 'Create datebase'
  # task :create do

  # end

  desc 'Run PSQL console'
  task :console do
    system "psql '%s'" % Lux.config.db_url
  end

  desc 'Automigrate schema'
  task am: :env do
    ENV['DB_MIGRATE'] = 'true'

    load '%s/auto_migrate/auto_migrate.rb' % Lux.plugin(:db).folder

    # Sequel extension and plugin test
    DB.run %[DROP TABLE IF EXISTS lux_tests;]
    DB.run %[CREATE TABLE lux_tests (int_array integer[] default '{}', text_array text[] default '{}');]
    class LuxTest < Sequel::Model(DB); end;
    LuxTest.new.save
    die('"DB.extension :pg_array" not loaded') unless LuxTest.first.int_array.class == Sequel::Postgres::PGArray
    DB.run %[DROP TABLE IF EXISTS lux_tests;]

    load_file './db/before.rb'
    load_file './db/auto_migrate.rb'

    klasses = Typero.schema(type: :model) || raise(StandardError.new('Typero schemas not loaded'))

    for klass in klasses
      AutoMigrate.apply_schema klass
    end

    load_file './db/after.rb', external: true
  end

  desc 'Load seed from ./db/seeds '
  task :seed do
    # run 'rake db:reset'

    require './config/app'

    load_file './db/seeds.rb' do
      for file in Dir['db/seeds/*'].sort
        puts 'Seed: %s' % file.green
        load file
      end
    end
  end

  # rake db:gen_seeds[site]
  # Site.create({
  #   name: "Main site",
  #   org_id: @org.id
  # })
  desc 'Generate seeds'
  task :gen_seeds, [:klass] => :env do |_, args|
    Lux.die 'arguemnt not given => rake db:gen_seeds[model]' unless args[:klass]

    klass = args[:klass].classify.constantize
    data = klass.limit(100).all.map(&:seed)
      .join("\n\n")
      .gsub(/(\w+)_id:\s\d+/) {|el| "#{$1}_id: @#{$1}.id" }

    puts data
  end
end
