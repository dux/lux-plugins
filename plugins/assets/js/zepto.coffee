# $.createFunction
  # const str = "(arg1, arg2) => alert(arg1 + arg2)";
  # const argsStart = str.indexOf("(");
  # const argsEnd = str.indexOf(")");
  # const args = str.substring(argsStart + 1, argsEnd).split(",").map(arg => arg.trim());
  # const bodyStart = str.indexOf("=>") + 2;
  # const body = str.substring(bodyStart).trim();
  # const func = new Function(...args, body);
  # func(10, 20);

# if location.port
#   window.alert = function(e){ console.warn( "Alerted: " + e ); }

window.Z = $
window.ZZ = (nodeId) => 
  if typeof nodeId == 'string'
    nodeId = '#' + nodeId unless nodeId.includes('#')
    Z(nodeId)
  else
    nodeId

window.LOG = (what...) =>
  if location.port
    # console.warn what
    what = what[0] if what.length < 2
    # console.log what.constructor.name
    if ['Array', 'Object'].includes(what?.constructor.name)
      console.log(JSON.stringify(what, null, 2))
    else
      console.log(what)

window.XMP = (what) =>
  data = JSON.stringify(what, null, 2)
  "<xmp style='font-size: 0.9rem; line-height: 1.1rem; padding: 5px; border: 1px solid #ccc; background: #fff;'>#{data}</xmp>"

window.xalert = (message) ->
  try
    throw new Error(message)
  catch e
    stackLines = e.stack.split('\n')
    callerLine = stackLines[2] # Adjust the index as needed based on your project's call stack structure
    alert "#{callerLine.trim()}\n\n#{message}"

# loadResource 'https://cdnjs.cloudflare.com/some/min.css'
# loadResource css: 'https://cdnjs.cloudflare.com/some/min.css'
loadResource = (src, type) ->
  if typeof src == 'string'
    type ||= if src.includes('.css') then 'css' else 'js'
  else
    if src = src.css
      type = 'css'
    else if src = src.js
      type = 'js'
    else if src = src.img
      type = 'img'

  id = 'res-' + src.replace(/^https?/, '').replace(/[^\w]+/g, '')

  unless document.getElementById(id)
    if type == 'css'
        node = document.createElement('link')
        node.id = id
        node.setAttribute 'rel', 'stylesheet'
        node.setAttribute 'type', 'text/css'
        node.setAttribute 'href', src
        document.getElementsByTagName('head')[0].appendChild node
    else if ['js', 'module'].includes(type)
        node = document.createElement('script')
        node.id    = id
        node.async = 'async'
        node.src   = src
        node.type = 'module' if type == 'module'
        document.getElementsByTagName('head')[0].appendChild node
    else if type == 'img'
        node.id = id
        node = document.createElement('img')
        node.src = src
    else
      alert "Unsupported type (#{type})"

#

$.capitalize = (str) ->
  str.charAt(0).toUpperCase() + str.slice(1)

$.tag = (nodeName, attrs) ->
  attrStr = Object.keys(attrs)
    .filter (key) -> attrs[key] != undefined
    .map (key) -> "#{key}='#{attrs[key]}'"
    .join(' ')

  if ['img', 'input', 'link', 'meta'].includes(nodeName)
    "<#{nodeName} #{attrStr} />"
  else
    "<#{nodeName} #{attrStr}></#{nodeName}>"

$.eval = (...args) ->
  if str = args.shift()
    # str = "()=>{render(#{str})}" unless str[0] == '('
    # params = str.match(/\((.*?)\)/)[1]
    # alert params
    func = if typeof str == 'string' then eval "(#{str})" else str
    func(args...)

$.fnv1 = (str) ->
  FNV_OFFSET_BASIS = 2166136261
  FNV_PRIME = 16777619
  
  hash = FNV_OFFSET_BASIS

  for i in [0..str.length - 1]
    hash ^= str.charCodeAt(i)
    hash *= FNV_PRIME

  # Convert the hash to base 36
  hash.toString(36).replaceAll('-', '')

$.htmlSafe = (text) =>
  String(text).replaceAll('#LT;', '<').replaceAll('<script', '&lt;script')

ulidCounter = 0
$.ulid = ->
  parts = [
    (new Date()).getTime(),
    String(Math.random()).replace('0.', ''),
    ++ulidCounter
  ]
  BigInt(parts.join('')).toString(36).slice(0, 20)

$.delay = (time, func) ->
  if !func
    func = time
    time = 10
  setTimeout func, time

# run until function returns true
# $.untilTrue('md5', () => { md5(key) })
# $.untilTrue(() => { if (window.md5) { md5(key); return true}})
$.untilTrue = (args...) ->
  if typeof args[0] == 'string'
    func = () -> 
      if window[args[0]]
        args[1]()
        return true
    timeout = args[2]
  else
    func = args[0]
    timeout = args[1]

  timeout ||= 200
  unless func() == true
      setTimeout ->
        $.untilTrue func, timeout
      , timeout

