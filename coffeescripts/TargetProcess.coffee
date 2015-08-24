@TPClient = @TPClient || {}

class @TPClient.TargetProcess
  constructor: (@subdomain, @auth_string) ->
    @full_url = "https://#{@subdomain}.tpondemand.com/api/v1"
    @ajax_defaults =
      type: 'GET'
      dataType: 'json'
      headers:
        'Cache-Control': 'no-cache'
        'Authorization': "Basic #{@auth_string}"
        'Accept':'application/json'


  build_ajax_options: (opts = {}) -> $.extend @ajax_defaults, opts

  getProjects: (ajax_opts = {}) ->
    projects_url = @full_url + '/Projects/?take=500&amp;skip=500'
    ajax_opts = @build_ajax_options.call this, ajax_opts
    $.ajax(projects_url, ajax_opts)

  getStories: (projectId, ajax_opts = {}) ->
    stories_url = @full_url + '/Projects/' + projectId + '/Userstories/?take=500&amp;skip=500'
    ajax_opts = @build_ajax_options.call this, ajax_opts
    $.ajax(stories_url, ajax_opts)

  getStory: (storyId, ajax_opts = {}) ->
    story_url = @full_url + '/Userstories/' + storyId + '?include=[id, name, Project]'
    ajax_opts = @build_ajax_options.call this, ajax_opts
    $.ajax(story_url, ajax_opts)

  getTasks: (storyId, ajax_opts = {}) ->
    tasks_url = @full_url + '/Userstories/' + storyId + '/Tasks/?take=100&amp;skip=100'
    ajax_opts = @build_ajax_options.call this, ajax_opts
    $.ajax(tasks_url, ajax_opts)

  getBugs: (storyId, ajax_opts = {}) ->
    bugs_url = @full_url + '/Userstories/' + storyId + '/Bugs/?take=100&amp;skip=100'
    ajax_opts = @build_ajax_options.call this, ajax_opts
    $.ajax(bugs_url, ajax_opts)

  getTaskDetail : (taskId, ajax_opts = {}) ->
    taskDetail_url = @full_url + '/Tasks/' + taskId + '?skip=0&take=999&include=[id,Name, TimeRemain, Project, UserStory, EntityType]'
    ajax_opts = @build_ajax_options.call this, ajax_opts
    $.ajax(taskDetail_url, ajax_opts)

  getBugDetail : (bugId, ajax_opts = {}) ->
    bugDetail_url = @full_url + '/Bugs/' + bugId + '?skip=0&take=999&include=[id,Name,TimeRemain, Project, UserStory, EntityType]'
    ajax_opts = @build_ajax_options.call this, ajax_opts
    $.ajax(bugDetail_url, ajax_opts)

  getAssignable : (itemId, ajax_opts = {}) ->
    assignable_url = @full_url + '/Assignables/' + itemId
    ajax_opts = @build_ajax_options.call this, ajax_opts
    $.ajax(assignable_url, ajax_opts)

  delete_entry: (eid, ajax_opts = {}) ->
    delete_url       = @full_url + '/times.asmx/' + eid
    ajax_temp = {url: delete_url, type:'DELETE'}
    ajax_opts = $.extend ajax_opts, @ajax_defaults
    ajax_opts = $.extend ajax_opts, ajax_temp
    $.ajax ajax_opts

  update_entry: (eid, tpTaskTimerId, props, tpMap, send_json_response, ajax_opts = {}) ->
    update_url = this.full_url + '/times.asmx/?skip=0&take=999&resultInclude=[id]'
    
    #console.log props
    mapEntry = (tpMap).find (item) -> item.timerId == eid
    if mapEntry?
        # calculate and assign progress in tpMap
        effortDetails = mapEntry.tpTask.selected.EffortDetail
        timeAlreadySpent = parseFloat(effortDetails.TimeSpent)
        currentSpend = parseFloat(props.hours)
        totalSpent = timeAlreadySpent + currentSpend
        remaining = parseFloat(props.tpRemaining)
        actualRemaining = remaining
        progress = totalSpent / (totalSpent+actualRemaining)
        #console.log('The Progress')
        #console.log(progress)
        mapEntry.tpTask.selected.EffortDetail.Progress = progress.toFixed(2)
        localStorage.setItem('tempTpmap', JSON.stringify(tpMap))    
    
    time_entry =
        id: tpTaskTimerId
        spent: props.hours
        remain: props.tpRemaining
        description: props.notes

    postOptions =
        url: update_url
        type: 'POST'
        dataType: 'json'
        contentType: 'application/json; charset=utf-8'
        data: JSON.stringify(time_entry)

    ajax_opts = $.extend ajax_opts, @ajax_defaults
    ajax_opts = $.extend ajax_opts, postOptions
    $.ajax ajax_opts

  postTime: (task, timerId, tpMap, isStopped, oneShotEntry, send_json_response, ajax_opts = {}) ->
    return if not task.hours?
    time_url = @full_url + '/Times/'
    successFunction = (resultData, textStatus, jqXhr) ->
      mapEntry = (tpMap).find (item) -> item.timerId == timerId

      #console.log('Into Success Func')
      #console.log(resultData)
      
      if isStopped and mapEntry.tpTask? and mapEntry.tpTask.selected?
        # calculate and assign progress in tpMap
        effortDetails = mapEntry.tpTask.selected.EffortDetail
        timeAlreadySpent = if !oneShotEntry then parseFloat(effortDetails.TimeSpent) else 0
        currentSpend = parseFloat(task.hours)
        totalSpent = timeAlreadySpent + currentSpend
        remaining = parseFloat(task.tpRemaining)
        actualRemaining = remaining
        progress = totalSpent / (totalSpent+actualRemaining)
        mapEntry.tpTask.selected.EffortDetail.Progress = progress.toFixed(2)
      
      mapEntry.hours = task.hours
      mapEntry.tpRemaining = task.tpRemaining
      mapEntry.tpTaskTimerId = resultData.Id
      mapEntry.TimerStopped = isStopped
      resultData.tpMap = mapEntry
      
      localStorage.setItem('tempTpmap', JSON.stringify(tpMap))
      return

    if task.tpTask? and task.tpTask.selected?
      assignedId = if task.tpTask.selected.EntityType is 'Bug' then task.tpStory.selected.Id else task.tpTask.selected.Id
    else if task.tpStory?
      assignedId = task.tpStory.selected.Id

    time_entry =
        Description: task.notes
        Spent: task.hours
        Remain: task.tpRemaining
        Date: task.entryDate,
        Assignable:
            Id: assignedId
    time_struct =
        url: time_url
        type: 'POST'
        dataType: 'json'
        contentType: 'application/json; charset=utf-8'
        data: JSON.stringify(time_entry)
        success: successFunction
    ajax_opts = $.extend ajax_opts, @ajax_defaults
    ajax_opts = $.extend ajax_opts, time_struct
    #ajax_opts = @build_ajax_options time_struct
    $.ajax(ajax_opts)


window.TargetProcess = @TPClient.TargetProcess
