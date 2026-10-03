class_name StoryChapter
extends Resource

@export var id: StringName
@export var title: String
@export var objective: String
@export var floor_texture: Texture2D
@export var wall_color: Color = Color("484450")
@export var void_color: Color = Color("30313c")
@export var trim_color: Color = Color("c9b58f")
@export var arrival_dialogue: Array[Dictionary] = []
@export var boss: EnemyData
@export var boss_dialogue: Array[Dictionary] = []
