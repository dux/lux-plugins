# lnk models AR style

module Sequel::Plugins::LuxLinks
  LUX_REF_CACHE_CLEAR ||= {}

  module ClassMethods
    def ref name, opts = {}
      opts = opts.to_hwia :class, :field, :cache

      if name.class != Symbol
        # OrgUser.ref(@org) - @org_user.org_ref = @org.ref
        f = "#{name.class.to_s.underscore}_ref".to_sym
        if db_schema[f]
          where(f => name.id)
        else
          # Comment.ref(@task) - @comment.parent_ref = @task.ref
          where(parent_ref: name.ref)
        end
      else
        name = name.to_s
        klass = opts[:class] ? opts[:class].to_s : name.to_s.singularize.classify
        field = (opts[:field] || "#{name}_ref").to_s

        if name == name.singularize
          # ref :user (user_ref)
          field = db_schema[field.to_sym] ? field : :parent_ref
          class_eval <<-STR, __FILE__, __LINE__ + 1
            def #{name}
              #{klass}.find(#{field})
            end
          STR
        else
          field = "#{name.to_s.singularize}_refs".to_sym

          if db_schema[field.to_sym]
            # ref :users (user_refs [])
            class_eval <<-STR, __FILE__, __LINE__ + 1
              def #{name}
                #{field}.or([]).map { #{klass}.find(_1) }
              end
            STR
          else
            host = name.classify.constantize
            LUX_REF_CACHE_CLEAR[host.to_s] ||= []
            LUX_REF_CACHE_CLEAR[host.to_s].push to_s.underscore

            # filed = host.respond_to?("#{self.to_s.underscore}_ref") : "#{self.to_s.underscore}_ref" : :parent_ref

            # Org.ref :projects -> @org.projects
            action_field = "#{self.to_s.underscore}_ref".to_sym
            action =
            if host.db_schema[action_field]
              "#{klass}.default.where(#{action_field}: ref)"
            else
              "#{klass}.default.where(parent_ref: key)"
            end
            # ap [to_s, name, action_field, action].join(' - ')
            class_eval <<-STR, __FILE__, __LINE__ + 1
              def #{name}
                #{action}
              end
            STR
          end
        end
      end
    end

    # Object.genders
    # @object.gender
    def link name, opts = {}
      opts = opts.to_hwia :class, :polymorphic, :field

      name_s = name.to_s.singularize
      name_p = name.to_s.pluralize

      klass = opts[:class] ? opts[:class].to_s : name.to_s.singularize.classify

      opts.field ||= '%s_id' % name_s

      # link :country, class: Country -> many_to_one :country
      if name.to_s == name_s
        class_eval %[
          def #{name_s}
            @#{name_s}_cached ||= #{klass}.find(#{opts.field})
          end
          def #{name_s}=(object)
            self[:#{opts.field}] = object.id
            @#{name_s}_cached = object
          end
          def #{opts.field.to_s.sub(/_id$/, '_sid')}= sid
            self.#{opts.field} = sid.present? ? sid.string_id : nil
          end
        ]

      # link :cities
      # postgre integer array, has to be in form #{name.singularize}_ids
      # city_ids = [1,2,4]
      # cities -> [<City:1>, <City:2>, <City:4>]
      elsif db_schema["#{name_s}_ids".to_sym]
        # puts "* #{to_s}.link :#{name} -> inline #{name_s}_ids".yellow
        class_eval %[
          def #{name_p}
            return [] if #{name_s}_ids.blank?
            ids = #{name_s}_ids.uniq

            if !ids.first
              []
            elsif !ids[1]
              [#{klass}.find(ids.first)]
            else
              #{klass}.where(Sequel.lit('id in ('+ids.join(',')+')')).default.all
            end
          end
        ]

      # link :users, class: OrgUser -> OrgUser.where(org_id)
      # elsif opts[:class]
      #   class_eval %[
      #     def #{name_p}
      #       #{comm}
      #     end
        # ]

      # link :countries -> one_to_many :countries
      else
        # one_to_many name, opts
        field = "#{to_s.tableize.singularize}_id"

        if poly = opts[:polymorphic]
          if klass.constantize.db_schema[:parent_type]
            comm = "#{klass}.where(parent_type: '#{to_s}', parent_id: id).default"
          else
            comm = "#{klass}.where(model_type: '#{to_s}', model_id: id).default"
          end
        elsif klass.constantize.db_schema[field.to_sym]
          comm = "#{klass}.where(#{field}:id).default"
        else
          # we have a link table
          cname = klass[0,1] > to_s[0,1] ? "#{to_s}#{klass}" : "#{klass}#{to_s}"

          die "Link field/table not found for #{to_s}.link :#{name}" unless const_defined?(cname)

          comm = "#{klass}.default.xwhere('id in (select #{klass.tableize.singularize}_id from #{cname.tableize} where #{to_s.tableize.singularize}_id=?)', id)"
          # puts "* #{to_s}.link :#{name} -> #{comm}"
        end

        class_eval %[
          def #{name_p}
            #{comm}
          end
        ]
      end
    end
  end

  module InstanceMethods
    def after_create
      _lux_refs_update_counts
      super
    end

    def after_save
      _lux_refs_clear_cache
      super
    end

    def after_destroy
      _lux_refs_clear_cache
      _lux_refs_update_counts
      super
    end

    def _lux_refs_clear_cache
      for o in (LUX_REF_CACHE_CLEAR[self.class.to_s] || [])
        if respond_to?(o)
          # clears cache in linked objects
          # Project.ref :tasks
          # @task.update -> Lux.cache.delete(@task.project.cache_key/tasks)
          # project.update tasks_count: project.tasks.count
          target = send(o)
          key = [target.key, self.class.to_s.underscore.pluralize].join('/')
          Lux.cache.delete key
        end
      end
    end

    def _lux_refs_update_counts
      if respond_to?(:parent_key)
        plural = self.class.to_s.tableize
        count_field = "#{plural}_count"
        if parent.respond_to?(count_field) && parent.respond_to?(plural)
          parent.this.update count_field => parent.send(plural).count
        end
      end

      for o in (LUX_REF_CACHE_CLEAR[self.class.to_s] || [])
        if respond_to?(o)
          # update counts
          # Project.ref :tasks -> update @project.tasks_count when task changes (if exists)
          target = send(o)
          plural = self.class.to_s.tableize
          count_key = "#{plural}_count"
          if target.respond_to?(count_key)
            target.this.update count_key => target.send(plural).count
          end
        end
      end
    end
  end
end

# Sequel::Model.plugin :lux_links
