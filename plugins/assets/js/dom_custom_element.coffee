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

counter = 1

window.CustomElement =
  attributes: (node) ->
    props = node.getAttribute('data-props')
    id = node.getAttribute('id') || "svelte-block-#{counter++}"

    if props
      node.removeAttribute('data-props')
      # if you want to send nested complex data, best to define as data-props encoded as JSON
      props = JSON.parse(props)
    else
      props = Array.prototype.slice
        .call(node.attributes)
        .reduce (h, el) ->
          h[el.name] = el.value;
          # if we remove attrs, then we sometimes have to manually re-add them, as for s-ajax, that expects last path attribute to be present at all times
          unless ['id', 'svelte'].includes(el.name)
            node.removeAttribute(el.name)
          h
        , {}

    if node.innerHTML
      props.html = node.innerHTML
        .replace(/&lt;/g, '<')
        .replace(/&gt;/g, '>')
        .replace(/&amp;/g, '&')

    # node.removeAttribute('style')
    # node.removeAttribute('onclick')

    node.setAttribute('id', id)
    props ||= {}
    props._id = id
    props._node = node
    props.childNodes = (target, nodes) ->
      nodes ||= Array.from(node.childNodes)
      
      if target
        for el in nodes
          target.appendChild el
      else
        nodes

    props

  renderReplace: (node, func) ->
    # func node, CustomElement.attributes(node)

    attrs = CustomElement.attributes(node)
    newSpan = document.createElement('span')
    newSpan.setAttribute('id', node.id)
    newSpan.setAttribute('class', "custom-element custom-element-#{node.nodeName.toLowerCase()}")
    node.parentNode?.replaceChild(newSpan, node)
    func newSpan, attrs

  render: (node, func) ->
    svelte = node.getAttribute('svelte')

    # console.log node.nodeName

    if document.readyState != 'complete'
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

        # we need this to capture elements created before initialization (svelte="p"repared)
        for el in document.querySelectorAll("""#{name}:not([svelte="d"])""")
          CustomElement.render el, func


window.Svelte = (name, func) ->
  if typeof func == 'function'
    # run in scope of svelte blocks
    Array.prototype.slice
      .call document.getElementsByTagName(name)
      .forEach (el) ->
        func.bind(el.svelte)()
    return

  target = if func
    func.closest(name)
  else
    document.querySelector(name)

  if target
    target.svelte || alert('Svelte not bound to DOM node')
  else
    alert('Svelte target DOM node not found')

Svelte.bind = (name, svelte_klass) ->
  CustomElement.define name, (node, opts) ->
    svelte_node = new svelte_klass({ target: node, props: { props: opts }})
    node.svelte = svelte_node

    svelte_node.onDomMount?(svelte_node)
    
    if c = svelte_node.component
      if c.global
        window[c.global] = svelte_node

# # bind react elements
# bind_react: (name, klass) ->
#   @define name, (node, opts) ->
#     element = React.createElement klass, opts, node.innerHTML
#     ReactDOM.render element, node
