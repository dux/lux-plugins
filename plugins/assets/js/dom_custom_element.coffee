# Svelte custom DOM nodes
# https://github.com/sveltejs/svelte/issues/1748

# I could refactor it to work with Mutation observer
# const observer = new MutationObserver((mutationsList) => {
#   for (let mutation of mutationsList) {
#     if (mutation.type === 'childList') {
#       for (let node of mutation.addedNodes) {
#         if (node.nodeType === Node.ELEMENT_NODE) {
#           console.log(node.nodeName)
#         }
#       }
#     }
#   }
# });

# document.addEventListener("DOMContentLoaded", ()=>{
#   const config = { childList: true, attributes: true };
#   observer.observe(document.body, config);
# })



# React to do
# ReactDOM.render(React.createElement(SomeReactComponent, { foo: 'bar' }), dom_node);

# get all <s-filter ...> components and run close() on them
# Svelte('filter', function(){ this.close() })
#
# get singleton dialog component
# Svelte('s-dialog').close()
#
# get closest ajax svelte node
# Svelte('s-ajax', this)
#
# CustomElement.define({
#   name: 'foo-bar',
#   func: (node)=>{ node.innerHTML = 'binded' }
# })
# create DOM custom element or polyfil for older browsers

# %s-toggle-block{ id: 'mail_form' }
#   .off
#     %s-info
#       Email is sent
#   .on
# or use server application helper svelte to render innerHTML in params

# function will loop while node exists in document, run if is visible and will stop on return true
# if you need just a small delay, use window.requestAnimationFrame instead (much faster and no flicker)

HTMLElement.prototype.$ready = (func, time) ->
  interval = setInterval () =>
    # LOG this.checkVisibility()
    return clearInterval interval unless document.body.contains(this)
    if !this.checkVisibility || this.checkVisibility()
      clearInterval interval
      func()

  , time || 300

nodesAsList = (root, as_hash) ->
  list = []

  return list unless root

  if typeof root == 'string'
    node = document.createElement("div")
    node.innerHTML = root
    root = node

  root.childNodes.forEach (node, i) ->
    if node.attributes
      o = {}
      o.NODE = node
      o.NODENAME = node.nodeName
      o.ID = i + 1
      o.html = node.innerHTML

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

counter = 1

window.CustomElement =
  attributes: (node) ->
    props =
    if node.getAttribute('data-props')
      # if you want to send nested complex data, best to define as data-props encoded as JSON
      # LOG props.replaceAll('"', 'x').split('Segoe UI', 2)[1]
      JSON.parse(props)
    else if node.getAttribute('data-json-template')
      # BEST
      # template{ id: foo}= @object.to_jsonp
      data = node.previousSibling?.textContent
      if data then JSON.parse(data) else {}
    else
      Array.prototype.slice
        .call(node.attributes)
        .reduce (h, el) ->
          h[el.name] = el.value;
          # if we remove attrs, then we sometimes have to manually re-add them, as for s-ajax, that expects last path attribute to be present at all times
          # unless ['id', 'svelte'].includes(el.name)
          #   node.removeAttribute(el.name)
          h
        , {}

    props.html ||= node.innerHTML
    id = node.getAttribute('id') || "svelte-block-#{counter++}"
    node.removeAttribute('id')
    props.$id = id
    props.$node = node
    props.$nodes = () => nodesAsList(node)
    props.$self = "Svelte('##{id}')"
    props.$html = (filter) ->
      data = String(node.innerHTML)
      if filter
        data.replace(/&lt;/g, '<')
        data.replace(/&gt;/g, '>')
        data.replace(/&amp;/g, '&')
      data

    # props.$slot(target) - copy all to target
    # props.$slot(target, nodes) - copy node/nodes to target
    # props.$slot('a.link') - get slot clind node links with class name link
    props.$slot = (target, nodes) ->
      if target
        if typeof target == 'string'
          return Array.from node.querySelectorAll(":scope > #{target}")
        else
          if nodes?.nodeName
            nodes = [nodes]
          else if typeof nodes == 'string'
            nodes = Array.from node.querySelectorAll(":scope > #{nodes}")
          else
            nodes = Array.from(node.querySelectorAll(":scope > *"))

          for el in nodes
            target.appendChild el

        target
      else
        Array.from(node.querySelectorAll(":scope > *"))

    props

  renderReplace: (node, func) ->
    # func node, CustomElement.attributes(node)

    attrs = CustomElement.attributes(node)
    newSpan = document.createElement('span')
    newSpan.setAttribute('id', attrs.$id)
    newSpan.setAttribute('class', "custom-element custom-element-#{node.nodeName.toLowerCase()}")
    newSpan.onclick = () -> node.click() if newSpan.onclick
    # node.parentNode.insertBefore(newSpan, node);
    node.parentNode?.replaceChild(newSpan, node)
    func newSpan, attrs

  render: (node, func) ->
    if document.readyState != 'complete'
      # ['complete', 'loaded', 'interactive'].includes(document.readyState)
      window.requestAnimationFrame =>
        @renderReplace node, func
    else
      @renderReplace node, func

  # define custom element
  define: (name, func) ->
    if window.customElements
      unless customElements.get(name)
        customElements.define name, class extends HTMLElement
          attributeChangedCallback: (name, oldValue, newValue) ->
            console.log('attributeChangedCallback', name, oldValue, newValue)
          connectedCallback: ->
            CustomElement.render @, func

