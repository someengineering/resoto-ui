extends PanelContainer

const IconGraphRoot = preload("res://assets/resoto/Resoto-Logo_med.svg")

var metadata:Dictionary

onready var icon_bg = $"%IconBG"
onready var icon_shadow = $"%IconShadow"
onready var icon_tex = $"%IconTex"
onready var kind_label_bg = $"%KindLabelBG"
onready var kind_label_text = $"%KindLabelText"
onready var details_container = $"%DetailsContainer"

onready var n_icon_cleaned := $"%NodeIconCleaned"
onready var n_icon_phantom := $"%NodeIconPhantom"
onready var n_icon_protected := $"%NodeIconProtected"


func display(_metadata:Dictionary):
	modulate.a = 0.001
	rect_size = Vector2.ONE
	for c in details_container.get_children():
		c.queue_free()
	
	metadata = _metadata
	set_title(Utils.name_id(metadata.reported.name, metadata.reported.id))
	set_group_color(metadata.reported.kind)
	set_kind(metadata.reported.kind)
	create_breadcrumbs()
	set_details()
	yield(VisualServer, "frame_post_draw")
	modulate.a = 1.0


func create_breadcrumbs():
	if not metadata.has("ancestors"):
		return
	
	if metadata.ancestors.has("cloud"):
		create_detail_pair("Cloud:", Utils.name_id(metadata.ancestors.cloud.reported.name, metadata.ancestors.cloud.reported.id))
	
	if metadata.ancestors.has("account"):
		create_detail_pair("Account:", Utils.name_id(metadata.ancestors.account.reported.name, metadata.ancestors.account.reported.id))
	
	if metadata.ancestors.has("region"):
		create_detail_pair("Region:", Utils.name_id(metadata.ancestors.region.reported.name, metadata.ancestors.region.reported.id))
	
	if metadata.ancestors.has("zone"):
		create_detail_pair("Zone:", Utils.name_id(metadata.ancestors.zone.reported.name, metadata.ancestors.zone.reported.id))
	
	var spacer1 := Control.new()
	spacer1.rect_min_size.y = 10
	spacer1.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var spacer2 := Control.new()
	spacer2.rect_min_size.y = 10
	spacer2.mouse_filter = Control.MOUSE_FILTER_IGNORE
	details_container.add_child(spacer1)
	details_container.add_child(spacer2)


func set_details():
	if metadata.metadata.has("cleaned"):
		n_icon_cleaned.visible = metadata.metadata.cleaned
	if metadata.metadata.has("protected"):
		n_icon_protected.visible = metadata.metadata.protected
	if metadata.metadata.has("phantom"):
		n_icon_phantom.visible = metadata.metadata.phantom
	
	if metadata.has("reported"):
		if metadata.reported.has("age"):
			create_detail_pair("Age:", Utils.readable_duration(metadata.reported.age))
		if metadata.reported.has("ctime"):
			create_detail_pair("CTime:", metadata.reported.ctime.replace("T", "\n").trim_suffix("Z"))
		if metadata.reported.has("mtime"):
			create_detail_pair("MTime:", metadata.reported.ctime.replace("T", "\n").trim_suffix("Z"))
		if metadata.reported.has("tags") and not metadata.reported.tags.empty():
			create_detail_pair("Tags:", Utils.readable_dict(metadata.reported.tags))


func create_detail_pair(_text_l:String, _text_r:String):
	var n_l : Label = Label.new()
	n_l.size_flags_horizontal = 0
	n_l.size_flags_vertical = SIZE_EXPAND_FILL
	n_l.theme_type_variation = "LabelBold"
	n_l.text = _text_l
	n_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	details_container.add_child(n_l)
	var n_r : Label = Label.new()
	n_r.text = _text_r
	n_r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	n_r.size_flags_horizontal = SIZE_EXPAND_FILL
	details_container.add_child(n_r)


func set_title(_title:String):
	$"%NodeNameID".text = Utils.truncate_string(_title, $"%NodeNameID".get_font("font"), 800.0)
	

func set_kind(_kind:String):
	set_kind_icon(_kind)
	kind_label_text.text = _kind


func set_kind_icon(_kind:String):
	if _kind == "graph_root":
		icon_tex.texture = IconGraphRoot
		icon_shadow.texture = IconGraphRoot
		return
	
	if not _g.resoto_model.has(metadata.reported.kind):
		return
	
	var model_for_kind : Dictionary = _g.resoto_model[metadata.reported.kind]
	if model_for_kind.has("metadata") and model_for_kind.metadata.has("icon"):
		icon_tex.texture = Style.icon_files[model_for_kind.metadata.icon]
		icon_shadow.texture = Style.icon_files[model_for_kind.metadata.icon]


func set_group_color(_kind:String):
	if _kind == "graph_root":
		icon_bg.self_modulate = Style.group_colors[_kind][0]
		icon_tex.modulate = Color.white
		kind_label_bg.self_modulate = Style.group_colors[_kind][0]
		kind_label_text.modulate = Style.group_colors[_kind][1]
		return
	
	if not _g.resoto_model.has(metadata.reported.kind):
		return
	
	var model_for_kind : Dictionary = _g.resoto_model[metadata.reported.kind]
	if model_for_kind.has("metadata") and model_for_kind.metadata.has("group"):
		icon_bg.self_modulate = Style.group_colors[model_for_kind.metadata.group][0]
		icon_tex.modulate = Style.group_colors[model_for_kind.metadata.group][1]
		kind_label_bg.self_modulate = Style.group_colors[model_for_kind.metadata.group][0]
		kind_label_text.modulate = Style.group_colors[model_for_kind.metadata.group][1]
