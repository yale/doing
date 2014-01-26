Tasks = new Meteor.Collection("tasks")
Lists = new Meteor.Collection("lists")

Lists.allow
  remove: -> true
  insert: -> true
  update: -> true

Meteor.methods
  clearAllLists: -> Lists.remove { userId: Meteor.userId() } 

if Meteor.isClient
  Session.setDefault("selected-task", null)
  Session.setDefault("hide-completed", false)
  
  newList = ->
    list = Lists.insert userId: Meteor.userId()
    Session.set "editing-list", list
  
  newTask = (listId) ->
    task = Tasks.insert listId: listId, text: "", completed: false
    Session.set "selected-task", task
    
  complete = (task, complete=true) ->
    task.completed = complete
    Tasks.update task._id, task
    
  Template.toolbar.hidingCompleted = -> 
    Session.get("hide-completed")
    
  Template.toolbar.events =
    "click #new-list": -> newList()
    "click #clear-all-lists": -> Meteor.call "clearAllLists"
    "click #hide-completed": -> 
      Session.set "hide-completed", !Session.get("hide-completed")      
      
  Template.lists.lists = ->
    Lists.find { userId: Meteor.userId() }
    
  Template.list.events =
    "click #new-task": -> newTask( @_id )
    "click #delete-list": -> 
      Lists.remove( @_id )
    "click .name": (e) -> 
      return if e.target.id == "new-task"
      Session.set "editing-list", @_id
    "submit form": (e) ->
      @name = $(e.target).find("input").val()
      unless @name
        alert("Please name your list")
        return 
      Lists.update @_id, { $set: { name: @name } }
      Session.set "editing-list", null
  
  Template.list.editingList = ->
    Session.get("editing-list") == @_id
    
  Template.list.tasks = -> 
    if Session.get("hide-completed")
      Tasks.find { listId: @_id, completed: false }
    else
      Tasks.find { listId: @_id }
 
  Template.list.rendered = ->
    $("list-#{ @data._id } ul.tasks").sortable()
    $("body").on 'keydown', (e) ->
      return if Session.get("selected-task")
      newTask( @data._id ) if (e.which == 13) && e.shiftKey
      
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
        return unless @text
        Tasks.update @_id, @
        Session.set "selected-task", null
        if e.metaKey || e.ctrlKey
          complete(@) 
        else
          newTask( @listId ) unless e.shiftKey
