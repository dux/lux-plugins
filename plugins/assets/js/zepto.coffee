$.delay = (time, func) ->
  if !func
    func = time
    time = 10
  setTimeout func, time

# run until function returns true
$.untilTrue = (func) ->
  unless func()
    setTimeout () =>
      $.untilTrue func
    , 100

# capture key press unless in forms
$.keyPress = (key, func) ->
  $(document).keydown (e) ->
    # console.log([e.keyCode, e.key])

    return if e.target.nodeName == 'INPUT'
    return if $(e.target).parents('form')[0]

    if key.includes('+')
      [base, part] = key.split('+', 2)
      return unless e.ctrlKey || e.metaKey
    else
      part = key

    if e.key == part
      $(e).cancel()
      func e

# clear timeout and postopne execution of a function
# like for autocomplete
# $.debounce 'foo-1', -> ...
# $.debounce 'foo-1', 500, -> ...
$._debounce_hash = {}
$.debounce = (uid, delay, callback) ->
  if typeof delay == 'function'
    callback = delay
    delay = 10

  if $._debounce_hash[uid]
    clearTimeout $._debounce_hash[uid]

  $._debounce_hash[uid] = setTimeout(callback, delay)

# for ajax search, will cache results
$._cached_get = {}
$.cachedGet = (url, func) ->
  if data = $._cached_get[url]
    func data
  else
    $.debounce 'cached-get', 200, ->
      $.get url, (data) ->
        func(data)
        $._cached_get[url] = data

# insert script in the head
$.getScript = (src, check, func) ->
  if func && typeof check == 'string'
    check = new Function "return !!window['#{check}']"

  unless func
    func = check
    check = null

  if check && check()
    func() if func
  else
    script = document.createElement('script')
    script.async  = 'async'
    script.src    = src
    script.onload = func if func
    document.getElementsByTagName('head')[0].appendChild script

# insert script module in the head
# $.loadModule('https://cdn.skypack.dev/easymde', 'EasyMDE', ()=>{
#   let editor = new EasyMDE({
$.loadModule = (src, import_gobal, on_load) ->
  module_id = 'header_module_' + import_gobal
  on_load ||= () => true

  unless document.getElementById(module_id)
    script = document.createElement('script')
    script.id   = module_id
    script.type = 'module'
    script.innerHTML = """
      import mod from '#{src}';
      window.#{import_gobal} = mod;
    """
    document.getElementsByTagName('head')[0].appendChild script

  $.untilTrue () =>
    if window[import_gobal]
      on_load() if on_load
      true

  src

# parse and execute nested <script> tags
# we need this for example in svelte, where template {@html data} does nor parse scripts
$.parseScripts = (html) ->
  tmp = document.createElement 'DIV'
  tmp.innerHTML = html

  for script_tag in tmp.getElementsByTagName('script')
    continue if script_tag.getAttribute('src') || !script_tag.innerText
    type = script_tag.getAttribute('type') || 'javascript'

    if type.indexOf('javascript') > -1
      try
        f = new Function script_tag.innerText
        f()
        script_tag.innerText = '1;'
      catch e
        console.error(e)
        alert "JS error: #{e.message}"


  tmp.innerHTML


# return child nodes as list of hashes
$.nodesAsList = (root, as_hash) ->
  list = []

  if typeof root == 'string'
    node = document.createElement("div")
    node.innerHTML = root
    root = node

  root.childNodes.forEach (node, i) ->
    if node.attributes
      o = {}
      o.NODENAME = node.nodeName
      o.HTML = node.innerHTML
      o.OUTER = node.outerHTML
      o.ID = i + 1

      for a in node.attributes
        o[a.name] = a.value

      list.push o

  if as_hash
    out = {}
    for el in list
      out[el.NODENAME] ||= []
      out[el.NODENAME].push el
    out
  else
    list

$.cookies =
  get: (name) ->
    list = {}

    for line in document.cookie.split("; ")
      [key, value] = line.split('=', 2)

      if key == name
        return value
      else
        list[key] = value

    list

  set: (name, value, days) ->
    date = new Date()
    date.setTime date.getTime() + ((days || 7) * 24 * 60 * 60 * 1000)
    expires = "; expires=" + date.toGMTString()
    document.cookie = name + "=" + value + expires + "; path=/"

  delete: (name) ->
    setCookie name, "", -1

