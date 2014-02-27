_ = require('lodash')

mongoose = require('mongoose')
Project = mongoose.model('Project')

exports.create = (req, res) ->
  project = new Project(req.body)
  project.user = req.user
  project.save (err) ->
    if err then res.send('users/signup', {errors: err.errors, project: project })
    else res.jsonp(project)


exports.project = (req, res, next, id) ->
  Project.load id, (err, project) ->
    if err then return next(err)
    if !project then return next(new Error('Failed to load project ' + id))
    req.project = project
    next()

exports.update = (req, res)  ->
  project = req.project
  project = _.extend(project, req.body)
  project.save (err)  ->
    if err then res.send('users/signup', {errors: err.errors, project: project})
    else res.jsonp(project)

exports.destroy = (req, res)  ->
  project = req.project
  project.remove (err)  ->
    if err then res.send('users/signup', {errors: err.errors, project: project})
    else res.jsonp(project)

exports.show = (req, res)  ->
  res.jsonp(req.project)

exports.all = (req, res) ->
  Project.find().sort('-created').populate('user', 'name username').exec (err, projects) ->
    if err then res.render('error', { status: 500 })
    else res.jsonp(projects)
