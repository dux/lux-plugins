# @list = LinkedUser
#   .order(Sequel.desc(:updated_at))
#   .where(user_id: user.id)
#   .limit(20)
#   .all
#   .precache(:job_id)
#   .precache(:org_id)

class Sequel::Model
  module ClassMethods
    def include _
      self.cattr :cache_ttl, nil
      super
    end

    # find will cache all finds in a scope
    def find id
      return nil if id.blank?
      Lux.current.cache("#{self}/#{id}", ttl: cattr.cache_ttl) { self.where(id:id).first }
    end

    # find first and cache it
    def cached_first filter
      where_filter = xwhere filter
      Lux.current.cache(where_filter.sql, ttl: cattr.cache_ttl) { self.where_filter.first }
    end
  end

  module InstanceMethods
    def cache_id full=false
      keys = [self.class, id]
      keys.push self[:updated_at].to_f if full
      keys.join('/')
    end
  end
end

class Array
  # we have to call all on set and then precache
  def precache field, klass=nil
    list = self
      .select{ |it| it && it[field] }
      .map{ |it| it[field] }
      .uniq
      .sort

    klass ||= field.to_s.sub(/_ids?$/, '').classify.constantize

    for el in klass.where(id: list).all
      Lux.current.cache("#{klass}/#{el.id}") { el.dup }
    end

    self
  end
end