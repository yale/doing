Tasks = new Meteor.Collection("tasks")
Lists = new Meteor.Collection("lists")

Meteor.methods
  clearAllTasks: -> Tasks.remove {}

if Meteor.isClient
  Session.setDefault("selected-task", null)
  Session.setDefault("hide-completed", false)
  
  newList = ->
    debugger
    list = Lists.insert userId: Meteor.userId()
    Session.set "editing-list", list
  
  newTask = ->
    task = Tasks.insert text: "", completed: false
    Session.set "selected-task", task
    
  complete = (task, complete=true) ->
    task.completed = complete
    Tasks.update task._id, task
    
  Template.toolbar.hidingCompleted = -> 
    Session.get("hide-completed")
    
  Template.toolbar.events =
    "click #clear-all": -> Meteor.call "clearAllTasks"
    "click #hide-completed": -> 
      Session.set "hide-completed", !Session.get("hide-completed")      
      
  Template.lists.lists = ->
    Lists.find { userId: Meteor.userId() }
    
  Template.lists.events = ->
    "click #new-list": -> 
      debugger
      newList()
      
  Template.list.events =
    "click #new-task": -> newTask()
    "click .name": -> Session.set "editing-list", @_id
    "keypress": (e) ->
      if e.which == 13
        @name = $(e.target).val()
        Lists.update @_id, @
        Session.set "editing-list", null
    
  Template.list.editingList = ->
    Session.get("editing-list") == @_id
    
  Template.tasks.tasks = -> 
    if Session.get("hide-completed")
      Tasks.find { completed: false }
    else
      Tasks.find {}
 
  Template.tasks.rendered = ->
    $("body").on 'keydown', (e) ->
      return if Session.get("selected-task")
      newTask() if (e.which == 13) && e.shiftKey
      
  Template.task.isSelected = ->
    Session.get("selected-task") == @_id
    
  Template.task.checkedIfCompleted = -> 
    "checked" if @completed
    
  Template.task.events =
    "click": (e) -> 
      if e.target.className == "completed-checkbox"
        checked = $(e.target).prop("checked")
        complete(@, checked)
      else
        Session.set "selected-task", @_id
        $("task-#{ @_id }").focus()
    
    "keypress": (e) ->
      if e.which == 13
        @text = $(e.target).val()
        Tasks.update @_id, @
        Session.set "selected-task", null
        if e.metaKey || e.ctrlKey
          complete(@) 
        else
          newTask() unless e.shiftKey