# run until function returns true and node exists
$.untilTrueWhileExists = (node, func, timeout) ->
  $.untilTrue =>
    if node
      # console.log(node.checkVisibility(), document.body.contains(node))
      return true unless document.body.contains(node)
      if node.checkVisibility()
        return true if func()
  , timeout 

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

$._throttle_hash = {}
$.throttle = (uid, delay, callback) ->
  if typeof delay == 'function'
    callback = delay
    delay = 200

  $._throttle_hash[uid] ||= [0]

  doIt = () -> 
    $._throttle_hash[uid][0] = new Date()
    callback()

  diff = new Date() - $._throttle_hash[uid][0]
  if diff > delay
    doIt()
  else
    clearTimeout $._throttle_hash[uid][1]
    $._throttle_hash[uid][1] = setTimeout(doIt, delay)

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

  if src.forEach
    for el in src
      loadResource el
  else
    loadResource src

   if check
    $.untilTrue =>
      if check()
        func()
        true
   else if func
    func()
  
# insert script module in the head
# $.loadModule('https://cdn.skypack.dev/easymde', 'EasyMDE', ()=>{
#   let editor = new EasyMDE({
$.loadModule = (src, import_gobal, on_load) ->
  module_id = "header_module_#{$.fnv1(src)}"
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

  return list unless root

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

$.simpleEncode = (str) -> # base64 then rot13
  btoa(str)
    .replace /[a-zA-Z]/g, (c) ->
      charCode = c.charCodeAt(0)
      baseCharCode = if c >= 'a' then 'a'.charCodeAt(0) else 'A'.charCodeAt(0)
      String.fromCharCode(baseCharCode + ((charCode - baseCharCode + 13) % 26))
    .replaceAll('/', '_').replace(/=+$/, '')

$._setInterval = {}
$.setInterval = (name, func, every) ->
  clearInterval $._setInterval[name]
  $._setInterval[name] = setInterval func, every

$.scrollToBottom = (goNow) -> 
  if goNow == true
    window.scrollTo(0, document.body.scrollHeight)
  else
    setTimeout () =>
      window.scrollTo(0, document.body.scrollHeight)
    , goNow || 200

$.saveInfo = () ->
  data = """<div id="loader-bar">
    <style>
      .loader-bar {
        position: fixed;
        top: 0px;
        left: 0px;
        width: 0px;
        height: 3px;
        background-color: #8198cd;
        animation: loader-bar-fill 0.5s cubic-bezier(0.23, 1, 0.32, 1) forwards;
      }

      @keyframes loader-bar-fill {
        0% {
          width: 0;
        }
        60% {
          width: 50%;
        }
        100% {
          width: 100%;
        }
      }
    </style>
    <div class="loader-bar"></div>
  </div>"""

  $(document.body).append(data)
  $.delay(500, () => $('#loader-bar').remove() )

# node functions

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

# $('form#foo').serializeHash()
$.fn.serializeHash = ->
  hash = {}

  $(this).find('input, textarea, select').each ->
    if @name and !@disabled
      val = $(@).val()
      val = 0 if @type == 'checkbox' and !@checked
      hash[@name] = val

  hash

# $('form#foo').ajaxSubmit((response) { ... })
$.fn.ajaxSubmit = (callback)->
  form = $(this)
  $.ajax
    type: (form.attr('method') || 'get').toUpperCase()
    url: form.attr 'action'
    data: form.serializeHash() 
    headers:
      'x-tz-name': Intl.DateTimeFormat().resolvedOptions().timeZone if window.Intl
    complete: (r) =>
      data = r.responseText
      data = JSON.parse(data) if r.getResponseHeader('content-type').toLowerCase().includes('json')
      callback(data, r) if callback

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
# node has to have path or ID
# $(this).ajax('/cell/post/preview/post_id:8/site_id:4/edit:true', '/dashboard/posts/czr/edit:true')
$.fn.ajax = (path, path_state) ->
  node = if @hasClass('ajax') then @ else @parents('.ajax')
  id = @attr('id')

  if node[0]
    node.attr('data-path', path) if path

    path ||= @attr('path') || @attr('data-path')
    path ||= location.pathname + String(location.search)

    $.get path, (data) =>
      html = if id
        $("<div>#{data}</div>").find("##{id}").html() || data
      else
       data

      node.html html

    # set new path state, so back can work in browsers
    if path_state
      if path_state[0] == '?'
        path_state = location.pathname + path_state

      window.history.pushState({ title: document.title }, document.title, path_state)

$.fn.shake = (interval = 150) ->
  @addClass 'shaking'
  @css 'transition', "all 0.#{interval}s"
  setTimeout (=>@css('transform', 'rotate(-10deg)')), interval * 0
  setTimeout (=>@css('transform', 'rotate(10deg)')), interval * 1
  setTimeout (=>@css('transform', 'rotate(-5deg)')), interval * 2
  setTimeout (=>@css('transform', 'rotate(5deg)')), interval * 3
  setTimeout (=>@css('transform', 'rotate(-2deg)')), interval * 4
  setTimeout (=>@css('transform', 'rotate(0deg)')), interval * 5
  @removeClass 'shaking'

$.fn.isVisible = () -> @[0] && @[0].checkVisibility()
