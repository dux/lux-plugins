Sequel::Model.dataset_module do
  # only postgree
  # Bucket.can.all_tags -> all_tags mora biti zadnji
  def all_tags field = :tags, *args
    sqlq = sql.split(' FROM ')[1]
    sqlq = "select lower(unnest(#{field})) as tag FROM " + sqlq
    sqlq = "select tag as name, count(tag) as cnt from (#{sqlq}) as tags group by tag order by cnt desc"
    DB.fetch(sqlq).map(&:to_hwia).or([])
  end

  # were users.id in (select unnest(user_ids) from doors)
  # def where_unnested klass
  #   target_table = klass.to_s.tableize
  #   where("#{table_name}.id in (select unnest(#{table_name.singularize}_ids) from #{target_table})")
  # end
  # assumes field name is tags
  # Example: Job.where_any(@location.id, :location_ids).count
  def where_any data, field = :tags
    if data.present?
      data = [data] unless data.is_a?(Array)

      xwhere(data.map do |what|
        what = what.to_s.gsub(/[^\w\-]+/, '')
        "'#{what}'=any(#{field})"
      end.join(' or '))
    else
      self
    end
  end
end

