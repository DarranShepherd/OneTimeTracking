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
    projects_url = @full_url + '/Projects'
    ajax_opts = @build_ajax_options.call this, ajax_opts
    $.ajax(projects_url, ajax_opts)

  getStories: (projectId, ajax_opts = {}) ->
    stories_url = @full_url + '/Projects/' + projectId + '/Userstories/?take=500&amp;skip=500'
    ajax_opts = @build_ajax_options.call this, ajax_opts
    $.ajax(stories_url, ajax_opts)

  getTasks: (storyId, ajax_opts = {}) ->
    tasks_url = @full_url + '/Userstories/' + storyId + '/Tasks/?take=100&amp;skip=100'
    ajax_opts = @build_ajax_options.call this, ajax_opts
    $.ajax(tasks_url, ajax_opts)

  delete_entry: (eid, ajax_opts = {}) ->
    delete_url       = @full_url + '/times.asmx/' + eid
    ajax_temp = {url: delete_url, type:'DELETE'}
    ajax_opts = $.extend ajax_opts, @ajax_defaults
    ajax_opts = $.extend ajax_opts, ajax_temp
    $.ajax ajax_opts

  update_entry: (eid, tpTaskTimerId, props, tpMap, send_json_response, ajax_opts = {}) ->
    update_url = this.full_url + '/times.asmx/?skip=0&take=999&resultInclude=[id]'
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

  postTime: (task, timerId, tpMap, send_json_response, ajax_opts = {}) ->
    return if not task.hours?
    time_url = @full_url + '/Times/'
    successFunction = (resultData, textStatus, jqXhr) ->
      mapEntry = (tpMap).find (item) -> item.timerId == timerId

      mapEntry.tpTaskTimerId = resultData.Id;
      resultData.tpMap = mapEntry;
      localStorage.setItem('tempTpmap', JSON.stringify(tpMap));


    time_entry =
        Description: task.notes
        Spent: task.hours
        Remain: task.tpRemaining
        Date: task.entryDate,
        Assignable:
            Id: task.tpTask
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
