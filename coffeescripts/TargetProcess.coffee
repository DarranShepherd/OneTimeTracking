class TargetProcess
  constructor: (@subdomain, @auth_string) ->
    @full_url = "https://#{@subdomain}.tpondemand.com/api/v1"
    @ajax_defaults =
      type: 'GET'
      dataType: 'json'
      headers:
        'Cache-Control': 'no-cache'
        'Authorization': "Basic #{@auth_string}"
        'Accept':'application/json'
  
  ###
  Build an AJAX options object by merging with @ajax_defaults

  @private
  @param {Object} opts
  @returns {Object}
  ###
  build_ajax_options = (opts = {}) -> $.extend @ajax_defaults, opts
    
  getProjects: (ajax_opts = {}) ->
    projects_url = @full_url + '/Projects'
    ajax_opts = build_ajax_options.call this, ajax_opts
    $.ajax(projects_url, ajax_opts)
    
  getStories: (projectId, ajax_opts = {}) ->
    stories_url = @full_url + '/Projects/' + projectId + '/Userstories'
    ajax_opts = build_ajax_options.call this, ajax_opts
    $.ajax(stories_url, ajax_opts)
    
  getTasks: (storyId, ajax_opts = {}) -> 
    tasks_url = @full_url + '/Userstories/' + storyId + '/Tasks'
    ajax_opts = build_ajax_options.call this, ajax_opts
    $.ajax(tasks_url, ajax_opts)
    
  postTime: (description, spent, remain, spentDate, id, ajax_opts = {}) ->
    time_url = @full_url + '/Times/'
    time_struct = 
        data:
            Description: description
            Spent: spent
            Remain: remain
            Date: spentDate,
            Assignable:
                Id: id
    ajax_opts = build_ajax_options time_struct
    $.ajax(time_url, ajax_opts)
  

window.TargetProcess = TargetProcess