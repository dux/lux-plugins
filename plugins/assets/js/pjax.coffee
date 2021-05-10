# make new class PjaxPage, work with that

# How to use?

# Pjax will replace only contents of MAIN HTML tag
# HTML <main> Tag
# https://www.w3schools.com/tags/tag_main.asp

# Pjax.no_scroll('.no-scroll', '.menu-heading', '.skill', ()=>{ ... })
# set meta[name=pjax_template_id] in header, and full reaload page on missmatch
# Pjax.init -> ... -> function to execute after every page load

window.Pjax = class Pjax
  @config =
    silent: false
  @no_scroll_list = []
  @before_test    = []
  @paths_to_skip  = []

  # base class method to load page
  @load: (href, opts) ->
    if Pjax.noCache
      Pjax.noCache  = false

      opts = opts || {}
      opts.no_cache = true

    pjax = new Pjax(href, opts || {})
    pjax.load()

  @path: ->
    location.pathname+location.search

  # refresh page, keep scrool
  @refresh: (func) ->
    Pjax.load(Pjax.path(), { no_scroll: true, done: func })

  # reload, jump to top, no_cache http request forced
  @reload: (func) ->
    Pjax.load(Pjax.path(), { no_cache: true, done: func })

  @node: ->
    document.getElementsByTagName('pjax')[0] || document.getElementsByClassName('pjax')[0]

  # send info to a client
  @info: (data) ->
    return if @config.silent

    msg = "Pjax info: #{data}"
    console.log msg
    alert msg

  @console: (msg) ->
    unless @config.silent
      console.log msg

  # what to do on request error
  @on_error: (ret) ->
    @console("Pjax request error: #{ret.statusText} (#{ret.status})")

  # execute action before pjax load and do not proceed if return is false
  # example, load dialog links inside the dialog
  # Pjax.before (href, opts) ->
  #   if opts.node
  #     if opts.node.closest('.in-popup')
  #       Dialog.load href
  #       return false
  #   true
  @before: (func) ->
    @before_test.push func

  # do not scroll to top, use refresh() and not reload() on node with classes
  # Pjax.no_scroll('.no-scroll', '.menu-heading', '.skill')
  @no_scroll: ->
    @no_scroll_list = arguments

  @no_scroll_check: (node) ->
    return unless node && node.closest

    for el in @no_scroll_list
      return true if node.closest(el)

    false

  # skip pjax on followin links and do location.href = target
  # Pjax.skip('/admin', '/login')
  @skip: ->
    for el in arguments
      @paths_to_skip.push el

  # Pjax.init ->
  #  Widget.bind()
  #  Dialog.close()
  #  ga('send', 'pageview') if window.ga;
  # init Pjax with function that will run after every pjax request
  @init: (func) ->
    @init_ok = true

    # if page change fuction provided, store it and run it
    @after = func if func

  # replace with real page reload init func
  @after: -> true

  ###########

  constructor: (@href, @opts) ->
    true

  redirect: ->
    location.href = @href
    false

  # load a new page
  load: ->
    @info 'You did not use Pjax.init()' unless Pjax.init_ok

    return false unless @href

    @href = location.pathname + @href if @href[0] == '?'

    for func in Pjax.before_test
      return false unless func(@href, @opts)

    if @href == '#' || (location.hash && location.pathname == @href)
      return

    if /^http/.test(@href) || /#/.test(@href) || @is_disabled
      return @redirect()

    for el in Pjax.paths_to_skip
      switch typeof el
        when 'object' then return @redirect() if el.test(@href)
        when 'function' then return @redirect() if el(@href)
        else return @redirect() if @href.startsWith(el)

    @opts.req_start_time = (new Date()).getTime()

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

      # if not 200, redirect to page to show the error
      if @req.status != 200
        Pjax.console("Pjax status: #{@request.status}")
        location.href = @href
      else
        # fix href because of redirects
        if rul = @req.responseURL
          @href = rul.split('/')
          @href.splice(0,3)
          @href = '/' + @href.join('/')

        # console log
        time_diff = (new Date()).getTime() - @opts.req_start_time
        log_data  = "Pjax.load #{@href}"
        log_data += if @opts.no_history then ' (back trigger)' else ''
        Pjax.console "#{log_data} (app #{@req.getResponseHeader('x-lux-speed')}, real #{time_diff}ms)"

        # inject response in current page and process if ok
        if ResponsePage.inject(@response, @href)
          # add history
          PjaxHistory.addCurrent(@href) unless @opts.no_history

          # trigger init func if one provided on init
          Pjax.after()

          # trigger opts['done'] function
          @opts.done() if typeof(@opts.done) == 'function'

          # scroll to top of the page unless defined otherwise
          unless @opts.no_scroll || Pjax.no_scroll_check(@opts.node)
            window.scrollTo(0, 0)

    @req.send()

    false

#

class ResponsePage
  @inject: (response, href) ->
    response_page = new ResponsePage response
    response_page.inject_in_current(href)

  @set: (title, main_data) ->
    if main_node = Pjax.node()
      document.title      = title || 'no page title (pjax)'
      main_node.innerHTML = main_data
    else
      Pjax.info 'No pjax node?'

  #

  constructor: (@response) ->
    @page = document.createElement('div')
    @page.innerHTML = @response

  node: ->
    @page.getElementsByTagName('pjax')[0] ||
    @page.getElementsByClassName('pjax')[0] ||
    alert('No <pjax id="foo"> or <div class="pjax" id="foo"> node in response page')

  # extract node html + attributes as object from html data
  extract: (node_name) ->
    out = {}

    if node = @page.querySelector(node_name)
      out['HTML'] = node.innerHTML

      for name in node.getAttributeNames()
        out[name] = node.getAttribute(name)

    out

  # replace title and main block
  inject_in_current: (href) ->
    node = @node()

    if node.id
      if node.id == Pjax.node().id
        ResponsePage.set @extract('title').HTML, node.innerHTML
        Pjax.after()
        return true
      else
        console.log 'Pjax: template_id mismatch, full page load'
        # document.write @response is buggy and unsafe
        # do full reload
        location.href = href
    else
      alert 'No IN on pjax node (<pjax id="main">...)'

    false

#

class PjaxHistory
  # add current page to history
  @addCurrent: (href) ->
    title = document.title
    main  = Pjax.node().innerHTML

    window.history.pushState({ title: title, main: main }, title, href)

  @loadFromHistory: (event) ->
    if event.state.main
      ResponsePage.set event.state.title, event.state.main
      Pjax.after()
    else
      Pjax.load Pjax.path(), no_history: true

# handle back button gracefully
window.onpopstate = PjaxHistory.loadFromHistory

