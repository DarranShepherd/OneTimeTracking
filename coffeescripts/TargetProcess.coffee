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
    stories_url = @full_url + '/Projects/' + projectId + '/Userstories'
    ajax_opts = @build_ajax_options.call this, ajax_opts
    $.ajax(stories_url, ajax_opts)
    
  getTasks: (storyId, ajax_opts = {}) -> 
    tasks_url = @full_url + '/Userstories/' + storyId + '/Tasks'
    ajax_opts = @build_ajax_options.call this, ajax_opts
    $.ajax(tasks_url, ajax_opts)
    
  postTime: (description, spent, remain, spentDate, id, ajax_opts = {}) ->
    time_url = @full_url + '/Times/'
    time_entry = 
        Description: description
        Spent: spent
        Remain: remain
        Date: spentDate,
        Assignable:
            Id: id
    time_struct =
        url: time_url
        type: 'POST'
        dataType: 'json'
        contentType: 'application/json; charset=utf-8'
        data: JSON.stringify(time_entry)

    ajax_opts = @build_ajax_options time_struct
    $.ajax(ajax_opts)
  

window.TargetProcess = @TPClient.TargetProcess