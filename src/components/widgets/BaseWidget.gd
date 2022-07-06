class_name BaseWidget
extends Control

enum DATA_TYPE {INSTANT, RANGE}

export (DATA_TYPE) var data_type = DATA_TYPE.INSTANT
# 0 max_data_sources means infinite
export (int) var max_data_sources : int = 1

