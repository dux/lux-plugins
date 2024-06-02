# call just after body tag or $ -> window.MediaBodyClass.init()
# sets body class for
# mobile to  "mobile not-tablet not-desktop"
# tablet to  "not-mobile tablet not-desktop"
# desktop to "not-mobile not-tablet desktop"

window.MediaBodyClass =
  init: ->
    if document.body
      w = document.body.clientWidth

      if window.Pubsub
        Pubsub.pub 'window-resize'

      if w > 1023
        MediaBodyClass.set 'desktop'
      else if w > 767
        MediaBodyClass.set 'tablet'
      else
        MediaBodyClass.set 'mobile'

  set: (name) ->
    base = document.body.classList
    for kind in ['mobile', 'tablet', 'desktop']
      if kind == name
        base.add kind
        base.remove "not-#{kind}"
      else
        base.add "not-#{kind}"
        base.remove kind

  isMobile: ->
    document.body.classList.contains('mobile')

addEventListener "resize", MediaBodyClass.init
addEventListener 'DOMContentLoaded', MediaBodyClass.init

styles = []
points = ['mobile', 'table', 'desktop']
for el in points
  styles.push """
    .#{el}-show, .#{el}-inline, .#{el}-full, .#{el}-center { display: none !important; }
    body.#{el} {
      .#{el}-show { display: block !important; }
      .#{el}-inline { display: inline-block !important; }
      .#{el}-full { display: block !important; width: 100%; max-width: 100% !important; }
      .#{el}-center { display: flex !important; justify-content: center; }
      .#{el}-hide { display: none !important; }
    }
  """

style = document.createElement 'style'
style.id = 'mobile-tablet-desktop'
style.type = 'text/css'
style.appendChild(document.createTextNode(styles.join("\n")))
document.head.appendChild(style)

