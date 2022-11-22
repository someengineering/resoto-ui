extends ComponentContainer

func apply_navigation_arguments():
	if "dashboard_name" in navigation_arguments:
		UINavigation.change_title("Dashboard: %s" % navigation_arguments["dashboard_name"])
		component = component as DashboardManager
		component.load_dashboard(navigation_arguments["dashboard_name"])


func _on_DashBoardManager_dashboard_opened(dashboard_name):
	update_navigation_arguments({"dashboard_name": dashboard_name})
	UINavigation.change_title("Dashboard: %s" %dashboard_name)
