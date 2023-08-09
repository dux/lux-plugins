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

$readyAction = (node, func, time) ->
    # console.log node
    return unless document.body.contains(node)
    return if node.checkVisibility() && func() == true

    setTimeout ->
      $readyAction node, func, time
    , time || 200

HTMLElement.prototype.$ready = (func, time) ->
  $readyAction this, func, time

counter = 1

window.CustomElement =
  attributes: (node) ->
    props = node.getAttribute('data-props')

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
          # unless ['id', 'svelte'].includes(el.name)
          #   node.removeAttribute(el.name)
          h
        , {}

    props ||= {}
    props.html ||= node.innerHTML
    id = node.getAttribute('id') || "svelte-block-#{counter++}"
    node.removeAttribute('id')
    props.$id = id
    props.$node = node
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

Svelte.bind = (name, svelte_klass) ->
  CustomElement.define name, (node, opts) ->
    # some strange bug with custom nodes double defined, this seems to fix it
    if node.parentNode
      props = { target: node, props: { props: opts }}
      svelteInstance = new svelte_klass(props)
      node.svelte = svelteInstance
      svelteInstance.onDomMount?(svelteInstance, node)
    
# # bind react elements
# bind_react: (name, klass) ->
#   @define name, (node, opts) ->
#     element = React.createElement klass, opts, node.innerHTML
#     ReactDOM.render element, node