extends Node

signal analytics_event_posted

enum EventsDashboard{ NEW, DELETE, NEW_WIDGET, EDIT_WIDGET, DUPLICATE_WIDGET}
enum EventsConfig { NEW = 100, DELETE, EDIT }
enum EventsDatasource {NEW = 200, STATUS}

var events:= {
	EventsDashboard.NEW : "ui.dashboard.new",
	EventsDashboard.DELETE : "ui.dashboard.delete",
	EventsDashboard.NEW_WIDGET : "ui.dashboard.widget-new",
	EventsDashboard.EDIT_WIDGET : "ui.dashboard.widget-edit",
	EventsDashboard.DUPLICATE_WIDGET : "ui.dashboard.widget-duplicate",
	EventsConfig.NEW : "ui.config.new",
	EventsConfig.DELETE : "ui.config.delete",
	EventsConfig.EDIT : "ui.config.edit",
	EventsDatasource.NEW : "ui.datasource.new",
	EventsDatasource.STATUS : "ui.datasource.status",
}

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


func analytics_event_data(event : int, context := {}, counters := {}) -> Dictionary:
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
	var body = analytics_event_data(event, properties)
	
	if event_queue and event_queue.size() > max_queue_size:
		post_events()
		yield(self, "analytics_event_posted")
		if event_queue.size() > 0:
			print("Force clear the queue: analytics request failed but the queue is full...")
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
		
	emit_signal("analytics_event_posted")
