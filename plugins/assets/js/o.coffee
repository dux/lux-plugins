# capitqalized method to return self
# O({foo:123, aasda:2323, bar: null, zcc: ''}).Slice('foo', 'bar').compact() -> {foo: 123}

stringObject = (data) =>
  @data = data
  # O('/admin/uild:{ulid}').template({ulid: 123}) -> '/admin/uild:123'
  @template = (o) => @data.replace /\{(\w+)\}/g, (_, r1) => o[r1] 
  @

plainObject = (data) =>
  @data = data
  @map = (func) => Object.entries(@data).map((el, i) => func(el[0], el[1], i))
  @keys = () => Object.keys(@data)
  @values = () => Object.values(@data)
  @qs = () => Object.entries(@data).map(([k,v]) => "#{k}=#{escape(v)}").join('&')
  @css = () =>
    out = Object.entries(@data).map ([k,v]) =>
      v = if typeof v == 'string' then v else "#{Math.round(v)}px"
      "#{k}: #{v};"
    out.join(' ')
  @key = (n) => @data.hasOwnProperty(n)
  @props = () =>
    Object.entries(@data)
      .map(([k,v]) =>
        v = String(v).replaceAll('"', '&quot;')
        "#{k}=" + '"' + v + '"'
      ).join(' ')
  @delete = (key) =>
    o = @data[key]
    delete @data[key]
    o
  @compact = (func) =>
    out = {}
    @map (k, v) => out[k] = v if !k.includes('$') && ![undefined, null, 'undefined', ''].includes(v) && k == k.toLowerCase()
    out
  @Compact = (...args) ->
    O @compact(...args)
  @slice = (...args) ->
    # O({foo: 123, style: 'nice'}).slice('width', 'style', 'class')
    out = {}
    for key in args
      val = data[key]
      out[key] = val if val != undefined
    out
  @Slice = (...args) ->
    O @slice(...args)
  @except = (...args) ->
    # O({foo: 123, bar: 2, style: 'nice'}).except('style', 'bar')
    out = {}
    for k, v of @data
      if args.indexOf(k) == -1
        out[key] = v
    out
  @merge = (o) ->
    # O({foo: 123, style: 'nice'}).slice('width', 'style', 'class')
    Object.assign(@data, o)
  @

arrayObject = (data) =>
  @data = data
  @notNil = => @data.filter((el) => ![null, undefined].includes(el))
  @compact = => @data.filter((el) => ![null, undefined, 'undefined', ''].includes(el))
  @prev = (el) ->
    i = @data.indexOf(el)
    if i > 0 then @data[i - 1] else null
  @next = (el) ->
    i = @data.indexOf(el)
    if i > -1 then @data[i + 1] else null
  @map = (func) =>
    copy = []
    @data.forEach((el, i) => copy.push func(el, i))
    copy
  @

O = window.O = (o) =>
  if typeof o == 'string'
    stringObject(o)
  else if Array.prototype.isPrototypeOf(o)
    arrayObject o
  else if Object.prototype.isPrototypeOf(o) 
    plainObject o

O.trim = (t, l) =>
  t = String t
  if t.length > l
    t.slice(0, l) + '...'
  else
    t


