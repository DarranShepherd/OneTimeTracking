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
    

window.TargetProcess = TargetProcess