# copies text to clipboard
$.copyText = (str) ->
  el = document.createElement('textarea')
  el.value = str
  document.body.appendChild(el)
  el.select()
  document.execCommand('copy')
  document.body.removeChild(el)

$.noCacheGet = (path, func) ->
  $.ajax
    type: 'get'
    url: path
    headers: { 'cache-control': 'no-cache' }
    success: func

# run fuction only once
$.once_hash = {}
$.once = (name, func) ->
  if $.once_hash[name]
    false
  else
    $.once_hash[name] = true
    func()
    true

$.resizeIframe = (obj) ->
  obj.style.height = obj.contentWindow.document.documentElement.scrollHeight + 'px';

$.d = (obj) ->
  JSON.stringify obj, null, 2

# add html but do not everwrite ids
$.fn.xhtml = (data) ->
  id = $(@).attr('id')

  unless id
    console.warn 'ID not defined on node for $.fn.xhtml'
    return

  @each ->
    tmp_data = $("<div>#{data}</div>").find('#'+id)

    if tmp_data[0]
      data = tmp_data[0].innerHTML
    else
      console.warn "ID ##{id} not found in returned HTML"

    this.innerHTML = data

# get or set unique ID on a node
$.fn.node_id = ->
  unless window._node_id_cnt
    window._node_id_cnt = 0
  unless @attr('id')
    @attr 'id', 'jsapp_uid_' + ++window._node_id_cnt
  @attr 'id'

$.fn.slideDown = (duration) ->
  @show()
  height = @height()
  @css height: 0
  @animate { height: height }, duration

$.fn.slideUp = (duration) ->
  target = this
  height = @height()
  @css height: height
  @animate { height: 0 }, duration, '', ->
    target.css
      display: 'none'
      height: ''

$.fn.serializeHash = ->
  hash = {}

  $(this).find('input, textarea, select').each ->
    if @name and !@disabled
      val = $(@).val()
      val = 0 if @type == 'checkbox' and !@checked
      hash[@name] = val

  hash

# execute func if first element found
$.fn.xfirst = (func) ->
  el = undefined
  el = $(this).first()
  if el
    func(el)

# better focus, cursor at the end of the input
# $('input[name=q]').xfocus()
$.fn.xfocus = ->
  $.delay =>
    $(this).xfirst (el) ->
      value = undefined
      value = el.val()
      el.focus()
      el.val value + ' '
      el.val value

# load URL and replace content under specific ID
# executes scripts found in a page
# load path into node
#   $('#dialog').reload('/c/cts/show_dialog')
# load path from attribute
#   #dialog{ path: '...' }
#   $('#dialog').reload() -> path in attribute
# refresh full page and replace only target element
#   $('#dialog').reload() -> path in attribute
$.fn.reload = (path, func) ->
  if typeof path == 'function'
    func = path
    path = null

  ajax_node = @parents('.ajax').first()
  ajax_node = @ unless ajax_node[0]

  path  ||= ajax_node.attr('path')

  unless path
    alert 'Ajax path not found'
    return

  node_id = ajax_node.attr('id')
  ajax_node.attr('path', path)

  $.get path, (data) =>
    new_node = $("""<div>#{data}</div>""")
    if node_id
      if html = new_node.find('#'+node_id).html()
        data = html
    else
      if html = new_node.find('.ajax').html()
        data = html

    data = $.parseScripts data
    ajax_node.html(data)
    func(data) if func

# stop event propaation from a node
$.fn.cancel = ->
  e = @[0]
  if e.preventDefault
    e.preventDefault()
    e.stopPropagation()
  else if window.event
    window.event.cancelBubble = true

# searches for parent %ajax node and refreshes with given url
$.fn.ajax = (path, path_state) ->
  node = if @hasClass('ajax') then @ else @parents('.ajax')

  if !node[0] && @attr('id')
    path ||= location.pathname + String(location.search)
    $.get path, (data) =>
      html = $("""<div>#{data}</div>""").find('#'+@attr('id')).html()
      @html html

  if path
    node.attr 'path', path
  else
    path = node.attr 'path'

  node.load path

  # set new path state, so back can work in browsers
  if path_state
    if path_state[0] == '?'
      path_state = location.pathname + path_state

    window.history.pushState({ title: document.title }, document.title, path_state)
