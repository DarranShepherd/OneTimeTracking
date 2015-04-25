###
Background Page Application Class
###

class BackgroundApplication
  # @private
  start_refresh_interval = ->
    console.debug "Setting refresh interval to every %d milliseconds", @refresh_interval_time
    @refresh_interval = setInterval @refresh_hours, @refresh_interval_time

  # @private
  register_message_listeners = ->
    console.debug "Registering asynchronous message listeners"

    chrome.runtime.onMessage.addListener (request, sender, send_response) =>
      send_json_response = (json) =>
          console.log 'Logging in BGAPP'
          # console.log @todays_entry_tp_map
          # json = $.extend json, { tpMap: @todays_entry_tp_map }
          # json.tpMap = @todays_entry_tp_map
          console.log json
          send_response json
      methods =
        refresh_hours: =>
          @refresh_hours =>
            send_response
              authorized: @authorized
              projects: @projects
              tpProjects: @tpProjectList
              tpClient: @tpClient
              clients: @clients
              timers: @todays_entries
              total_hours: @total_hours
              current_hours: @current_hours
              current_task: @current_task
              harvest_url: if @client.subdomain then @client.full_url else null
              preferences: @preferences
              tpMap: @todays_entry_tp_map
        get_entries: =>
          send_response
            authorized: @authorized
            projects: @projects
            tpProjects: @tpProjectList
            tpClient: @tpClient
            clients: @clients
            timers: @todays_entries
            total_hours: @total_hours
            current_hours: @current_hours
            current_task: @current_task
            harvest_url: if @client.subdomain then @client.full_url else null
            targetProcess_url: if @tp_subdomain then "https://#{@tp_subdomain}.tpondemand.com" else null
            preferences: @preferences
            tpMap: @todays_entry_tp_map
        get_tp_stories: (id) =>
            @tp_get_stories id
        get_preferences: =>
          @get_preferences (prefs) => send_response preferences: prefs
        add_timer: =>
          tpTaskTimerId=0
          retrievedObject = localStorage.getItem('tempTpmap')
          #@todays_entry_tp_map = JSON.parse(retrievedObject) if retrievedObject !=null
          if retrievedObject !=null
            @todays_entry_tp_map = JSON.parse(retrievedObject)
            if request.active_timer_id != 0
             mapEntry = _(@todays_entry_tp_map).find (item) -> item.timerId == request.active_timer_id
             tpTaskTimerId = mapEntry.tpTaskTimerId
          if request.active_timer_id != 0
            result = @client.update_entry request.active_timer_id, request.task, @todays_entry_tp_map, send_json_response
            if tpTaskTimerId != 0
              @tpClient.update_entry request.active_timer_id, tpTaskTimerId, request.task, @todays_entry_tp_map, send_json_response
          else
            result = @client.add_entry request.task, @todays_entry_tp_map, send_json_response
          return
          # retrievedObject = localStorage.getItem('tempTpmap')
          # @todays_entry_tp_map = JSON.parse(retrievedObject) if retrievedObject !=null
          # #@tpClient.postTime request.task.notes, request.task.hours, request.task.tpRemaining, request.task.entryDate, request.task.tpTask
          # if request.active_timer_id != 0
          #   result = @client.update_entry request.active_timer_id, request.task, @todays_entry_tp_map, send_json_response
          # else
          #   result = @client.add_entry request.task, @todays_entry_tp_map, send_json_response
          # return
          #
          # this is now moved to client's add entry function
          ###
          result.success (resultData, textStatus, jqXhr) ->
            # console.log(@todays_entry_tp_map)
            jsonData = $.extend(resultData, request.task)
            # mapEntry = @todays_entry_tp_map.find (item) -> item.id == resultData.
            try
                @todays_entry_tp_map.push ({ a: '10' })
                console.log todays_entry_tp_map
            catch e
                console.log(e)
            send_json_response resultData
            return
          ###
        add_tp_timer: =>
          @tpClient.postTime(request.task, request.timer_id, request.tpMap);
        stop_timer: =>
          #@tpClient.postTime request.task.notes, request.task.hours, request.task.tpRemaining, request.task.entryDate, request.task.tpTask
          @tpClient.postTime request.task, request.timer_id, @todays_entry_tp_map
          result = @client.stop_timer request.timer_id, request.task, request.running, @todays_entry_tp_map, send_json_response
          if request.running
              result = @client.toggle_timer request.timer_id
              result.complete send_json_response
          return
          # result.complete send_json_response
        toggle_timer: =>
          result = @client.toggle_timer request.timer_id
          result.complete send_json_response
        delete_timer: =>
          if request.tpTaskTimerId != 0
           @tpClient.delete_entry(request.tpTaskTimerId);
          result = @client.delete_entry request.timer_id
          result.complete send_json_response
        reload_app: =>
          send_response reloading: true
          window.location.reload true
        get_targetProcess_client: =>
            send_response @tpClient

      if methods.hasOwnProperty request.method
        console.debug "Received message from popup: %s", request.method
        methods[request.method].call this
        true
      else
        console.warn "Unknown method: %s", request.method
        false

  constructor: (@subdomain, @auth_string, @tp_subdomain, @tp_auth_string) ->
    @client                = new Harvest(@subdomain, @auth_string)
    @tpClient              = new TargetProcess(@tp_subdomain, @tp_auth_string)
    @version               = '0.3.6'
    @authorized            = false
    @total_hours           = 0.0
    @current_hours         = 0.0
    @current_task          = null
    @badge_flash_interval  = 0
    @refresh_interval      = 0
    @refresh_interval_time = 36e3
    @todays_entries        = []
    @projects              = []
    @tpProjectList         = []
    @preferences           = {}
    @timer_running         = false
    @todays_entry_tp_map   = []

    chrome.browserAction.setTitle title: "One Time Tracking"
    register_message_listeners.call this
    start_refresh_interval.call this if @subdomain and @auth_string

    retrievedObject = localStorage.getItem('tempTpmap')
    @todays_entry_tp_map = JSON.parse(retrievedObject) if retrievedObject !=null and this.todays_entry_tp_map.length == 0

  # Class Methods
  @get_auth_data: (callback) ->
    chrome.storage.local.get [ 'harvest_subdomain', 'harvest_auth_string', 'harvest_username', 'tp_subdomain', 'tp_username', 'tp_auth_string' ], (items) ->
      callback(items)

  @get_preferences: (callback) ->
    chrome.storage.local.get 'hayfever_prefs', (items) ->
      callback(items)

  @migrate_preferences: (callback) ->
    options =
      harvest_subdomain: localStorage['harvest_subdomain']
      harvest_auth_string: localStorage['harvest_auth_string']
      harvest_username: localStorage['harvest_username']
    prefs = if localStorage['hayfever_prefs'] then JSON.parse(localStorage['hayfever_prefs']) else null
    options.hayfever_prefs = prefs if prefs

    chrome.storage.local.set options, ->
      localStorage.removeItem 'harvest_subdomain'
      localStorage.removeItem 'harvest_auth_string'
      localStorage.removeItem 'harvest_username'
      localStorage.removeItem 'hayfever_prefs'
      callback(options)

  # Instance Methods
  get_preferences: (callback = $.noop) ->
    BackgroundApplication.get_preferences (items) =>
      @preferences = items.hayfever_prefs || {}
      callback(items)

  set_badge: =>
    @get_preferences()
    prefs = @preferences
    badge_color = $.hexColorToRGBA prefs.badge_color

    switch prefs.badge_display
      when 'current'
        badge_text = if prefs.badge_format is 'decimal' then @current_hours.toFixed(2) else @current_hours.toClockTime()
      when 'total'
        badge_text = if prefs.badge_format is 'decimal' then @total_hours.toFixed(2) else @total_hours.toClockTime()
      else
        badge_text = ''

    chrome.browserAction.setBadgeBackgroundColor color: badge_color
    chrome.browserAction.setBadgeText text: badge_text

  tp_get_stories: (tpProjectId) =>
    tpStories = @tpClient.getStories(tpProjectId)
    tpStories.success (json) =>
        console.log 'Stories'
        console.log json
        return

  refresh_hours: (callback = $.noop) =>
    console.debug 'refreshing hours'
    @get_preferences()
    prefs        = @preferences
    todays_hours = @client.get_today()
    tpProjects = @tpClient.getProjects()

    tpProjects.success (json) =>
        projects = json.Items
        @tpProjectList = []
        @tpProjectList.push({ Id: project.Id, Name: project.Name }) for project in projects
        return

    todays_hours.success (json) =>
      @authorized   = true
      @current_task = null
      total_hours   = 0.0
      current_hours = ''

      @projects = json.projects
      @todays_entries = json.day_entries

      # Add up total hours by looping thru timesheet entries
      $.each @todays_entries, (i, v) =>
        total_hours += v.hours

        project = _.find @projects, (proj) -> proj.name is v.project and proj.client is v.client
        v.code  = if _.isEmpty project then '' else project.code

        if v.hasOwnProperty('timer_started_at') and v.timer_started_at
          current_hours = parseFloat(v.hours)
          v.running = true
          @current_task = v

        @todays_entries[i] = v
      @total_hours = total_hours

      if typeof current_hours is 'number'
        @current_hours = current_hours
        @timer_running = true
        chrome.browserAction.setTitle
          title: "Currently working on: #{@current_task.client} - #{@current_task.project}"
        @start_badge_flash() if @badge_flash_interval is 0 and prefs.badge_blink
      else
        @current_hours = 0.0
        @timer_running = false
        chrome.browserAction.setTitle title: 'One Time Tracking'
        @stop_badge_flash() if @badge_flash_interval isnt 0

      @set_badge()
      callback.call(@todays_entries)

    todays_hours.error (xhr, text_status, error_thrown) =>
      console.warn 'Error refreshing hours!'

      if xhr.status == 401
        # Authentication failure
        @authorized = false
        chrome.browserAction.setBadgeBackgroundColor color: [255, 0, 0, 255]
        chrome.browserAction.setBadgeText text: '!'

  badge_color: (alpha) =>
    color = $.hexColorToRGBA @preferences.badge_color, alpha
    chrome.browserAction.setBadgeBackgroundColor color: color

  badge_flash: (alpha) =>
    @badge_color 255
    setTimeout @badge_color, 1000, 100

  start_badge_flash: ->
    console.debug 'Starting badge blink'
    @badge_flash_interval = setInterval @badge_flash, 2000

  stop_badge_flash: ->
    console.debug 'Stopping badge blink'
    clearInterval @badge_flash_interval
    @badge_flash_interval = 0
    @badge_color 255

window.BackgroundApplication = BackgroundApplication
