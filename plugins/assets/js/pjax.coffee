# Pjax will replace only contents of MAIN HTML tag
# HTML <main> Tag
# https://www.w3schools.com/tags/tag_main.asp

# How to use?

# Pjax.captureOnClick()
# Pjax.error = (msg) -> Info.error msg
# Pjax.noScrollOn('.no-scroll', '.menu-heading', '.skill', ()=>{ ... })
# Pjax.before ->
#   InlineDialog.save()
# Pjax.after ->
#   InlineDialog.restore() if window.InlineDialog
#   Dialog.close() if window.Dialog
# Pjax.load('/users/new', no_history: bool, no_scroll: bool, done: ()=>{...})

# to refresh link in container only nameing of dom nodes is imporant
# functionality rest is automatic, it will refres first .ajax parent by id
# .ajax{ id: :foo }
#   ...
#   .ajax
#     %a{ href: '' }

window.Pjax = class Pjax
  @is_silent      = false
  @no_scroll_list = ['.no-scroll']
  @paths_to_skip  = []

  @onDocumentClick: ->
    document.addEventListener 'click', PjaxOnClick.main

  # base class method to load page
  # no_history: bool
  # no_scroll: bool
  # done: ()=>{...}
  @load: (href, opts) ->
    if Pjax.noCache
      Pjax.noCache  = false

      opts = opts || {}
      opts.no_cache = true

    pjax = new Pjax(href, opts || {})
    pjax.load()

  @path: ->
    location.pathname+location.search

  # refresh page, keep scroll
  @refresh: (func) ->
    if typeof func == 'string'
      Pjax.load(func, { no_scroll: true })
    else
      Pjax.load(Pjax.path(), { no_scroll: true, done: func })

  # reload, jump to top, no_cache http request forced
  @reload: (func) ->
    Pjax.load(Pjax.path(), { no_cache: true, done: func })

  @node: ->
    document.getElementsByTagName('pjax')[0] || document.getElementsByClassName('pjax')[0] || alert('.pjax or #pjax not found')

  # send info to a client
  @info: (data) ->
    msg = "Pjax info: #{data}"
    console.log msg
    alert msg unless @is_silent

  @console: (msg) ->
    unless @is_silent
      console.log msg

  # Pjax.init ->
  #  Widget.bind()
  #  Dialog.close()
  #  ga('send', 'pageview') if window.ga;
  # init Pjax with function that will run after every pjax request
  @init: (func) -> @after func
  @after: (func) ->
    if func
      @after_func = func
      func()
    else
      @after_func() if @after_func

  # replace with real page reload init func
  @before: (func) ->
    if func
      @before_func = func
    else if @before_func
      @before_func()
    else
      true

  # execute action before pjax load and do not proceed if return is false
  # example, load dialog links inside the dialog
  # Pjax.test (href, opts) ->
  #   if opts.node
  #     if opts.node.closest('.in-popup')
  #       Dialog.load href
  #       return false
  #   true
  @test: (arg1, arg2) ->
    if arg2
      if @test_func
        @test_func(arg1, arg2)
      else
        true
    else
      @test_func = arg1 if typeof arg1 == 'function'

  # do not scroll to top, use refresh() and not reload() on node with classes
  # Pjax.noScrollOn('.no-scroll', '.menu-heading', '.skill')
  @noScrollOn: ->
    @no_scroll_list = arguments

  # overload to add filters
  # Pjax.beforeLoad(@href, @opts.node)
  @beforeLoad: ->
    true

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

  @error: (msg) ->
    console.error "Pjax error: #{msg}"

  ###########

  constructor: (@href, @opts) ->
    true

  redirect: ->
    if @href && !@href.includes(location.host)
      # if page is on a foreign server, open it in new window
      window.open @href
    else if Pjax.use_document_write
      document.open()
      document.write(@response)
      document.close()
    else
      location.href = @href

    false

  # load a new page
  load: ->
    return false unless @href

    @href = location.pathname + @href if @href[0] == '?'

    return if Pjax.test(@href, @opts) == false

    if @href == '#' || (location.hash && location.pathname == @href)
      return

    if /^http/.test(@href) || /#/.test(@href) || @is_disabled
      return @redirect()

    for el in Pjax.paths_to_skip
      switch typeof el
        when 'object' then return @redirect() if el.test(@href)
        when 'function' then return @redirect() if el(@href)
        else return @redirect() if @href.startsWith(el)

    return if Pjax.beforeLoad(@href, @opts.node) == false

    @opts.req_start_time = (new Date()).getTime()
    @opts.path = @href
    @opts.no_scroll = true if @opts.node && @opts.node.closest('.ajax')
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
        unless @opts.no_history
          #  PjaxHistory.replaceState()
          PjaxHistory.addCurrent(@href)

        # inject response in current page and process if ok
        if ResponsePage.inject(@response, @opts)
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

