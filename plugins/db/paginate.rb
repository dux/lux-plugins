module HtmlHelper
  extend self

  # paginate @list, first: 1
  def paginate list, in_opts = {}
    in_opts[:first] ||= '&bull;'

    if list.is_a?(Hash)
      opts = list
    else
      return unless list.respond_to?(:paginate_next)

      opts = {
        param: list.paginate_param,
        page:  list.paginate_page,
        next:  list.paginate_next
      }
    end

    return nil if opts[:page].to_i < 2 && !opts[:next]

    ret = ['<div class="paginate"><div>']

    if opts[:page] > 1
      url = Url.current
      opts[:page] == 1 ? url.delete(opts[:param]) : url.qs(opts[:param], opts[:page]-1)
      ret.push %[<a href="#{url.relative}">&larr;</a>]
    else
      ret.push %[<span>&larr;</span>]
    end

    ret.push %[<i>#{opts[:page] == 1 ? in_opts[:first] : opts[:page]}</i>]

    if opts[:next]
      url = Url.current
      url.qs(opts[:param], opts[:page]+1)
      ret.push %[<a href="#{url.relative}">&rarr;</a>]
    else
      ret.push %[<span>&rarr;</span>]
    end

    ret.push '</div></div>'
    ret.join('')
  end

end

###

Sequel::Model.db.extension :pagination

Sequel::Model.dataset_module do
  def page size: 20, param: :page, page: nil, count: nil
    page = Lux.current.params[param] if Lux.current.params[param].respond_to?(:to_i)
    page = page.to_i
    page = 1 if page < 1

    # ret = paginate(page, size).all
    ret = offset((page-1) * size).limit(size+1).all

    has_next = ret.length == size + 1
    ret.pop if has_next

    ret.define_singleton_method(:paginate_param) do; param ;end
    ret.define_singleton_method(:paginate_page)  do; page; end
    ret.define_singleton_method(:paginate_next)  do; has_next; end
    ret.define_singleton_method(:paginate_opts)  do; ({ param: param, page: page, next: has_next }); end
    ret
  end
end
