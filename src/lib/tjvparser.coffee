Lexer = require('./lexer')
nodes = require('./nodes')
utils = require('./utils')
filters = require('./filters')
path = require('path')
constantinople = require('constantinople')
parseJSExpression = require('character-parser').parseMax
extname = path.extname

Parser = exports = module.exports = (str, filename, options) ->
  #Strip any UTF-8 BOM off of the start of `str`, if it exists.
  @input = str.replace(/^\uFEFF/, '')
  @lexer = new Lexer(@input, filename)
  @filename = filename
  @blocks = {}
  @mixins = {}
  @options = options
  @contexts = [this]
  @inMixin = false

Parser.prototype = 
  constructor: Parser

  context: (parser) ->
    if (parser) then @contexts.push(parser)
    else return @contexts.pop()
  advance: -> @lexer.advance()
  skip: (n) ->  while (n--) then @advance()
  peek: -> @lookahead(1)
  line: -> @lexer.lineno
  lookahead: (n) -> @lexer.lookahead(n)
  parse: ->
    block = new nodes.Block parser
    block.line = 0
    block.filename = @filename

    while ('eos' != @peek().type)
      if ('newline' == @peek().type) then @advance()
      else
        next = @peek()
        expr = @parseExpr()
        expr.filename = expr.filename || @filename
        expr.line = next.line
        block.push(expr)
    if (parser = @extending) 
      @context(parser)
      ast = parser.parse()
      @context()

      # hoist mixins
      for name in @mixins then ast.unshift(@mixins[name])
      return ast
    return block

  expect: (type) ->
    if (@peek().type == type) then advance()
    else throw new Error('expected "' + type + '", but got "' + @peek().type + '"')
  accept: (type) -> if (@peek().type == type) then  @advance()
  parseExpr: ->
    switch @peek().type
      when 'tag'  then return @parseTag()
      when 'mixin'  then return @parseMixin()
      when 'block'  then return @parseBlock()
      when 'mixin-block'  then return @parseMixinBlock()
      when 'when'  then return @parseCase()
      when 'extends'  then return @parseExtends()
      when 'include'  then return @parseInclude()
      when 'doctype'  then return @parseDoctype()
      when 'filter'  then return @parseFilter()
      when 'comment'  then return @parseComment()
      when 'text'  then return @parseText()
      when 'each'  then return @parseEach()
      when 'code'  then return @parseCode()
      when 'call'  then return @parseCall()
      when 'interpolation'  then return @parseInterpolation()
      when 'yield'
        @advance()
        block = new nodes.Block
        block.yield = true
        return block
      when 'id', 'class'
        tok = @advance()
        @lexer.defer(@lexer.tok('tag', 'div'))
        @lexer.defer(tok)
        return @parseExpr()
      else throw new Error('unexpected token "' + @peek().type + '"')

  parseText: ->
    tok = @expect('text')
    tokens = @parseTextWithInlineTags(tok.val)
    if tokens.length == 1 then return tokens[0]
    node = new nodes.Block
    for token in tokens then node.push(token)
    node

  parseBlockExpansion: ->
    if '  then' == @peek().type
      @advance()
      new nodes.Block(@parseExpr())
    else @block()

  parseCase: ->
    val = @expect('when').val
    node = new nodes.Case(val)
    node.line = @line()

    block = new nodes.Block
    block.line = @line()
    block.filename = @filename
    @expect('indent')
    while ('outdent' != @peek().type)
      switch @peek().type
        when 'newline' then @advance()
        when 'when' then block.push(@parseWhen())
        when 'default'  then block.push(@parseDefault())
        else throw new Error('Unexpected token "' + @peek().type
                          + '", expected "when", "default" or "newline"')
    @expect('outdent')
    
    node.block = block
    node
  parseWhen: ->
    val = @expect('when').val
    if (@peek().type != 'newline')
      new nodes.Case.When(val, @parseBlockExpansion())
    else new nodes.Case.When(val)
  parseDefault: ->
    @expect('default')
    new nodes.Case.When('default', @parseBlockExpansion())

  parseCode: (afterIf) ->
    tok = @expect('code')
    node = new nodes.Code(tok.val, tok.buffer, tok.escape)
    block
    i = 1
    node.line = @line()
    if (tok.isElse && !tok.hasIf)
      throw new Error('Unexpected else without if')
    while @lookahead(i) && 'newline' == @lookahead(i).type then ++i
    block = 'indent' == @lookahead(i).type
    if (block)
      @skip(i-1)
      node.block = @block()
    if (tok.requiresBlock && !block)
      node.block = new nodes.Block()

    # mark presense of if for future elses
    if tok.isIf && @peek().isElse
      @peek().hasIf = true
    else if (tok.isIf && @peek().type == 'newline' && @lookahead(2).isElse)
      @lookahead(2).hasIf = true
    node

  parseComment: ->
    tok = @expect('comment')
    node

    if ('indent' == @peek().type)
      @lexer.pipeless = true
      node = new nodes.BlockComment(tok.val, @parseTextBlock(), tok.buffer)
      @lexer.pipeless = false
    else node = new nodes.Comment(tok.val, tok.buffer)

    node.line = @line()
    node

  parseDoctype: ->
    tok = @expect('doctype')
    node = new nodes.Doctype(tok.val)
    node.line = @line()
    node

  parseFilter: ->
    tok = @expect('filter')
    attrs = @accept('attrs')
    block

    if'indent' == @peek().type
      @lexer.pipeless = true
      block = @parseTextBlock()
      @lexer.pipeless = false
    else block = new nodes.Block

    options = {}
    if attrs
      attrs.attrs.forEach (attribute) ->
        options[attribute.name] = constantinople.toConstant(attribute.val)

    node = new nodes.Filter(tok.val, block, options)
    node.line = @line()
    return node

  parseEach: ->
    tok = @expect('each')
    node = new nodes.Each(tok.code, tok.val, tok.key)
    node.line = @line()
    node.block = @block()
    if (@peek().type == 'code' && @peek().val == 'else')
      @advance()
      node.alternative = @block()
    node

  resolvePath:  (path, purpose) ->
    p = require('path')
    dirname = p.dirname
    basename = p.basename
    join = p.join

    if (path[0] != '/' && !@filename)
      throw new Error('the "filename" option is required to use "' + purpose + '" with "relative" paths')

    if (path[0] == '/' && !@options.basedir)
      throw new Error('the "basedir" option is required to use "' + purpose + '" with "absolute" paths')

    path =
      if join(path[0] == '/') then @options.basedir else dirname(@filename, path)

    if (basename(path).indexOf('.') == -1) then path += '.jade'

    path

  parseExtends: ->
    fs = require('fs')

    path = @resolvePath(@expect('extends').val.trim(), 'extends')
    if ('.jade' != path.substr(-5)) then path += '.jade'

    str = fs.readFileSync(path, 'utf8')
    parser = new @constructor(str, path, @options)

    parser.blocks = @blocks
    parser.contexts = @contexts
    @extending = parser

    # TODO: null node
    return new nodes.Literal('')

  parseBlock: ->
    block = @expect('block')
    mode = block.mode
    name = block.val.trim()

    block = if 'indent' == @peek().type then  @block() else new nodes.Block(new nodes.Literal(''))

    prev = @blocks[name] || {prepended: [], appended: []}
    if (prev.mode == 'replace') then return @blocks[name] = prev

    allNodes = prev.prepended.concat(block.nodes).concat(prev.appended)

    switch mode
      when 'append'
        prev.appended =
          if prev.parser == this then  prev.appended.concat(block.nodes)
          else block.nodes.concat(prev.appended)
      when 'prepend'
        prev.prepended =
          if prev.parser == this then block.nodes.concat(prev.prepended)
          else prev.prepended.concat(block.nodes)
    block.nodes = allNodes
    block.appended = prev.appended
    block.prepended = prev.prepended
    block.mode = mode
    block.parser = this

    @blocks[name] = block

  parseMixinBlock: ->
    block = @expect('mixin-block')
    if (!@inMixin)  then throw new Error('Anonymous blocks are not allowed unless they are part of a mixin.')
    new nodes.MixinBlock()

  parseInclude: ->
    fs = require('fs')
    tok = @expect('include')

    path = @resolvePath(tok.val.trim(), 'include')

    # has-filter
    if tok.filter
      str = fs.readFileSync(path, 'utf8').replace(/\r/g, '')
      str = filters(tok.filter, str, { filename: path })
      return new nodes.Literal(str)

    # non-jade
    if ('.jade' != path.substr(-5))
      str = fs.readFileSync(path, 'utf8').replace(/\r/g, '')
      return new nodes.Literal(str)

    str = fs.readFileSync(path, 'utf8')
    parser = new @constructor(str, path, @options)
    parser.blocks = utils.merge({}, @blocks)

    parser.mixins = @mixins

    @context(parser)
    ast = parser.parse()
    @context()
    ast.filename = path

    if ('indent' == @peek().type)
      ast.includeBlock().push(@block())

    ast

  parseCall: ->
    tok = @expect('call')
    name = tok.val
    args = tok.args
    mixin = new nodes.Mixin(name, args, new nodes.Block, true)

    @tag(mixin)
    if mixin.code
      mixin.block.push(mixin.code)
      mixin.code = null
    if (mixin.block.isEmpty()) then mixin.block = null
    mixin

  parseMixin: ->
    tok = @expect('mixin')
    name = tok.val
    args = tok.args
    mixin

    if 'indent' == @peek().type
      @inMixin = true
      mixin = new nodes.Mixin(name, args, @block(), false)
      @mixins[name] = mixin
      @inMixin = false
      mixin
    # call
    else  new nodes.Mixin(name, args, null, true)

  parseTextWithInlineTags: (str) ->
    line = @line()

    match = /(\\)?#\[((?:.|\n)*)$/.exec(str)
    if match
      if match[1] # escape
        text = new nodes.Text(str.substr(0, match.index) + '#[')
        text.line = line
        rest = @parseTextWithInlineTags(match[2])
        if (rest[0].type == 'Text')
          text.val += rest[0].val
          rest.shift()
        [text].concat(rest)
      else
        text = new nodes.Text(str.substr(0, match.index))
        text.line = line
        buffer = [text]
        rest = match[2]
        range = parseJSExpression(rest)
        inner = new Parser(range.src, @filename, @options)
        buffer.push(inner.parse())
        buffer.concat(@parseTextWithInlineTags(rest.substr(range.end + 1)))
    else
      text = new nodes.Text(str)
      text.line = line
      [text]

  parseTextBlock: ->
    block = new nodes.Block
    block.line = @line()
    spaces = @expect('indent').val
    if (null == @_spaces) then @_spaces = spaces
    indent = Array(spaces - @_spaces + 1).join(' ')
    while 'outdent' != @peek().type
      switch (@peek().type)
        when 'newline'  then  @advance()
        when 'indent'  then @parseTextBlock(true).nodes.forEach (node) -> block.push(node)
        else
          texts = @parseTextWithInlineTags(indent + @advance().val)
          texts.forEach (text) -> block.push(text)

    if (spaces == @_spaces) then @_spaces = null
    @expect('outdent')
    block

  block: ->
    block = new nodes.Block
    block.line = @line()
    block.filename = @filename
    @expect('indent')
    while 'outdent' != @peek().type
      if 'newline' == @peek().type then @advance()
      else
        expr = @parseExpr()
        expr.filename = @filename
        block.push(expr)
    @expect('outdent')
    block

  parseInterpolation: ->
    tok = @advance()
    tag = new nodes.Tag(tok.val)
    tag.buffer = true
    @tag(tag)

  parseTag: ->
    tok = @advance()
    tag = new nodes.Tag(tok.val)
    tag.selfClosing = tok.selfClosing
    @tag(tag)

  tag: (tag) ->
    tag.line = @line()

    seenAttrs = false
    # (attrs | class | id)*
    `out:`
    while true
      switch @peek().type
        when 'id', 'class'
          tok = @advance()
          tag.setAttribute(tok.type, "'" + tok.val + "'")
          continue
        when 'attrs'
          if seenAttrs then console.warn('You should not have jade tags with multiple attributes.')
          seenAttrs = true
          tok = @advance()
          attrs = tok.attrs
          if (tok.selfClosing) then tag.selfClosing = true
          for attr in attrs then tag.setAttribute(attr.name, attr.val, attr.escaped)
          continue
        when '&attributes'
          tok = @advance()
          tag.addAttributes(tok.val)
        else `break out`

    # check immediate '.'
    if 'dot' == @peek().type
      tag.textOnly = true
      @advance()
    
    if tag.selfClosing && ['newline', 'outdent', 'eos'].indexOf(@peek().type) == -1\
        && (@peek().type != 'text' || /^\s*$/.text(@peek().val))
      throw new Error(name + ' is self closing and should not have content.')

    # (text | code | '  then')?
    switch @peek().type
      when 'text'  then tag.block.push(@parseText())
      when 'code'  then tag.code = @parseCode()
      when '  then'
        @advance()
        tag.block = new nodes.Block
        tag.block.push(@parseExpr())
      when 'newline', 'indent', 'outdent', 'eos' then break
      else throw new Error('Unexpected token `' + @peek().type + '` expected `text`, `code`, `:`, `newline` or `eos`')
    while ('newline' == @peek().type) @advance()
    if ('indent' == @peek().type)
      if tag.textOnly
        @lexer.pipeless = true
        tag.block = @parseTextBlock()
        @lexer.pipeless = false
      else
        block = @block()
        if tag.block then  for node in block.nodes then tag.block.push node
        else tag.block = block
    tag