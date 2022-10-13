extends Node

signal posthog_event_posted

enum events_dashboard { NEW, DELETE, NEW_WIDGET, EDIT_WIDGET, DUPLICATE_WIDGET}
enum events_config { NEW = 100, DELETE, EDIT }
enum events_datasource {NEW = 200, STATUS}

var events:= {
	events_dashboard.NEW : "ui.dashboard.new",
	events_dashboard.DELETE : "ui.dashboard.delete",
	events_dashboard.NEW_WIDGET : "ui.dashboard.widget-new",
	events_dashboard.EDIT_WIDGET : "ui.dashboard.widget-edit",
	events_dashboard.DUPLICATE_WIDGET : "ui.dashboard.widget-duplicate",
	events_config.NEW : "ui.config.new",
	events_config.DELETE : "ui.config.delete",
	events_config.EDIT : "ui.config.edit",
	events_datasource.NEW : "ui.datasource.new",
	events_datasource.STATUS : "ui.datasource.status",
}

var posthog_url := "https://analytics.some.engineering/batch"
var api_key_url := "https://cdn.some.engineering/posthog/public_api_key"

var api_key : String = ""
var last_api_timestamp = 0
var api_key_refresh_time = 3600

var event_queue : Array = []
var max_queue_size : int = 100

var session_id : String = ""
var user_id : String = ""

func _ready():
	var post_timer := Timer.new()
	post_timer.wait_time = 10
	add_child(post_timer)
	post_timer.start()
	post_timer.connect("timeout", self, "post_events")
	
	if OS.has_feature("HTML5"):
		session_id = JavaScript.eval("getSessionId()")
		user_id = JavaScript.eval("getUserId()")
	else:
		user_id = str(OS.get_unique_id())


func refresh_api_key():
	if Time.get_unix_time_from_system() - last_api_timestamp > api_key_refresh_time:
		var request := HTTPRequest.new()
		add_child(request)
		request.request(api_key_url)
		api_key = (yield(request,"request_completed")[3] as PoolByteArray).get_string_from_utf8().strip_edges()
		request.queue_free()


func posthog_event_data(event : int, context := {}, counters := {}) -> Dictionary:
	var data : Dictionary = {
		"system" : "ui",
		"kind" : events[event],
		"context" : {
			"session-id": session_id,
			"user-id": user_id
		},
		"counters" : counters,
		"at" : "%s.000Z" % Time.get_datetime_string_from_system(true) # Need to add milliseconds to work
	}
	data.context.merge(context)
	return data


func event(event, properties := {}):
	var body = posthog_event_data(event, properties)
	
	if event_queue and event_queue.size() > max_queue_size:
		post_events()
		yield(self, "posthog_event_posted")
		if event_queue.size() > 0:
			print("Force clear the queue: posthog request failed but the queue is full...")
			event_queue.clear()
			
	event_queue.append(body)


func post_events():
	if not event_queue or event_queue.size() == 0:
		return
	API.analytics(JSON.print(event_queue), self)


func _on_analytics_done(error : int, response):
	if response.response_code == 204:
		event_queue.clear()
	else:
		print("Posting to analytics endpoint failed, not clearing the queue")