#

class ResponsePage
  @inject: (response, opts) ->
    response_page = new ResponsePage response, opts
    response_page.inject_in_current()

  @set: (title, main_data) ->
    if main_node = Pjax.node()
      document.title      = title || 'no page title (pjax)'
      Pjax.before()
      main_node.innerHTML = main_data
      @parseScripts()
      Pjax.after()

    else
      Pjax.info 'No pjax node?'

  @parseScripts: () ->
    for script_tag in Pjax.node().getElementsByTagName('script')
      unless script_tag.getAttribute('src')
        type = script_tag.getAttribute('type') || 'javascript'

        if type.indexOf('javascript') > -1
          func = new Function script_tag.innerText
          func()
          script_tag.innerText = '1;'

  #

  constructor: (@response, @opts) ->
    @page = document.createElement('div')
    @page.innerHTML = @response

  node: ->
    @page.getElementsByTagName('pjax')[0] || @page.getElementsByClassName('pjax')[0]

  # extract node html + attributes as object from html data
  extract: (node_name) ->
    out = {}

    if node = @page.querySelector(node_name)
      out['HTML'] = node.innerHTML

      for name in node.getAttributeNames()
        out[name] = node.getAttribute(name)

    out

  # replace title and main block
  inject_in_current: ->
    if @opts.node
      if ajax_node = @opts.node.closest('.ajax')
        @opts.no_history = true

        ajax_node.setAttribute('path', @opts.path)

        ajax_node.innerHTML =
        if response_ajax_node = @page.getElementsByClassName('ajax')[0]
           response_ajax_node.innerHTML
        else
          @response

        return true

    unless node = @node()
      Pjax.info('No <pjax id="foo"> or <div class="pjax" id="foo"> node in response page')
      return false

    if node.id
      if node.id == Pjax.node().id
        ResponsePage.set @extract('title').HTML, node.innerHTML
        return true
      else
        Pjax.error 'template_id mismatch, full page load'
    else
      alert 'No IN on pjax node (<pjax id="main">...)'

    false

#

class PjaxHistory
  @replaceState: ->
    try
      window.history.replaceState({ title: document.title, main: Pjax.node().innerHTML }, document.title, location.pathname + location.hash)
    catch e
      console.error(e)

  # add current page to history
  @addCurrent: (href) ->
    window.history.pushState({ title: document.title }, document.title, href)

  @loadFromHistory: (event) ->
    if event.state && event.state.main
      ResponsePage.set event.state.title, event.state.main
    else
      Pjax.load Pjax.path(), no_history: true

# handle back button gracefully
window.onpopstate = PjaxHistory.loadFromHistory

PjaxOnClick =
  run: (func) ->
    event.stopPropagation()
    event.preventDefault()
    func() if func
    false

  main: ->
    # if ctrl or cmd button is pressed
    return if event.which == 2 || event.metaKey

    # self or scoped href, as on %tr row element.
    if node = event.target.closest('*[href]')
      # scoped confirmatoon box
      if confirm_node = node.closest('*[confirm]')
        return unless confirm(confirm_node.getAttribute('confirm'))

      if click_node = node.closest('*[click]')
        func = new Function click_node.getAttribute('click')

        if func.bind(click_node)() == false
          return PjaxOnClick.run()

      return if node.closest('*[onclick]')

      if href = node.getAttribute 'href'
        klass = ' ' + node.className + ' '

        return if klass.includes(' no-pjax ')
        return if klass.includes(' direct ')
        return if /^javascript:/.test(href)
        return if /bot|googlebot|crawler|spider|robot|crawling/i.test(navigator.userAgent)

        if /^\w/.test(href) || node.getAttribute('target')
          return PjaxOnClick.run ->
            window.open(href, node.getAttribute('target') || href.replace(/[^\w]/g, ''))

        PjaxOnClick.run -> Pjax.load href, node: node
