# auto migrate database tables, create tables and fileds, drop if needed

# SequelTable db, :customers do
#   col :name, String
#   col :email, type(:email)
#   drop :foo
# end

###

# def SequelTable db, table, &block
#   st = SequelTable.new db, table
#   st.instance_exec &block
#   st.summary
# end

# class SequelTable
#   def initialize db, table
#     @db = db
#     @table_name = table
#     @table_schema = db.schema(table).to_h rescue nil
#     @used_fileds = []

#     unless @table_schema
#       db.create_table table do
#         primary_key :id
#       end

#       @table_schema = db.schema(table).to_h
#     end
#   end

#   def col field, type, opts = {}
#     @used_fileds.push field

#     if type.is?(Typero::Type)
#       type, db_opts = type.new(nil).db_field
#       opts.merge! db_opts
#     end

#     type = String if type == :string
#     type = Integer if type == :integer

#     unless @table_schema[field]
#       @db.add_column @table_name, field, type, opts
#       info "DB migrate: Adding field #{field} (#{type})"
#     end
#   end

#   def drop field
#     @used_fileds.push field

#     if @table_schema[field]
#       @db.drop_column @table_name, field
#       info "DB migrate: Dropping field #{field}"
#     end
#   end

#   def type name
#     Typero.type name
#   end

#   def summary
#     unused = @table_schema.keys - [:id] - @used_fileds

#     if unused.first
#       info "Unused fileds present in DB -> #{unused.join(', ')}"
#     end
#   end

#   def info text
#     $stdout.puts "* SequelTable #{@db.opts[:database]}[#{@table_name}]: #{text}"
#   end
# end
