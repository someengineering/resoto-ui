extends Node

signal analytics_event_posted

enum EventsDashboard{ NEW, DELETE, NEW_WIDGET, EDIT_WIDGET, DUPLICATE_WIDGET}
enum EventsConfig { NEW = 100, DELETE, EDIT, DUPLICATE }
enum EventsDatasource {NEW = 200, NEW_FROM_TEMPLATE, FAILED, DELETE}
enum EventsUI {STARTED = 300, EXITED, ERROR, RUNNING}
enum EventsExplore {BACK = 400, COPY_QUERY, COPY_NODE, CHANGE_MODE, REMOVE_FROM_CLEANUP, ADD_TO_CLEANUP, PROTECT, EXPLORE_SUCCESSORS, EXPLORE_PREDECESSORS, EXPLORE_NODE_LIST, EXPLORE_NODE}
enum EventsSearch {SEARCH = 500}
enum EventWizard {START = 600, FINISH, COLLECT_DONE, ERROR}
enum EventsJobEditor {SAVE = 700, DELETE, DUPLICATE, RUN, NEW_FROM_TEMPLATE}
enum EventsAggregationView {RUN = 800, USE_EXAMPLE, COPY_TO_CSV, COPY_TO_JSON, DOCS, SHOW}

var events:= {
	EventsDashboard.NEW : "ui.dashboard.new",
	EventsDashboard.DELETE : "ui.dashboard.delete",
	EventsDashboard.NEW_WIDGET : "ui.dashboard.widget-new",
	EventsDashboard.EDIT_WIDGET : "ui.dashboard.widget-edit",
	EventsDashboard.DUPLICATE_WIDGET : "ui.dashboard.widget-duplicate",
	EventsConfig.NEW : "ui.config.new",
	EventsConfig.DELETE : "ui.config.delete",
	EventsConfig.EDIT : "ui.config.edit",
	EventsConfig.DUPLICATE : "ui.config.duplicate",
	EventsDatasource.NEW : "ui.datasource.new",
	EventsDatasource.NEW_FROM_TEMPLATE : "ui.datasource.new-from-template",
	EventsDatasource.FAILED : "ui.datasource.failed",
	EventsDatasource.DELETE : "ui.datasource.delete",
	EventsUI.STARTED : "ui.started",
	EventsUI.EXITED: "ui.exited",
	EventsUI.ERROR: "ui.error",
	EventsUI.RUNNING: "ui.running",
	EventsExplore.BACK: "ui.explore.back",
	EventsExplore.COPY_QUERY: "ui.explore.copy-query",
	EventsExplore.COPY_NODE: "ui.explore.copy-node",
	EventsExplore.CHANGE_MODE: "ui.explore.change-mode",
	EventsExplore.REMOVE_FROM_CLEANUP: "ui.explore.remove_from_cleanup",
	EventsExplore.ADD_TO_CLEANUP: "ui.explore.add-to-cleanup",
	EventsExplore.PROTECT: "ui.explore.protect",
	EventsExplore.EXPLORE_SUCCESSORS: "ui.explore.successors",
	EventsExplore.EXPLORE_PREDECESSORS: "ui.explore.predecessors",
	EventsExplore.EXPLORE_NODE_LIST: "ui.explore.node-list",
	EventsSearch.SEARCH: "ui.search",
	EventWizard.START: "ui.wizard.start",
	EventWizard.FINISH: "ui.wizard.finish",
	EventWizard.ERROR: "ui.wizard.error",
	EventWizard.COLLECT_DONE: "ui.wizard.collect-done",
	EventsJobEditor.DELETE: "ui.job-editor.delete",
	EventsJobEditor.DUPLICATE: "ui.job-editor.duplicate",
	EventsJobEditor.NEW_FROM_TEMPLATE: "ui.job-editor.new_from_template",
	EventsJobEditor.RUN: "ui.job-editor.run",
	EventsJobEditor.SAVE: "ui.job-editor.save",
	EventsAggregationView.RUN: "ui.aggregation-view.run",
	EventsAggregationView.USE_EXAMPLE: "ui.aggregation-view.used_example",
	EventsAggregationView.COPY_TO_CSV: "ui.aggregation-view.copy_to_csv",
	EventsAggregationView.COPY_TO_JSON: "ui.aggregation-view.copy_to_json",
	EventsAggregationView.DOCS: "ui.aggregation-view.docs",
	EventsAggregationView.SHOW: "ui.aggregation-view.show"
}

var api_key : String = ""
var last_api_timestamp = 0
var api_key_refresh_time = 3600

var event_queue : Array = []
var max_queue_size : int = 100

var session_id : String = ""
var user_id : String = ""

var one_hour_callback_ref = JavaScript.create_callback(self, "one_hour_callback")
var one_hour_timer : Timer
var total_time : int = 0

func _ready():
	var post_timer := Timer.new()
	post_timer.wait_time = 60
	add_child(post_timer)
	post_timer.start()
	post_timer.connect("timeout", self, "post_events")
	
	if OS.has_feature("HTML5"):
		session_id = JavaScript.eval("getSessionId()")
		user_id = JavaScript.eval("getUserId()")
		var window := JavaScript.get_interface("window")
		window.addEventListener("oneHourEvent", one_hour_callback_ref)
	else:
		user_id = str(OS.get_unique_id())
		one_hour_timer = Timer.new()
		one_hour_timer.wait_time = 3600
		one_hour_timer.connect("timeout", self, "on_one_hour_timer_timeout")
		add_child(one_hour_timer)
		one_hour_timer.start()


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


func event(event, properties := {}, counters := {}):
	var body = analytics_event_data(event, properties, counters)
	
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
	if error:
		return
	if response.response_code == 204:
		event_queue.clear()
	else:
		print("Posting to analytics endpoint failed, not clearing the queue")
		
	emit_signal("analytics_event_posted")


func _notification(what):
	# If user quits, send all the events
	if what == NOTIFICATION_WM_QUIT_REQUEST:
		# TODO: find a way to measure this times in native builds
		if OS.has_feature("HTML5"):
			var properties := {
				"focused time" : JavaScript.eval("focusTime"),
				"not focused time" : JavaScript.eval("unfocusTime"),
				"total time" : JavaScript.eval("totalTime")
			}
			event(EventsUI.EXITED, properties)
			
		post_events()

func one_hour_callback(_args):
	var properties := {
		"focused time" : JavaScript.eval("focusTime"),
		"not focused time" : JavaScript.eval("unfocusTime"),
		"total time" : JavaScript.eval("totalTime")
	}
	event(EventsUI.RUNNING, properties)

func on_one_hour_timer_timeout():
	total_time += 3600
	var properties := {
		# We cannot measure the time the app is visible but not focused in native
		"total time" : total_time
	}
	event(EventsUI.RUNNING, properties)
