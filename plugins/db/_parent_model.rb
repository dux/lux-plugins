# parent_key
# parent_type & parent_id

module Sequel::Plugins::ParentModel
  module InstanceMethods
    # apply parent attributes
    def parent= model
      if db_schema[:parent_key]
        if model.is_a?(String)
          if model.include?('/')
            self[:parent_key] = model
          else
            raise ArgumentErorr.new('Parent key is missing /')
          end
        else
          self[:parent_key] = '%s/%s' % [model.class, model.id]
        end
      else
        self[:parent_type] = model.class.to_s
        self[:parent_id] = model.id
      end
    end

    # @board.parent -> @list
    def parent
      if key = self[:parent_key]
        key = key.split('/')
        key[0].constantize.find(key[1])
      elsif key = self[:parent_type]
        key.constantize.find(self[:parent_id])
      else
        raise ArgumentError, '%s parent key not found.' % self.class
      end
    end

    # check if parent is present
    def parent?
      db_schema[:parent_key] || (db_schema[:parent_id] && db_schema[:parent_id])
    end
  end

  # Favorite.for_parent(@cards) -> cards in favorites
  module ClassMethods
    def for_parent object
      if key = db_schema[:parent_key]
        where(parent_key: '%s/%d' % [object.class.to_s, object.id])
      elsif key = db_schema[:parent_type]
        where(parent_id: object.id, parent_type: object.class.to_s)
      else
        raise ArgumentError, 'parent key not found'
      end
    end
  end
end

# Sequel::Model.plugin :parent_model
