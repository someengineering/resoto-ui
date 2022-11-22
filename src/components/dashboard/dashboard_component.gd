extends ComponentContainer

func apply_navigation_arguments():
	if "dashboard_name" in navigation_arguments:
		component = component as DashboardManager
		component.load_dashboard(navigation_arguments["dashboard_name"])
		if navigation_arguments["dashboard_name"] == "ManageDashboards":
			UINavigation.change_title("Manage Dashboards")
		else:
			UINavigation.change_title("Dashboard: %s" % navigation_arguments["dashboard_name"].replace("_", " "))


func _on_DashBoardManager_dashboard_opened(dashboard_name):
	update_navigation_arguments({"dashboard_name": dashboard_name})
	if dashboard_name == "ManageDashboards":
		UINavigation.change_title("Manage Dashboards")
	else:
		UINavigation.change_title("Dashboard: %s" % dashboard_name.replace("_", " "))
