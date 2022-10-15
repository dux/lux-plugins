# React to do
# ReactDOM.render(React.createElement(SomeReactComponent, { foo: 'bar' }), dom_node);

# get all <s-filter ...> components and run close() on them
# window.Svelte('filter', function(){ this.close() })
#
# get singleton dialog component
# el = Svelte('dialog')
# el.close()
#
# get closest ajax svelte node
# Svelte('ajax', this)
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


window.CustomElement =
  attributes: (node) ->
    props = node.getAttribute('data-props')

    if props = node.getAttribute('data-props')
      # if you want to send nested complex data, best to define as data-props encoded as JSON
      props = JSON.parse(props)
    else
      props = Array.prototype.slice
        .call(node.attributes)
        .reduce (h, el) ->
          h[el.name] = el.value;
          h
        , {}

    if node.innerHTML
      props.html = node.innerHTML
        .replace(/&lt;/g, '<')
        .replace(/&gt;/g, '>')
        .replace(/&amp;/g, '&')

      node.innerHTML = ''

    props

  # define custom element
  define: (name, func) ->
    if window.customElements
      window.addEventListener 'DOMContentLoaded', () ->
        unless customElements.get(name)
          # console.log('define: ' + name)
          customElements.define name, class extends HTMLElement
            attributeChangedCallback: (name, oldValue, newValue) ->
              console.log('attributeChangedCallback', name, oldValue, newValue)
            connectedCallback: ->
              node = @

              while node && node = node.parentNode
                break if node.nodeName == 'BODY'
                if node.nodeName.includes('-')
                  return if node.getAttribute('svelte_binded') != 'true'

              @setAttribute('svelte_binded', 'true')

              func @, CustomElement.attributes(@)

window.Svelte = (name, func) ->
  if func
    if typeof func == 'object'
      if target = func.closest("s-#{name}")
        target.svelte
      else
        null
    else
      Array.prototype.slice
        .call document.getElementsByTagName("s-#{name}")
        .forEach (el) ->
          func.bind(el.svelte)()
  else if typeof(name) == 'string'
    elements = document.getElementsByTagName("s-#{name}")

    if elements[1]
      alert("""Globed more then one svelte "#{name}" component""")

    if el = elements[0]
      el.svelte
    else
      null
  else
    alert('Svelte error: not supported')

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
