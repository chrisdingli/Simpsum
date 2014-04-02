class @Simpsum
  constructor: (dataSourceLink) ->
    @dataSourceLink = dataSourceLink

    @allowedNodes = ['H1', 'H2', 'H3', 'H4', 'H5', 'H6', 'P', 'LI']
    @headingNodes = @allowedNodes[0...6]

    # DOM nodes that we will change
    @nodesToChange = []

    # Find all allowed nodes
    @findAllowedNodes(document.body)
    # Get the content
    @getContent()

  # Check number of matches
  findAllowedNodes: (node) ->
    # Match the following formats:
      # {{ simpsum_heading }}
      # {{ simpsum_heading(10) }}
    regex = /\{{2}\s{1,}(simpsum)(\([0-9]{1,}\))?\s{1,}\}{2}/

    # If current node is a permissable node
    if node.nodeName in @allowedNodes and regex.test node.innerHTML

      @nodesToChange.push
        element: node
        characterLimit: 0

      # Check if the developer has specified a max length for the placeholder
      if /\([0-9]{1,}\)/.test node.innerHTML
        matchedValue = node.innerHTML.match /\((.*?)\)/
        @nodesToChange[@nodesToChange.length - 1].characterLimit = parseInt matchedValue[1]

      # If a heading
      if node.nodeName in @headingNodes
        replaceType = 'heading'
      # If anything else
      else
        replaceType = 'paragraph'

      @nodesToChange[@nodesToChange.length - 1].type = replaceType

    # Otherwise iterate through children of node
    else
      for key, child of node.childNodes
        @findAllowedNodes child

  getContent: () ->
    @loadDummyText(@setContent)

  loadDummyText: (callback) ->
    req = new XMLHttpRequest()

    nodes = @nodesToChange

    req.addEventListener 'readystatechange', ->
      if req.readyState is 4 # ReadyState Compelte
        successResultCodes = [200, 304]
        if req.status in successResultCodes
          dummyContent = JSON.parse req.responseText
          callback(nodes, dummyContent)
        else
          console.log 'Error loading data...'

    req.open 'GET', @dataSourceLink, false
    req.send()

  setContent: (nodes, dummyContent) ->
    # Set text values for each of the nodes
    for node in nodes
      switch node.type
        when "heading"
          newContent = dummyContent.headings
        when "paragraph"
          newContent = dummyContent.paragraphs

      newContentString = newContent[Math.floor(Math.random() * newContent.length)]

      node.element.innerHTML = if node.characterLimit == 0 then newContentString else newContentString.substring(0, node.characterLimit)
