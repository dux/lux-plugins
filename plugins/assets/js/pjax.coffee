# Pjax will replace only contents of MAIN HTML tag
# HTML <main> Tag
# https://www.w3schools.com/tags/tag_main.asp

# How to use?

# Pjax.captureOnClick()
# Pjax.error = (msg) -> Info.error msg
# Pjax.before ->
#
#   Dialog.close()
#   InlineDialog.close()
# Pjax.after ->
#   Dialog.close() if window.Dialog
# Pjax.load('/users/new', no_history: bool, no_scroll: bool, done: ()=>{...})

# to refresh link in container, pass current node and have ajax node ready, with id and path
# .ajax{ id: :foo, path: '/some_dialog_path' }
#   ...
#   .div{ onclick: Pjax.load('?q=search_term', node: this) }

# opts: {
#   path: what path to load
#   replacePath: path to replace path with (on ajax state change, to have back button on different path)
#   done: function to execute on done
#   node: dom node to refresh, finds closest ajax node
#   scroll: set to false if you want to have no scroll (default for Pjax.refresh)
#   history: set to false if you dont want to add state change to history
#   cache: set to false if you want to force no-cache header
# }

window.Pjax = class Pjax
  @config = {
    # shoud Pjax log info to console
    is_silent      : parseInt(location.port) < 1000,

    # do not scroll to top, use refresh() and not reload() on node with selectors
    no_scroll_selector : ['.no-scroll'],

    # skip pjax on followin links and do location.href = target
    # you can add function, regexp of string (checks for starts with)
    paths_to_skip  : [],

    # if link has any of this classes, Pjax will be skipped and link will be followed
    # Example: %a.direct{ href: '/somewhere' } somewhere
    no_pjax_class  : ['no-pjax', 'direct'],

    # if parent id found with ths class, ajax response data will be loaded in this class
    # you can add ID for better targeting. If no ID given to .ajax class
    #  * if response contains .ajax, first node found will be selected and it innerHTML will be used for replacement
    #  * if there is no .ajax in response, full page response will be used
    # Example: all links in "some_template" will refresh ".ajax" block only
    # .ajax
    #   = render 'some_template'
    ajax_selector  : '.ajax',
  }

  # you have to call this if you want to capture clicks on document level
  # Example: Pjax.onDocumentClick()
  @onDocumentClick: ->
    document.addEventListener 'click', PjaxOnClick.main

  # base class method to load page
  # no_history: bool
  # no_scroll: bool
  # done: ()=>{...}
  @load: (href, opts) ->
    opts = @getOpts href, opts
    @fetch(opts)

  # refresh page, keep scroll
  @refresh: (func, opts) ->
    opts = @getOpts func, opts
    opts.no_scroll = true
    @fetch(opts)

  # reload, jump to top, no_cache http request forced
  @reload: (opts) ->
    opts = @getOpts opts
    opts.no_cache = true
    @fetch(opts)

  # normalize options
  @getOpts = (path, opts) ->
    opts ||= {}

    opts.no_scroll  = true if opts.scroll == false
    opts.no_history = true if opts.history == false
    opts.no_cache   = true if opts.cache == false

    if typeof(path) == 'object'
      if path.nodeName
        opts.node = path
      else
        opts = path
    else if typeof(path) == 'function'
      opts.done = path
    else
      opts.path = path

    if opts.href
      opts.path = opts.hred
      delete opts.href

    opts.path ||= @path()

    if opts.node && !opts.node.className.includes('ajax-skip') && !opts.node.className.includes('skip-ajax')
      ajax_node = opts.node.closest(Pjax.config.ajax_selector)
      delete opts.node

      if ajax_node
        opts.ajax_node = ajax_node
        opts.no_scroll = true unless opts.no_scroll?
        opts.no_history = true unless opts.no_history?

    if opts.path[0] == '?'
      # if href starts with ?
      if opts.ajax_node
        # and we are in ajax node
        ajax_path = opts.ajax_node.getAttribute('data-path') || opts.ajax_node.getAttribute('path')

        if ajax_path
          # and ajax path is defined, use it to create full url
          opts.path = ajax_path.split('?')[0] + opts.path

      if opts.path[0] == '?'
        # if not modified, use base url
        opts.path = location.pathname + opts.path

    if opts.replacePath
      if opts.replacePath[0] == '?'
        opts.replacePath = location.pathname + path

    opts

  @fetch: (opts) ->
    pjax = new Pjax(opts)
    pjax.load()

  # used to get full page path
  @path: ->
    location.pathname+location.search

  @node: ->
    document.getElementsByTagName('pjax')[0] || document.getElementsByClassName('pjax')[0] || alert('.pjax or #pjax not found')

  @console: (msg) ->
    unless @config.is_silent
      console.log msg

  # execute action before pjax load and do not proceed if return is false
  # example, load dialog links inside the dialog
  # Pjax.before (href, opts) ->
  #   if opts.node
  #     if opts.node.closest('.in-popup')
  #       Dialog.load href
  #       return false
  #   true
  @before: (func) ->
    true

  # execute action after pjax load
  @after: (func) ->
    true

  # error logger, replace as fitting
  @error: (msg) ->
    console.error "Pjax error: #{msg}"

  # internal to check scripts
  @parseScripts: () ->
    for script_tag in Pjax.node().getElementsByTagName('script')
      unless script_tag.getAttribute('src')
        type = script_tag.getAttribute('type') || 'javascript'

        if type.indexOf('javascript') > -1
          func = new Function script_tag.innerText
          func()
          script_tag.innerText = '1;'

  # internal
  @no_scroll_check: (node) ->
    return unless node && node.closest

    for el in @config.no_scroll_selector
      return true if node.closest(el)

    false

  @last: ->
    @lastHref || @path()

  @send_global_event: ->
    event = new CustomEvent('pjax:page')
    window.dispatchEvent(event);

  # instance methods

  constructor: (@opts) ->
    @href = @opts.href || @opts.path

  redirect: ->
    @href ||= location.href

    if @href[0] == 'h' && !@href.includes(location.host)
      # if page is on a foreign server, open it in new window
      window.open @href
    else
      location.href = @href

    false

  # load a new page
  load: ->
    return false unless @href

    # if ctrl or cmd button is pressed, open in new window
    if event && (event.which == 2 || event.metaKey)
      return window.open @href

    if Pjax.before(@href, @opts) == false
      return

    if @href == '#' || (location.hash && location.pathname == @href)
      return

    if /^http/.test(@href) || /#/.test(@href) || @is_disabled
      return @redirect()

    for el in Pjax.config.paths_to_skip
      switch typeof el
        when 'object' then return @redirect() if el.test(@href)
        when 'function' then return @redirect() if el(@href)
        else return @redirect() if @href.startsWith(el)

    @opts.req_start_time = (new Date()).getTime()
    @opts.path = @href
    @opts.no_scroll = true if delete @opts.scroll == false

    headers = {}
    headers['cache-control'] = 'no-cache' if @opts.no_cache
    headers['x-requested-with'] = 'XMLHttpRequest'

    if Pjax.request
      Pjax.request.abort()

    Pjax.request = @req = new XMLHttpRequest()

    @req.onerror = (e) ->
      Pjax.error 'Net error: Server response not received (Pjax)'
      console.error(e)

    @req.open('GET', @href)
    @req.setRequestHeader k, v for k,v of headers

    @req.onload = (e) =>
      @response  = @req.responseText

      # console log
      time_diff = (new Date()).getTime() - @opts.req_start_time
      log_data  = "Pjax.load #{@href}"
      log_data += if @opts.no_history then ' (back trigger)' else ''
      Pjax.console "#{log_data} (app #{@req.getResponseHeader('x-lux-speed') || 'n/a'}, real #{time_diff}ms, status #{@req.status})"

      # if not 200, redirect to page to show the error
      if @req.status != 200
        @redirect()
      else
        # fix href because of redirects
        if rul = @req.responseURL
          @href = rul.split('/')
          @href.splice(0, 3)
          @href = '/' + @href.join('/')

        # add history
        if @opts.replacePath || !@opts.no_history
          PjaxHistory.addCurrent @opts.replacePath || @href

        # inject response in current page and process if ok
        if @set_data()
          # trigger opts['done'] function
          @opts.done() if typeof(@opts.done) == 'function'

          # scroll to top of the page unless defined otherwise
          unless @opts.no_scroll || Pjax.no_scroll_check(@opts.node)
            window.scrollTo(0, 0)
        else
          # document.write @response is buggy and unsafe
          # do full reload
          @redirect()

    @req.send()

    false

  set_title_and_body: ->
    title = @rroot.querySelector('title')?.innerHTML
    document.title = title || 'no page title (pjax)'

    if new_body = @rroot.querySelector('#'+@main_node.id)?.innerHTML
      @main_node.innerHTML = new_body
      Pjax.parseScripts()
      Pjax.after(@href, @opts)
      Pjax.send_global_event()
      true
    else
      false

  set_data: ->
    @main_node = Pjax.node()

    unless @main_node
      Pjax.error 'template_id mismatch, full page load (use no-pjax as a class name)'
      return

    unless @main_node.id
      alert 'No ID attribute on pjax node'
      return

    @rroot = document.createElement('div')
    @rroot.innerHTML = @response

    if ajax_node = @opts.ajax_node
      ajax_node.setAttribute('data-path', @href)
      ajax_node.removeAttribute('path')

      ajax_data = if ajax_id = ajax_node.getAttribute('id')
        @rroot.querySelector('#'+ajax_id)?[0]
      else
        @rroot.querySelector(Pjax.config.ajax_selector)?[0]

      if ajax_data
        ajax_data = ajax_data.innerHTML
      else
        if @response.includes('<html') && @response.includes('<body')
          # this happens when you have parent .ajax node, click link, and full page is loaded
          # without ajax node + ID match. we assume it is full fresh page and reload all
          # to mitigate that behaviour without ID match, just send partial without <html tag
          return @set_title_and_body()
        else
          ajax_data = @response

      ajax_node.innerHTML = ajax_data
      Pjax.parseScripts()
    else
      @set_title_and_body()

