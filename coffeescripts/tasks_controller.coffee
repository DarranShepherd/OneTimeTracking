###
Angular.js Popup Tasks Controller
###

app = angular.module 'hayfeverApp', [ 'ngAnimate', 'ngSanitize', 'ui.select' ]

tasks_controller = ($scope, $sanitize) ->
  # DEBUG MODE: set this to true to show debug content in popup
  $scope.debug_mode            = true
  $scope.form_visible          = false
  $scope.table_spinner_visible = false
  $scope.form_spinner_visible  = false
  $scope.runaway_timer         = false
  $scope.active_timer_id       = 0
  $scope.current_hours         = 0.0
  $scope.total_hours           = 0.0
  $scope.tasks                 = []
  $scope.storiesForProject     = []
  $scope.tasksForStory         = []
  $scope.tpMap                 = []
  $scope.stoppingTimer         = false
  $scope.remainingRequired     = false
  $scope.stoppingAndLoggingTimer = false
  $scope.form_task             =
    project: null
    task: null
    hours: null
    notes: null
    tpproject:
        selected: undefined
    tpstory:
        selected: undefined
    tptask:
        selected: undefined
    tpremaining: null
    currentTimer: null
  # console.debug $scope.form_visible

  # Grab background application data
  chrome.runtime.sendMessage { method: 'get_entries' }, (resp) ->
    #console.log(resp)
    (
       (
            # Get timer with same id
            existingTimer = _(resp.timers).find (item) -> item.id == mapEntry.timerId
            (
                
                progress = 0
                if mapEntry.tpTask? and mapEntry.tpTask.selected.EffortDetail?
                    if existingTimer.running or mapEntry.TimerStopped is false
                        # calculate progress on the basis of hours spent and allocated
                        effortDetails = mapEntry.tpTask.selected.EffortDetail
                        timeAlreadySpent = parseFloat(effortDetails.TimeSpent)
                        spent = parseFloat(existingTimer.hours)
                        totalSpent = timeAlreadySpent + spent
                        remaining = parseFloat(effortDetails.TimeRemain)
                        actualRemaining = if remaining - spent < 0 then 0 else remaining - spent
                        progress = totalSpent / (totalSpent+actualRemaining)
                    else 
                        progress = parseFloat(mapEntry.tpTask.selected.EffortDetail.Progress)
                        
                progress = progress * 100
                progress = progress.toFixed(0)
                #console.log(progress)

                existingTimer.progress = progress
                existingTimer.progress = progress
                (
                    existingTimer.stopped = true 
                    existingTimer.running = false
                ) if mapEntry.TimerStopped? and mapEntry.TimerStopped is true
            ) if existingTimer?
       ) for mapEntry in resp.tpMap
    ) if resp.tpMap.length > 0
    
    $scope.harvest_url   = resp.harvest_url
    $scope.targetProcess_url   = resp.targetProcess_url
    $scope.authorized    = resp.authorized
    $scope.projects      = resp.projects
    $scope.clients       = resp.clients
    $scope.timers        = resp.timers
    $scope.prefs         = resp.preferences
    $scope.current_hours = resp.current_hours
    $scope.total_hours   = resp.total_hours
    $scope.current_task  = resp.current_task
    $scope.tpProjects    = resp.tpProjects
    $scope.theClient     = new TargetProcess(resp.tpClient.subdomain, resp.tpClient.auth_string)
    $scope.tpMap         = resp.tpMap
    $scope.$apply()

    console.debug "Get Entries"
    #console.debug $scope.timers
    #console.debug $scope.tpMap

  $scope.refresh = ->
    $scope.table_spinner_visible = true
    
    chrome.runtime.sendMessage { method: 'refresh_hours' }, (resp) ->
        (
           (
                # Get timer with same id
                existingTimer = _(resp.timers).find (item) -> item.id == mapEntry.timerId
                # existingTimer.running = false if $scope.stoppingAndLoggingTimer
                $scope.stoppingAndLoggingTimer = false
                (
                    progress = 0
                    if mapEntry.tpTask? and mapEntry.tpTask.selected.EffortDetail?
                        if existingTimer.running or mapEntry.TimerStopped is false
                            # calculate progress on the basis of hours spent and allocated
                            effortDetails = mapEntry.tpTask.selected.EffortDetail
                            timeAlreadySpent = parseFloat(effortDetails.TimeSpent)
                            spent = parseFloat(existingTimer.hours)
                            totalSpent = timeAlreadySpent + spent
                            remaining = parseFloat(effortDetails.TimeRemain)
                            actualRemaining = if remaining - spent < 0 then 0 else remaining - spent
                            progress = totalSpent / (totalSpent+actualRemaining)
                        else 
                            progress = parseFloat(mapEntry.tpTask.selected.EffortDetail.Progress)
                        
                    progress = progress * 100
                    progress = progress.toFixed(0)
                    #console.log(progress)

                    existingTimer.progress = progress
                    (
                        existingTimer.stopped = true 
                        existingTimer.running = false
                    ) if mapEntry.TimerStopped? and mapEntry.TimerStopped is true
                ) if existingTimer?
            

           ) for mapEntry in resp.tpMap #when mapEntry.TimerStopped? and mapEntry.TimerStopped is true
        ) if resp.tpMap.length > 0
        $scope.harvest_url   = resp.harvest_url
        $scope.authorized    = resp.authorized
        $scope.projects      = resp.projects
        $scope.clients       = resp.clients
        $scope.timers        = resp.timers
        $scope.current_hours = resp.current_hours
        $scope.prefs         = resp.preferences
        $scope.total_hours   = resp.total_hours
        $scope.current_task  = resp.current_task
        $scope.tpProjects    = resp.tpProjects
        $scope.theClient     = new TargetProcess(resp.tpClient.subdomain, resp.tpClient.auth_string)
        $scope.tpMap         = resp.tpMap
        $scope.$apply()

    chrome.runtime.sendMessage { method: 'get_preferences' }, (resp) ->
      $scope.prefs                 = resp.preferences
      $scope.table_spinner_visible = false
      $scope.$apply()

  $scope.add_timer = ->
    $scope.form_task.notes = $('#task-notes').val()
    $scope.form_spinner_visible = true

    task =
      project_id: $scope.form_task.project
      task_id: $scope.form_task.task
      hours: $scope.form_task.hours
      notes: $scope.form_task.notes
      tpProject: $scope.form_task.tpproject ? null
      tpStory: $scope.form_task.tpstory ? null
      tpTask: $scope.form_task.tptask ? null
      tpSpent: $scope.form_task.hours
      tpRemaining: $scope.form_task.tpremaining
      entryDate: (new Date()).toJSON()

    chrome.runtime.sendMessage
        method: 'add_timer'
        active_timer_id: $scope.active_timer_id
        task: task
        (resp) ->
            #console.log 'Resp.tpMap is'
            #console.log resp.tpMap
            $scope.tpMap = resp.tpMap
            #localStorage.setItem('tempTpmap',JSON.stringify(resp.tpMap))
            $scope.form_spinner_visible = false
            $scope.hide_form()
            $scope.refresh()
    return

  $scope.tp_project_change = (showingMappedEntry) ->
    $scope.form_spinner_visible = true
    $scope.storiesForProject = []
    $scope.tasksForStory = []

    if not showingMappedEntry
        $scope.form_task.tpstory =
            selected: undefined
        $scope.form_task.tptask =
            selected: undefined
    tpClient = $scope.theClient
    tpStories = tpClient.getStories $scope.form_task.tpproject.selected.Id
    # projectTitle = $('#tp-project-select option:selected').val()
    #$('#task-notes').val('#' + $scope.form_task.tpproject)
    window.strProject = '#' + $scope.form_task.tpproject.selected.Id
    $('#task-notes').val(window.strProject)
    tpStories.success (json) =>
        stories = json.Items
        $scope.storiesForProject.push({ Id: story.Id, Name: story.Name }) for story in stories
        $scope.form_spinner_visible = false
        $scope.$apply()
        return

  $scope.project_change = ->
    $scope.tasks = []
    current_project = _($scope.projects).find (p) -> p.id == parseInt($scope.form_task.project)
    
    tasks = current_project.tasks
    developmentTask = _.filter tasks, (task) -> 
         task.name == 'Development'
    if (developmentTask.length > 0)
      $scope.form_task.task = developmentTask[0].id

    tasks.forEach (task) ->
      task.billable_text = if task.billable then 'Billable' else 'Non Billable'
      $scope.tasks.push task

  $scope.story_change = (showingMappedEntry) ->
    window.strStory = ' - #' + $scope.form_task.tpstory.selected.Id
    $('#task-notes').val(window.strProject + window.strStory)
    $scope.form_spinner_visible = true
    $scope.tasksForStory = []

    if not showingMappedEntry
        $scope.form_task.tptask =
            selected: undefined
    
    tpClient = $scope.theClient
    tpTasks = tpClient.getTasks $scope.form_task.tpstory.selected.Id
    tpTasks.success (json) =>
        $scope.tasksForStory = _.map(json.Items, createTaskDetail)
        $scope.form_spinner_visible = false
        $scope.$apply()
        return

  $scope.getColour = (input) -> 
    if (input.EntityState.Name == 'Done')
        return 'LightGray'
    return 'Black'

  $scope.task_change = ->
      #taskTitle = $('#tp-task-select option:selected').text()
      #currentText = $('#task-notes').val()
      #currentText = currentText.concat(' - ', taskTitle)
      #currentText = currentText.concat(' - #', $scope.form_task.tptask)
      #$('#task-notes').val(currentText)
      
      window.strTask = ' - #'+ $scope.form_task.tptask.selected.Id
      $('#task-notes').val(window.strProject + window.strStory + window.strTask)
      
      $scope.form_spinner_visible = true
      tpClient = $scope.theClient
      
      #console.log('tptaskdetail')
      #console.log($scope.form_task.tptask)
      #console.log($scope.form_task)
      
      tpTaskDetail  = tpClient.getTaskDetail $scope.form_task.tptask.selected.Id

      tpTaskDetail.success (json) =>
            taskDetail = json

            timeRemainUpdated = $scope.form_task.tpremaining
            if ($scope.form_task.currentTimer? and !$scope.form_task.currentTimer.stopped) or $scope.active_timer_id == 0
                timeRemainUpdated = if $scope.form_task.hours != null then (if (taskDetail.TimeRemain - $scope.form_task.hours) > 0 then (taskDetail.TimeRemain - $scope.form_task.hours) else 0) else taskDetail.TimeRemain
                timeRemainUpdated = +(Math.round(timeRemainUpdated + "e+2")  + "e-2")
            
            $('#task-hours-remaining').val(timeRemainUpdated)
            $scope.form_task.tpremaining = timeRemainUpdated

            $scope.form_spinner_visible = false
            $scope.$apply()
            return

  $scope.set_task_notes = ->
    # Possible future implementation placeholder
    projectId = $scope.form_task.tpproject.selected.Id
    storyId = $scope.form_task.tpstory.selected.Id
    taskId = $scope.form_task.tptask.selected.Id
    currentNotes = $('#task-notes').val()
    return    

  $scope.toggle_timer = (timer_id) ->
    $scope.table_spinner_visible = true
    chrome.runtime.sendMessage { method: 'toggle_timer', timer_id: timer_id }, (resp) ->
      $scope.table_spinner_visible = false
      $scope.refresh()

  $scope.delete_timer = (timer_id) ->
    $scope.table_spinner_visible = true
    @retrivedJson=[];
    retrievedObject = localStorage.getItem('tempTpmap');
    @retrivedJson = JSON.parse(retrievedObject);
    mapEntry = _(@retrivedJson).find (item) -> item.timerId == timer_id
    id = mapEntry.tpTaskTimerId;
    chrome.runtime.sendMessage { method: 'delete_timer', timer_id: timer_id, tpTaskTimerId: id }, (resp) ->
      $scope.table_spinner_visible = false
      $scope.refresh()

  $scope.stop_timer = (timer_id) =>
    $scope.stoppingTimer = true
    $scope.show_form(timer_id)
    #$scope.table_spinner_visible = true
    #$scope.refresh()

  $scope.stop_and_log = (timer_id) =>
    # need to stop the timer in harvest
    # need to log the entry in tp
    # there is duplication here but I think I need to also set certain things here such as removing stop, pause and potentially notes button

    # first check if time rmaining is set
    return if $scope.active_timer_id is 0

    currentTimer = _($scope.timers).find (item) -> item.id == $scope.active_timer_id

    runningTimer = if currentTimer.running? then currentTimer.running else false

    if $scope.form_task.tpremaining is `undefined` or $scope.form_task.tpremaining is null
        $scope.remainingRequired = true
        return
    else
        $scope.remainingRequired = false

    $scope.form_task.notes = $('#task-notes').val()
    $scope.form_spinner_visible = true
    task =
      project_id: $scope.form_task.project
      task_id: $scope.form_task.task
      hours: $scope.form_task.hours
      notes: $scope.form_task.notes
      tpProject: $scope.form_task.tpproject ? null
      tpStory: $scope.form_task.tpstory ? null
      tpTask: $scope.form_task.tptask ? null
      tpSpent: $scope.form_task.hours
      tpRemaining: $scope.form_task.tpremaining
      entryDate: (new Date()).toJSON()
    
    chrome.runtime.sendMessage
        method: 'stop_timer'
        timer_id: $scope.active_timer_id
        task: task
        running: runningTimer
        (resp) ->
            #console.log 'Resp.tpMap is'
            #console.log resp.tpMap
            $scope.tpMap = resp.tpMap
            $scope.form_spinner_visible = false
            $scope.stoppingAndLoggingTimer = true
            $scope.hide_form()
            $scope.refresh()
    return

  $scope.show_form = (timer_id=0) ->
    $scope.active_timer_id = timer_id
    $scope.reset_form_fields()

    unless $scope.active_timer_id is 0
      timer = _($scope.timers).find (item) -> item.id == $scope.active_timer_id

      if timer
        #console.log timer
        $scope.form_task.currentTimer = timer
        $scope.form_task.project = parseInt timer.project_id, 10
        $scope.form_task.task = parseInt timer.task_id, 10
        $scope.form_task.hours = timer.hours
        $scope.form_task.notes = timer.notes
        $scope.project_change()

        # Now show the tpThings
        mapEntry = _($scope.tpMap).find (item) -> item.timerId == timer_id
        if mapEntry and mapEntry.tpProject?
            $scope.form_task.tpproject = 
                selected: mapEntry.tpProject.selected
            $scope.form_task.tpstory =
                selected: mapEntry.tpStory.selected
            $scope.form_task.tptask =
                selected: mapEntry.tpTask.selected
            $scope.form_task.tpremaining = mapEntry.tpRemaining

            # trigger change
            $scope.tp_project_change(true)
            $scope.story_change(true)
            $scope.task_change(true)
           
            $('#task-notes').val(timer.notes)
    $scope.form_visible = true

  $scope.getStoryById = (searchData) ->
    if ($scope)
      if (searchData.startsWith('#'))
        tpClient = $scope.theClient
        # Get the Task with all Detail we need
        tpStory = tpClient.getStory searchData.substring(1)
        tpStory.success (storyJson) ->
          selectedStory = storyJson

          # Get related User Stories to populate the Story List
          tpRelatedStories = tpClient.getStories selectedStory.Project.Id
          tpRelatedStories.success (relatedStoriesJson) ->
            $scope.storiesForProject.push({ Id: story.Id, Name: story.Name }) for story in relatedStoriesJson.Items
            selectedUserStory = _.filter $scope.storiesForProject, (story) -> 
                story.Id == selectedTask.UserStory.Id     
          
          # Get related tasks to populate the Task List
          tpRelatedTasks = tpClient.getTasks selectedStory.Id
          tpRelatedTasks.success (relatedTasksJson) =>
            $scope.tasksForStory = _.map(relatedTasksJson.Items, createTaskDetail)  

          $scope.form_task.tpstory = selected: selectedStory
          $scope.form_task.tpproject = selected: selectedStory.Project   
          window.strProject = '#' + selectedStory.Project.Id
          window.strStory = '#' + selectedStory.Id
          $('#task-notes').val(window.strProject + ' - ' + window.strStory)
          $scope.form_spinner_visible = false
          $scope.$apply()                     

  $scope.getTaskById = (searchData) ->   
    if ($scope)
      if (searchData.startsWith('#')) 
        tpClient = $scope.theClient

        # Get the Task with all Detail we need
        tpTask = tpClient.getTaskDetail searchData.substring(1)

        tpTask.success (taskJson) =>
          selectedTask = taskJson

          # Get related tasks to populate the Task List
          tpRelatedTasks = tpClient.getTasks selectedTask.UserStory.Id
          tpRelatedTasks.success (relatedTasksJson) =>
            $scope.tasksForStory = _.map(relatedTasksJson.Items, createTaskDetail)

          # Get list of User Stories
          tpStories = tpClient.getStories selectedTask.Project.Id
          tpStories.success (userStoriesJson) =>
            $scope.storiesForProject.push({ Id: story.Id, Name: story.Name }) for story in userStoriesJson.Items
            selectedUserStory = _.filter $scope.storiesForProject, (story) -> 
                story.Id == selectedTask.UserStory.Id

            # Now that we have all the data we can populate the form
            $scope.form_task.tpstory = selected: selectedUserStory[0]
            $scope.form_task.tptask = selected: selectedTask
            $scope.form_task.tpproject = selected: selectedTask.Project

          window.strProject = '#' + selectedTask.Project.Id
          window.strStory = '#' + selectedTask.Id
          window.strTask = '#' + selectedTask.Id
          $('#task-notes').val(window.strProject + ' - ' + window.strStory + ' - ' + window.strTask)
          $scope.form_spinner_visible = false
          $scope.$apply()

  $scope.hide_form = ->
    $scope.form_visible = false
    $scope.storiesForProject = []
    $scope.stoppingTimer = false if $scope.stoppingTimer is true

  $scope.reset_form_fields = ->
    $scope.form_task =
      project: null
      task: null
      hours: null
      notes: null

  $scope.toggle_spinners = ->
    $scope.table_spinner_visible = !$scope.table_spinner_visible
    $scope.form_spinner_visible = !$scope.form_spinner_visible

  $scope.updateTpRemaining = ->
    # Potential calculation for future
    return
    existingRemaining = $scope.form_task.tptask.selected.EffortDetail.EffortToDo
    newRemaining = existingRemaining - $scope.form_task.hours if existingRemaining > 0
    if newRemaining > 0 then $scope.form_task.tpremaining = newRemaining.toFixed(2) else $scope.form_task.tpremaining = 0

  $scope.getActualProgress = (progress) ->
    if Number.isFinite(Number(progress)) then progress else '';

createTaskDetail = (task) ->
  return {
    Id: task.Id
    Name: task.Name
    EntityState: task.EntityState
    EffortDetail:
        Effort: task.Effort
        EffortCompleted: task.EffortCompleted
        EffortToDo: task.EffortToDo
        Progress: task.Progress
        TimeSpent: task.TimeSpent
        TimeRemain: task.TimeRemain
    }
clock_time_filter = ->
  (input) ->
    input.toClockTime()

app.controller 'TasksController', [ '$scope', tasks_controller ]
app.filter 'clockTime', clock_time_filter
