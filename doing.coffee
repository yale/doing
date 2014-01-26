Tasks = new Meteor.Collection("tasks")

Meteor.methods
  clearAllTasks: -> Tasks.remove {}

if Meteor.isServer
  Meteor.startup = -> Tasks.remove {}

if Meteor.isClient
  Session.setDefault("selected-task", null)
  Session.setDefault("hide-completed", false)
  Template.tasks.tasks = -> 
    if Session.get("hide-completed")
      Tasks.find { completed: false }
    else
      Tasks.find {}
  
  newTask = ->
    task = Tasks.insert text: "", completed: false
    Session.set "selected-task", task
    
  Template.tasks.rendered = ->
    $("body").on 'keydown', (e) ->
      return if Session.get("selected-task")
      newTask() if (e.which == 13) && e.shiftKey
    
  Template.toolbar.events =
    "click #new-task": -> newTask()
    "click #clear-all": -> Meteor.call "clearAllTasks"
    "click #hide-completed": -> 
      Session.set "hide-completed", !Session.get("hide-completed")
      
  Template.toolbar.hidingCompleted = -> 
    Session.get("hide-completed")
  
  Template.task.isSelected = ->
    Session.get("selected-task") == @_id
    
  Template.task.checkedIfCompleted = -> 
    "checked" if @completed
    
  Template.task.events =
    "click": (e) -> 
      if e.target.className == "completed-checkbox"
        checked = $(e.target).prop("checked")
        @completed = checked
        Tasks.update @_id, @
      else
        Session.set "selected-task", @_id
        $("task-#{ @_id }").focus()
    
    "keypress": (e) ->
      console.log e.which
      if e.which == 13
        @text = $(e.target).val()
        Tasks.update @_id, @
        Session.set "selected-task", null
        newTask() if e.shiftKey
