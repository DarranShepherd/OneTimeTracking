###
Harvest API Wrapper

Depends on:
  - jQuery
  - Sugar.js
  - Underscore.js
###

class Harvest
  constructor: (@subdomain, @auth_string) ->
    @full_url = "https://#{@subdomain}.harvestapp.com"
    @ajax_defaults =
      type: 'GET'
      dataType: 'json'
      headers:
        'Cache-Control': 'no-cache'
        'Authorization': "Basic #{@auth_string}"

  ###
  Build URL for and API call

  @private
  @param {String[]} arguments
  @returns {String}
  ###
  build_url = ->
    url = @full_url
    $.each arguments, (i, v) ->
      url += "/#{v}"
    "#{url}.json"

  ###
  Build an AJAX options object by merging with @ajax_defaults

  @private
  @param {Object} opts
  @returns {Object}
  ###
  build_ajax_options = (opts = {}) -> $.extend @ajax_defaults, opts

  ###
  Get API rate limit status

  @returns {jqXHR}
  ###
  rate_limit_status: (ajax_opts = {}) ->
    url = build_url.call this, 'account', 'rate_limit_status'
    $.ajax url, build_ajax_options.call(this, ajax_opts)

  ###
  Get all timesheet entries (and project list) for a given day

  @param {Date} date
  @param {Boolean} async
  @returns {jqXHR}
  ###
  get_day: (date, ajax_opts = {}) ->
    day_url   = if date is 'today' then build_url.call(this, 'daily') else build_url.call(this, 'daily', date.getDOY(), date.getFullYear())
    ajax_opts = build_ajax_options.call this, ajax_opts
    $.ajax day_url, ajax_opts

  ###
  Convenience method for getting today's entries

  @param {Boolean} async
  @returns {jqXHR}
  ###
  get_today: (ajax_opts = {}) ->
    @get_day('today', ajax_opts)

  ###
  Get an individual timer by ID

  @param {Number} eid
  @param {Boolean} async
  @returns {jqXHR}
  ###
  get_entry: (eid, ajax_opts = {}) ->
    url = build_url.call this, 'daily', 'show', eid
    ajax_opts = build_ajax_options.call this, ajax_opts
    $.ajax url, ajax_opts

  ###
  Find runaway timers from yesterday

  @param {Function} callback
  @param {Boolean} async
  @returns {jqXHR}
  ###
  runaway_timers: (callback = $.noop, ajax_opts = {}) ->
    yesterday = Date.create 'yesterday'
    request = @get_day yesterday, ajax_opts

    request.success (json) ->
      if json.day_entries?
        entries = json.day_entries
        runaways = _(entries).filter (entry) -> entry.hasOwnProperty 'timer_started_at'
        callback.call entries, runaways

  ###
  Toggle a single timer on/off

  @param {Number} eid
  @param {Boolean} async
  @returns {jqXHR}
  ###
  toggle_timer: (eid, ajax_opts = {}) ->
    url       = build_url.call this, 'daily', 'timer', String(eid)
    ajax_opts = build_ajax_options.call this, ajax_opts
    $.ajax url, ajax_opts

  ###
  Create a new entry, optional starting its timer on creation

  @param {Object} props
  @param {Boolean} async
  @returns {jqXHR}
  ###
  add_entry: (props, tpMap, send_json_response, ajax_opts = {}) ->
    url       = build_url.call this, 'daily', 'add'
    #console.log 'Adding Entry'
    #console.log props
    successFunction = (resultData, textStatus, jqXhr) ->
        console.log resultData
        tpMap.push mapEntry =
            timerId: resultData.id
            tpProject: props.tpProject
            tpStory: props.tpStory
            tpTask: props.tpTask
            tpTaskTimerId:0
        resultData.tpMap = tpMap        
        localStorage.setItem('tempTpmap', JSON.stringify(tpMap));
        if props.hours != null
         chrome.runtime.sendMessage
          method: 'add_tp_timer'
          timer_id: resultData.id
          task: props
          tpMap: tpMap

        send_json_response resultData
        return
    # commented as global ajax options were getting modified
    #ajax_opts = build_ajax_options.call this, $.extend(ajax_opts, type: 'POST', data: props, success: successFunction)
    postOptions =
        type: 'POST'
        data: props
        success: successFunction
    ajax_opts = $.extend ajax_opts, @ajax_defaults
    ajax_opts = $.extend ajax_opts, postOptions
    $.ajax url, ajax_opts

  stop_timer: (eid, props, running, tpMap, send_json_response, ajax_opts = {}) ->
    #url = build_url.call this, 'daily', 'timer', String(eid)
    #ajax_opts = build_ajax_options.call this, ajax_opts
    #$.ajax url, ajax_opts

    url       = build_url.call this, 'daily', 'update', String(eid)
    successFunction = (resultData, textStatus, jqXhr) ->
        # check if entry exists
        existingMap = _(tpMap).find (item) -> item.timerId == resultData.id
        if existingMap is null    
            tpMap.push mapEntry =
                timerId: resultData.id
                tpProject: props.tpProject
                tpStory: props.tpStory
                tpTask: props.tpTask
        resultData.tpMap = tpMap
        send_json_response resultData
        return
    # ajax_opts = build_ajax_options.call this, $.extend(ajax_opts, type: 'POST', data: props)
    postOptions =
        type: 'POST'
        data: props
        success: successFunction
    ajax_opts = $.extend ajax_opts, @ajax_defaults
    ajax_opts = $.extend ajax_opts, postOptions
    $.ajax url, ajax_opts
    # toggle_timer eid,{} if running

  ###
  Delete an entry

  @param {Number} eid
  @param {Boolean} async
  @returns {jqXHR}
  ###
  delete_entry: (eid, ajax_opts = {}) ->
    delete_url       = build_url.call this, 'daily', 'delete', String(eid)
    #ajax_opts = build_ajax_options.call this, $.extend(ajax_opts, type: 'DELETE')
    ajax_temp = {url: delete_url, type:'DELETE'}
    ajax_opts = $.extend ajax_opts, @ajax_defaults
    ajax_opts = $.extend ajax_opts, ajax_temp
    $.ajax ajax_opts

  ###
  Update an entry

  @param {Number} eid
  @param {Object} props
  @param {Boolean} async
  @returns {jqXHR}
  ###
  update_entry: (eid, props, tpMap, send_json_response, ajax_opts = {}) ->
    url       = build_url.call this, 'daily', 'update', String(eid)
    successFunction = (resultData, textStatus, jqXhr) ->
        # check if entry exists
        existingMap = _(tpMap).find (item) -> item.timerId == resultData.id
        if existingMap is null
            tpMap.push mapEntry =
                timerId: resultData.id
                tpProject: props.tpProject
                tpStory: props.tpStory
                tpTask: props.tpTask
        resultData.tpMap = tpMap
        send_json_response resultData
        return
    # ajax_opts = build_ajax_options.call this, $.extend(ajax_opts, type: 'POST', data: props)
    postOptions =
        type: 'POST'
        data: props
        success: successFunction
    ajax_opts = $.extend ajax_opts, @ajax_defaults
    ajax_opts = $.extend ajax_opts, postOptions
    $.ajax url, ajax_opts

window.Harvest = Harvest
