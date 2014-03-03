exports.Node = class Node
  constructor: ->

exports.Tag = class Tag extends Node
  constructor: (@name, @attrs, @content) ->
  render: (model) ->
    result = '<'+@name
    attrs = @attrs.render()
    if attrs then result+' '+attrs+'>'+@content.render()+'</'+@name+'>'
    else result+'>'+@content.render()+'</'+@name+'>'

exports.tag = tag = (name, attrs, content) -> new Tag(name, attrs, content)

tagNames = "p div a html head body img link script"
tagNames = tagNames.split(' ')
console.log tagNames.join(' ')
for name in tagNames
  tag[name] = do (name=name) -> (attrs, content) -> new Tag(name, attrs, content)

exports.Attrs = class Attrs extends Node
  constructor: (@list) ->
  render: (model) -> (attr.render() for attr in @list).join ' '
exports.attrs = (attrList=[]) -> new Attrs(attrList)

exports.Attr = class Attr extends Node
  constructor: (@name, @value) ->
  render: (model) -> @name+'="'+@value+'"'
exports.attr = (name, value) -> new Attr(name, value)

exports.For = class For extends Node
  constructor: (@forVar, @range, @body, @index) ->
exports['for'] = (forVar, range, body, index) -> new For(forVar, range, body, index)

exports.If = class If extends Node
  constructor: (@test, @body, @else_) ->
exports['if'] = (test, body, else_) -> new If(test, body, else_)

exports.Switch = class Switch extends Node
  constructor: (@expression, @cases, @defaultCase) ->
exports['switch'] = (expression, cases, defaultCase) -> new Switch(expression, cases, defaultCase)

exports.Include = class Include extends Node
  constructor: (@path) ->
exports.include = (path) -> new Include(path)

exports.Block = class Block extends Node
  constructor: (@name, @defaultContent) ->
exports.block = (name, defaultContent) -> new Block(name, defaultContent)

exports.Replace = class Replace extends Node
  constructor: (@content, @name='') ->
exports.replace = (content, name) -> new Tag(content, name)

exports.Interpolation = class Interpolation extends Node
  construtor: (@expresson) ->
exports.interpolation = (expresson) -> new Interpolation(expresson)

exports.Binary = class Binary extends Node
  constructor: (@operator, @left, @right) ->
exports.binary = (operator, left, right) -> new Binary(operator, left, right)

exports.Unary = class Unary extends Node
  constructor: (@operator, @operand) ->
exports.unary = (operator, operand) -> new Unary(operator, operand)

exports.Variable = class Variable extends Node
  constructor: (@identifier) ->
  render: (model) -> model[@identifer]?.toString() or ''
exports.variable = (identifier) -> new Variable(identifier)

exports.Text = class Text extends Node
  # text can be an array of TextPiece and Interpolation
  constructor: (@content) ->
  render: (model) -> (@content.render?.bind(@content) or @content.toString?.bind(@content))(model)

exports.text = (content) -> new Text(content)

exports.TextPiece = class TextPiece extends Node
  constructor: (@text) ->
exports.textPiece = (text) -> new TextPiece(text)
