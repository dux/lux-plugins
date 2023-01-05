# https://sequel.jeremyevans.net/rdoc/classes/Sequel/Database.html

# auto migrate database tables, create tables and fileds, drop if needed
# idea is that cols and actions are executedm only if needed

# db = Sequel.sqlite

# SequelTable db, :customers do
#   col :name, String
#   col :foo, String
#   col :email, type(:email)
# end

# SequelTable.rename_table DB, :customers, :customers2

# SequelTable db, :customers2 do
#   drop :foo
#   col :name_foo, String
#   rename :name, :name2
# end

###

def SequelTable db, table, &block
  st = SequelTable.new db, table
  st.instance_exec &block
  st.summary
end

class SequelTable
  class << self
    # rename table if source exist
    def rename_table db, old_name, new_name
      if db.table_exists?(old_name)
        db.rename_table old_name, new_name
        $stdout.puts "* SequelTable in #{db.opts[:database]} rename #{old_name} to #{new_name}"
      end
    end
  end

  ###

  def initialize db, table
    @db = db
    @table_name = table
    @used_fileds = []

    unless schema_for(:id)
      db.create_table table do
        primary_key :id
      end
    end
  end

  def col field, type, opts = {}
    @used_fileds.push field

    if type.is?(Typero::Type)
      type, db_opts = type.new(nil).db_field
      opts.merge! db_opts
    end

    type = String if type == :string
    type = Integer if type == :integer

    unless schema_for(field)
      @db.add_column @table_name, field, type, opts
      info "DB migrate: Adding field #{field} (#{type})"
    end
  end

  def drop field
    @used_fileds.push field

    if schema_for(field)
      @db.drop_column @table_name, field
      info "DB migrate: Dropping field #{field}"
    end
  end

  def rename filed_from, filed_to
    @used_fileds.push filed_to

    if schema_for(filed_from)
      @db.rename_column @table_name, filed_from, filed_to
      info "DB migrate: Renamed filed from #{filed_from} to #{filed_to}"
    end
  end

  def type name
    Typero.type name
  end

  def summary
    unused = @table_schema.keys - [:id] - @used_fileds

    if unused.first
      info "Unused fileds present in DB -> #{unused.join(', ')}"
    end
  end

  def info text
    $stdout.puts "* SequelTable #{@db.opts[:database]}[#{@table_name}]: #{text}"
  end

  def schema_for name
    @table_schema = @db.schema(@table_name, reload: true).to_h rescue {}
    @table_schema[name]
  end
end

