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
#
# Nested nodes - svelte: :inner
# if you want to have propperly rendered inner nodes that have reactivity, you need this
#
# %s-toggle-block{ id: 'mail_form' }
#   .off
#     %s-info{ svelte: :inner }
#       Email is sent
#   .on

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
          # node.removeAttribute(el.name)
          h
        , {}

    if node.innerHTML
      props.html = node.innerHTML
        .replace(/&lt;/g, '<')
        .replace(/&gt;/g, '>')
        .replace(/&amp;/g, '&')

      node.innerHTML = ''

    node.removeAttribute('style')

    id = node.getAttribute('id') || "svelte-block-#{counter++}"
    node.setAttribute('id', id)
    props ||= {}
    props._id = id
    props

  # define custom element
  define: (name, func) ->
    if window.customElements
      window.addEventListener 'DOMContentLoaded', () ->
        unless customElements.get(name)
          customElements.define name, class extends HTMLElement
            attributeChangedCallback: (name, oldValue, newValue) ->
              console.log('attributeChangedCallback', name, oldValue, newValue)
            connectedCallback: ->
              window.requestAnimationFrame =>
                func @, CustomElement.attributes(@)

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

# bind Svelte elements
  # bind custom node to class

Svelte.bind = (name, svelte_klass) ->
  CustomElement.define name, (node, opts) ->
    svelte_node = new svelte_klass({ target: node, props: { props: opts }})
    node.svelte = svelte_node

    # export const component = { global: 'Dialog' }
    if c = svelte_node.component
      if c.global
        window[c.global] = svelte_node
      for el in (c.preload || [])
        # <link rel="preload" href="main.js" as="script">
        alert el

# # bind react elements
# bind_react: (name, klass) ->
#   @define name, (node, opts) ->
#     element = React.createElement klass, opts, node.innerHTML
#     ReactDOM.render element, node