window.Svelte = (name, func) ->
  if name.nodeName
    # Svelte(this).close() -> return first parent svelte node
    while name = name.parentNode
      return name.svelte if name.svelte
  else
    if name[0] == '#'
      # Svelte('#svelte-block-123').set('spinner')
      document.querySelectorAll(name)[0]?.svelte
    else
      nodes = Array.from document.querySelectorAll(".custom-element-#{name}")

      if func
        # Svelte('s-dialog', (el) => { el.close() })
        nodes.forEach (el) -> func(el.svelte)
        return
      else
        # Svelte('s-dialog') # all dialog nodes
        return nodes.map((el) => el.svelte)

Svelte.index = {}
window.S = {}
Svelte.bind = (name, svelte_klass) ->
  key_name = name.replace(/^\w+\-/, '').replaceAll('-', '_')
  unless Svelte.index[key_name]
    S[key_name] = Svelte.index[key_name] = svelte_klass

    CustomElement.define name, (node, opts) ->
      # some strange bug with custom nodes double defined, this seems to fix it
      if node.parentNode
        props = { target: node, props: { props: opts }}
        svelteInstance = new svelte_klass(props)
        node.svelte = svelteInstance
        svelteInstance.onDomMount?(svelteInstance, node)
        LOG "Svelte: #{name}"

        if svelteInstance.domReplaceParent # for buttons, not to be nested under <span node to break css rules
          child = node.firstChild
          if child.classList
            child.classList.add("custom-element");
            child.classList.add("custom-element-#{name}");
            node.parentNode.insertBefore(child, node)
            node.parentNode.removeChild(node)


# you pass base props and default values, get filterd hash (button-tabs for details)
# let props = Svelte.props($$props, { name: null, size: 24 })
Svelte.props = (base, obj) =>
  out = {}
  props = base.props || {}

  if obj == undefined
    obj = {}
    Object.keys(base.props || base).map (key) => obj[key] = null

  keys = Object.keys(obj).concat(['$id', '$node', '$nodes', '$self'])
  keys.forEach (key) =>
    vals = [props[key], base[key], obj[key]]
    out[key] = vals.find((v) => v != undefined)

  # you need to pass dom node after mount if useing native and not custom DOM nodes render
  # function mount (node) { links = props.links || props.$nodes(node); ... }
  out.$nodes ||= nodesAsList

  out

# # bind react elements
# bind_react: (name, klass) ->
#   @define name, (node, opts) ->
#     element = React.createElement klass, opts, node.innerHTML
#     ReactDOM.render element, node
