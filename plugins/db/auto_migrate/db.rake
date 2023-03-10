def db_backup_file_location args
  folder = './tmp/db_dump'
  Dir.mkdir(folder) unless Dir.exist?(folder)
  name = args[:name] || Lux.config.db_url.split('/').last
  "%s/%s.sql" % [folder, name]
end

def load_file file, external: false
  info = 'auto_migrate: %s' % file

  if !File.exist?(file)
    info += ' (skipping)'
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
    invoke 'db:create'
    Lux.run 'psql %s < %s' % [db_name, sql_file]
  end

  desc 'Reset database from db/seed.sql'
  task :reset, [:fast] do |_, args|
    if args.fast
      DB.disconnect
      run "dropdb #{db_name}"
      run "createdb #{db_name} -T #{db_name}_test"
    else
      invoke 'db:drop'
      invoke 'db:create'
      invoke 'db:am'

      DB.disconnect
      run 'rake db:am'
      run "createdb #{db_name}_test -T #{db_name}"
    end
  end

  desc 'Load seed from ./db/seeds '
  task seed: :app do
    print "This will destroy all local data and import seeds.\nProceed ? "
    exit unless $stdin.gets.chomp.downcase == 'y'

    all_tables = "SELECT table_name FROM information_schema.tables WHERE table_schema NOT IN ('pg_catalog', 'information_schema') and table_type='BASE TABLE' and table_name not in ('spatial_ref_sys')"
    DB[all_tables].all.map{|el| DB['delete from %s' % el[:table_name]].all }

    load_file './db/seeds.rb'

    for file in Dir['db/seeds/*'].sort
      puts 'Seed: %s' % file.green
      load file
    end
  end

  desc 'Create database'
  task :create do
    Lux.run "createdb #{db_name}"
    # Lux.run "createdb #{db_name}_test"
  end

  desc 'Drop database'
  task :drop do
    DB.disconnect
    Lux.run "dropdb #{db_name}"
    Lux.run "dropdb #{db_name}_test"
  end

  desc 'Run PSQL console'
  task :console do
    system "psql '%s'" % Lux.config.db_url
  end

  desc 'Automigrate schema'
  task am: :env do
    class Object
      def self.const_missing klass, path=nil
        eval 'class ::%s; end' % klass,  __FILE__, __LINE__
        Object.const_get(klass)
      end
    end

    Lux.config.migrate = true

    load '%s/auto_migrate/auto_migrate.rb' % Lux.plugin(:db).folder

    # Sequel extension and plugin test
    DB.run %[DROP TABLE IF EXISTS lux_tests;]
    DB.run %[CREATE TABLE lux_tests (int_array integer[] default '{}', text_array text[] default '{}');]
    class LuxTest < Sequel::Model; end;
    LuxTest.new.save
    die('"DB.extension :pg_array" not loaded') unless LuxTest.first.int_array.class == Sequel::Postgres::PGArray
    DB.run %[DROP TABLE IF EXISTS lux_tests;]

    load_file './db/before.rb'
    load_file './db/auto_migrate.rb'

    klasses = Typero.schema(type: :model) || raise(StandardError.new('Typero schemas not loaded'))

    for klass in klasses
      Typero::AutoMigrate.typero klass
    end

    load_file './db/after.rb', external: true
  end
end
