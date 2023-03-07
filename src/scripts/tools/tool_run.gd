extends EditorScript
tool

func _run():
	var cron_regex := RegEx.new()
	cron_regex.compile("(^((\\*\\/)?([0-5]?[0-9])((\\,|\\-|\\/)([0-5]?[0-9]))*|\\*)\\s+((\\*\\/)?((2[0-3]|1[0-9]|[0-9]|00))((\\,|\\-|\\/)(2[0-3]|1[0-9]|[0-9]|00))*|\\*)\\s+((\\*\\/)?([1-9]|[12][0-9]|3[01])((\\,|\\-|\\/)([1-9]|[12][0-9]|3[01]))*|\\*)\\s+((\\*\\/)?([1-9]|1[0-2])((\\,|\\-|\\/)([1-9]|1[0-2]))*|\\*|(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)((\\,|\\-|\\/)(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec))*)\\s+((\\*\\/)?[0-6]((\\,|\\-|\\/)[0-6])*|\\*|00|(mon|tue|wed|thu|fri|sat|sun)((\\,|\\-|\\/)(mon|tue|wed|thu|fri|sat|sun))*)$)")
	
	var regex := "* * * * MON"
	print(cron_regex.search_all(regex.to_lower()))

