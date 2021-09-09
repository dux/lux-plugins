window._ceh_cache ||= {}

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
    alert("""Globed more then one svelte "#{name}" component""") if elements[1]

    if el = elements[0]
      el.svelte
    else
      null
  else
    alert('Svelte error: not supported')

# bind Svelte elements
  # bind custom node to class
Svelte.bind = (name, svelte_klass, klass_opts = {}) ->
  CustomElement.define name: name, inline: klass_opts.inline, func: (node, opts) ->
    return if node.is_binded
    node.is_binded = true

    in_opts = {
      props: {
        ...opts,
        node: node,
        html: if /\w+/.test(String(node.innerHTML)) then node.innerHTML else ''
      }
    }

    node.innerHTML = ''

    svelte_node = new svelte_klass({ target: node, props: in_opts })
    node.svelte = svelte_node

    # export const component = { global: 'Dialog' }
    if c = svelte_node.component
      if c.global
        window[c.global] = svelte_node

# create DOM custom element or polyfil for older browsers
window.CustomElement =
  registred: {}
  un_registred: {}

  attributes: (node) ->
    if props = node.getAttribute('data-props')
      # if you want to send nested complex data, best to define as data-props encoded as JSON
      JSON.parse(props)
    else
      Array.prototype.slice
        .call(node.attributes)
        .reduce (h, el) ->
          h[el.name] = el.value;
          h
        , {}

  # define custom element
  define: ({name, inline, func}) ->
    @registred[name] = func

    if window.customElements
      unless customElements.get(name)
        customElements.define name, class extends HTMLElement
          attributeChangedCallback: (name, oldValue, newValue) ->
            console.log('attributeChangedCallback', name, oldValue, newValue)
          connectedCallback: ->
            if inline
              # inline tags are tags with no innerHTML, we initialize faster without animation frame if able
              func @, CustomElement.attributes(@)
            else
              window.requestAnimationFrame =>
                func @, CustomElement.attributes(@)
    else
      @un_registred[name] = func


# pollyfill for old browsers (this should never trigger)
unless window.customElements
  setInterval =>
    for name, func of CustomElement.un_registred
      for node in Array.from(document.querySelectorAll("#{name}:not(.mounted)"))
        node.classList.add('mounted')
        func node, CustomElement.attributes(node)
  , 500

# # bind react elements
# bind_react: (name, klass) ->
#   @define name, (node, opts) ->
#     element = React.createElement klass, opts, node.innerHTML
#     ReactDOM.render element, node