#

class PjaxHistory
  # add current page to history
  @addCurrent: (href) ->
    if Pjax.lastHref == href
      window.history.replaceState({}, document.title, href);
    else
      window.history.pushState({}, document.title, href)
      Pjax.lastHref = href

  @loadFromHistory: (event) ->
    setTimeout ->
      Pjax.load Pjax.path(), history: false
    , 1

# handle back button gracefully
window.onpopstate = PjaxHistory.loadFromHistory

PjaxOnClick =
  main: ->
    # self or scoped href, as on %tr row element.
    if node = event.target.closest('*[href]')
      event.stopPropagation()
      event.preventDefault()

      href = node.getAttribute 'href'

      # if ctrl or cmd button is pressed, open in new window
      if event.which == 2 || event.metaKey
        return window.open href

      # if direct link, do not use Pjax
      klass = ' ' + node.className + ' '
      for el in Pjax.config.no_pjax_class
        if klass.includes(" #{el} ")
          if /^http/.test(href)
            window.open(href)
          else
            return window.location.href = href

      # execute inline JS
      if /^javascript:/.test(href)
        func = new Function href.replace(/^javascript:/, '')
        return func()

      # disable bots
      # return if /bot|googlebot|crawler|spider|robot|crawling/i.test(navigator.userAgent)

      # if target attribute provided, open in new window
      if /^\w/.test(href) || node.getAttribute('target')
        return window.open(href, node.getAttribute('target') || href.replace(/[^\w]/g, ''))

      # if everything else fails, call Pjax
      Pjax.load href, node: node

      false

window.addEventListener 'DOMContentLoaded', () ->
  setTimeout(Pjax.send_global_event, 0)
