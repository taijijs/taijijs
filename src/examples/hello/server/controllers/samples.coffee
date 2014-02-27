mongoose = require('mongoose')
user = require('../models/sample').user

exports.signin = (req, res) -> res.render('users/signin', { title: 'Sign in', message: req.flash('error')})
exports.signup = (req, res) -> res.render('users/signup', { title: 'Sign up', user })
exports.signout = (req, res) -> req.logout(); res.redirect('/')
exports.session = (req, res) -> console.log 'Sign in succeed.'; res.redirect('/')
exports.create = (req, res, next) ->
  user = new User(req.body)
  message = null
  user.save (err) ->
    if err
      if (err.code == 11000 or err.code == 11001) then message = 'user name already exists'
      else message = 'Please fill all the required fields'
      return res.render '/', { message: message, user: user}
    req.logIn user, (err) ->
      if (err) then return next(err)
      return res.redirect('/')

exports.me = (req, res) -> res.jsonp(req.user || null)

exports.user = (req, res, next, id) ->
  User.findOne({ _id: id}).exec (err, user) ->
    if (err) then return next(err)
    if (!user) then return next(new Error('Failed to load User ' + id))
    req.profile = user
    next()
