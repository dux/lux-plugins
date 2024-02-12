# call just after body tag or $ -> window.MediaBodyClass.init()
# sets body class for
# mobile to  "mobile not-tablet not-desktop"
# tablet to  "not-mobile tablet not-desktop"
# desktop to "not-mobile not-tablet desktop"

window.MediaBodyClass =
  init: ->
    if document.body
      w = window.innerWidth
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

addEventListener 'DOMContentLoaded', ->
  MediaBodyClass.init()

  $(document.head).append("""
    <style>
      body.mobile .mobile-hide { display: none !important; }
      body.mobile .mobile-block { display: block !important; }
      body.mobile .mobile-full { display: block !important; width: 100% !important; max-width: 100% !important; }
      body.mobile .mobile-center { display: flex; justify-content: center; }

      body.desktop .mobile-show, body.tablet .mobile-show { display: none !important }
    </style>
  """)
