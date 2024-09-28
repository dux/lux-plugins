module Sequel::Plugins::LuxBeforeSave
  module InstanceMethods
    def validate
      return unless defined?(User)

      # timestamps
      self[:created_at] = Time.now.utc if !self.id && respond_to?(:created_at)
      self[:updated_at] = Time.now.utc if respond_to?(:updated_at)
      self[:updated_by] = default_current_user if respond_to?(:updated_by)
      self[:updated_by_ref] = default_current_user if respond_to?(:updated_by_ref)

      if self.id
        Lux.cache.delete "#{self.class}/#{id}"
      else
        self[:created_by] = default_current_user if respond_to?(:created_by)
        self[:created_by_ref] = default_current_user if respond_to?(:created_by_ref)
      end

      super
    end

    def before_destroy
      Lux.cache.delete cache_key
      super
    end

    # overload to return guest user, when needed
    def default_current_user
      if User.current
        User.current.id
      else
        error 'You have to be registered to save data'
        nil
      end
    end
  end
end

# Sequel::Model.plugin :lux_before_save
