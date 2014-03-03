# taiji view template engine

 taiji view is a high performance template engine heavily influenced by [Jade](http://jade-lang.com)
 and implemented with JavaScript for [node](http://nodejs.org). For discussion join the [Google Group](http://groups.google.com/group/taijiviewjs).

 You can test drive taiji view online [here](http://naltatis.github.com/taijiview-syntax-docs).

 [![Build Status](https://travis-ci.org/taijijs/taijiview.png?branch=master)](https://travis-ci.org/taijijs/taijiview)
 [![Dependency Status](https://gemnasium.com/taijijs/taijiview.png)](https://gemnasium.com/taijijs/taijiview)
 [![NPM version](https://badge.fury.io/js/taijiview.png)](http://badge.fury.io/js/taijiview)

## Announcements

**Deprecation of implicit script/style text-only:**

 taiji view version 0.31.0 deprecated implicit text only support for scripts and styles.  To fix this all you need to do is add a `.` character after the script or style tag.

 It is hoped that this change will make taiji view easier for newcomers to learn without affecting the power of the language or leading to excessive verboseness.

 If you have a lot of taiji view files that need fixing you can use [fix-taiji view](https://github.com/ForbesLindesay/fix-taiji view) to attempt to automate the process.

**Command line option change:**

since `v0.31.0`, `-o` is preferred for `--out` where we used `-O` before.

## Installation

via npm:

```bash
$ npm install taijiview
```

## Syntax

taiji view is a clean, whitespace sensitive syntax for writing html.  Here is a simple example:

```taiji view
doctype html
html lang=en
  head
    title= pageTitle
    script javascript:
      if (foo) bar(1 + 5)
  body
    h1: taiji view - node template engine
    #container.col
      if youAreUsingTaijiview
        p: You are amazing
      else
        p: Get on it!
      p:
        taiji view is a terse and simple templating language with a
        strong focus on performance and powerful features.
```

becomes


```html
<!DOCTYPE html>
<html lang="en">
  <head>
    <title>taiji view</title>
    <script type="text/javascript">
      if (foo) bar(1 + 5)
    </script>
  </head>
  <body>
    <h1>taiji view - node template engine</h1>
    <div id="container" class="col">
      <p>You are amazing</p>
      <p>taiji view is a terse and simple templating language with a strong focus on performance and powerful features.</p>
    </div>
  </body>
</html>
```

The official [taiji view tutorial](http://taijiview-lang.com/tutorial/) is a great place to start.  While that (and the syntax documentation) is being finished, you can view some of the old documentation [here](https://github.com/taijijs/taijiview/blob/master/taijiview.md) and [here](https://github.com/taijijs/taijiview/blob/master/taijiview-language.md)

## API

For full API, see [taijiview-lang.com/api](http://taijiview-lang.com/api/)

```js
var taijiview = require('taijiview');

// compile
var fn = taijiview.compile('string of taiji view', options);
var html = fn(locals);

// render
var html = taiji view.render('string of taiji view', merge(options, locals));

// renderFile
var html = taiji view.renderFile('filename.taiji view', merge(options, locals));
```

### Options

 - `filename`  Used in exceptions, and required when using includes
 - `compileDebug`  When `false` no debug instrumentation is compiled
 - `pretty`    Add pretty-indentation whitespace to output _(false by default)_

## Browser Support

 The latest version of taiji view can be download for the browser in standalone form from [here](https://github.com/taijijs/taijiview/raw/master/taijiview.js).  It only supports the very latest browsers though, and is a large file.  It is recommended that you pre-compile your taiji view templates to JavaScript and then just use the [runtime.js](https://github.com/taijijs/taijiview/raw/master/runtime.js) library on the client.

 To compile a template for use on the client using the command line, do:

```console
$ taijiview --client --no-debug filename.tjv
```

which will produce `filename.js` containing the compiled template.

## Command Line

After installing the latest version of [node](http://nodejs.org/), install with:

```console
$ npm install taijiview -g
```

and run with

```console
$ taijiview --help
```

## Additional Resources

Tutorials:

  - cssdeck interactive [taiji view syntax tutorial](http://cssdeck.com/labs/learning-the-taiji view-templating-engine-syntax)
  - cssdeck interactive [taiji view logic tutorial](http://cssdeck.com/labs/taijiview-templating-tutorial-codecast-part-2)
  - in [Japanese](http://blog.craftgear.net/4f501e97c1347ec934000001/title/10%E5%88%86%E3%81%A7%E3%82%8F%E3%81%8B%E3%82%8Btaiji view%E3%83%86%E3%83%B3%E3%83%97%E3%83%AC%E3%83%BC%E3%83%88%E3%82%A8%E3%83%B3%E3%82%B8%E3%83%B3)


Implementations in other languages:

  - [php](http://github.com/everzet/taijiview.php)
  - [scala](http://scalate.fusesource.org/versions/snapshot/documentation/scaml-reference.html)
  - [ruby](https://github.com/slim-template/slim)
  - [python](https://github.com/SyrusAkbary/pytaiji view)
  - [java](https://github.com/neuland/taijiview4j)

Other:

  - [Emacs Mode](https://github.com/brianc/taijiview-mode)
  - [Vim Syntax](https://github.com/digitaltoad/vim-taiji view)
  - [TextMate Bundle](http://github.com/miksago/taijiview-tmbundle)
  - [Coda/SubEtha syntax Mode](https://github.com/aaronmccall/taijiview.mode)
  - [Screencasts](http://tjholowaychuk.com/post/1004255394/taijiview-screencast-template-engine-for-nodejs)
  - [html2taiji view](https://github.com/donpark/html2taiji view) converter

## License

MIT
