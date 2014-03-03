###
 extensible
 pragma
 configurable: attriblue separator, interplation delimitor, text starter, text ender
###

path = require('path')
extname = path.extname

peasy = require 'peasy'

nodes = require('./nodes')

class Ast
class Generator

exports = module.exports = class Parser extends peasy.Parser
  constructor: ->
    super

    {memo, orp, char, may, any, eoi, identifier, follow, wrap, list, literal, select} = self = @

    lex = @lex =
      tjBibindLeft: '{{'
      tjBibindRight: '}}'
      tjUpbindLeft: '^{'
      tjUpbindRight: '}'
      tjDownbindLeft: '!{'
      tjDownbindRight: '}'
      tjInitbindLeft: '{'
      tjInitbindRight: '}'
      keyword: ->
      operator: ->
      token: ->
      next: ->
      attrsLeftDelimiter: -> true
      attrsRightDelimiter: -> follow(orp(blockStart, lineComment))()
      identifier: identifier

    identifier = -> lex.identifier()

    ast = @ast = new Ast()

    generator = @generator = new Generator()

    nonQuotedAttrValue = ->  # non quoted string or expression
    quotedAttrValue = -> # quoted string or expression
    @attrValue = -> orp(nonQuotedAttrValue, quotedAttrValue)
    @attrAssign = may(-> lex.op.attrAssign() and attrValue())
    @tagAttr = -> (name = identifier()) and (value=attrAssign()) and [name, value]
    @attrs = -> wrap(list(self.tagAttr, lex.attrSeparator), lex.attrsLeftDelimiter, lex.attrsRightDelemiter)
    lineTailStmt = ->
    tagContent = -> lineTailStmt() and mayIndentBlockStmt()
    htmlTag = ->

    @tagStmt = -> console.log('tag stmt'); self.attrs() and tagContent()
    keywordIn = lex.keyword('in')
    @forStmt = -> identifier() and may(-> comma() and identifier()) and keywordIn() and expression and block()
    @ifStmt = -> expression() and block()

    @pragmaDirectives =
      'css-coding-style' : ->

    @pragmaStmt = -> (name = pragmaName()) and select self.pragmaDiretives[name]

    @includeStmt = ->
    @switchStmt = ->
    @commentStmt = ->
    @blockStmt = ->
    @extendsStmt = ->
    @textStmt = ->
    @replaceStmt = ->
    @errorOnStartStmt = ->

    @statement = -> select lex.next(),
      tag: self.tagStmt
      'for': self.forStmt
      'if': self.ifStmt
      'switch': self.switchStmt
      pragma: self.pragmaStmt
      include: self.includeStmt
      block: self.blockStmt
      replace: self.replaceStmt # replace block in layout with content
      extends: self.extendsStmt
      textStarter: self.textStmt
      comment: self.commentStmt
      #inlinecomment: inlineCommentStmt
      '': self.errorOnStartStmt # 'default': error
    @statements = any(self.statement)
    @root = @statements

    @init = (text='', start=0) -> self.text = text; self.cur = start; self
    @parse = (text='', start=0) -> self.init(text, start).root()
    @parseFile = (file) ->

parser =exports.parser = new Parser()

exports.parse = (text, cursor=0, start=parser.root) ->
  if typeof cursor=='function' then  start = cursor; cursor = 0
  parser.init(text, cursor)
  start()
