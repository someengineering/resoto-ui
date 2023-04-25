extends Control

const browser_warning_string := "For the best experience using the Resoto User Interface, we recommend using Google Chrome instead of %s (detected).\n\nOther browsers may cause compatibility issues and reduce functionality."

var browser_warning_time := 5


func _ready():
	_g.connect("connect_to_core", self, "check_for_browser")


func check_for_browser():
	if not ["", "Chrome", "Chromium"].has(_g.browser):
		show_browser_popup()


func show_browser_popup():
	$"%BrowserWarningBG".show()
	$"%BrowserWarningLabel".text = browser_warning_string % _g.browser
	$"%BrowserWarningConfirmButton".disabled = true
	$"%BrowserWarningConfirmButton".text = "Dismiss (5)"
	$"%BrowserWarning".popup_centered()
	$"%BrowserWarningTimer".start()


func _on_BrowserWarningTimer_timeout():
	browser_warning_time -= 1
	if browser_warning_time <= 0:
		$"%BrowserWarningConfirmButton".disabled = false
		$"%BrowserWarningConfirmButton".text = "Dismiss"
	else:
		$"%BrowserWarningConfirmButton".text = "Dismiss (%s)" % str(browser_warning_time)
		$"%BrowserWarningTimer".start()


func _on_BrowserWarningConfirmButton_pressed():
	$"%BrowserWarningBG".hide()
	$"%BrowserWarning".hide()
