class_name GameplayPauseBoundary
extends RefCounted


static func apply(root_node: Node, explicit_always_nodes: Array[Node] = []) -> bool:
	if root_node == null:
		return false
	for child: Node in root_node.get_children():
		if child is CanvasLayer or explicit_always_nodes.has(child):
			child.process_mode = Node.PROCESS_MODE_ALWAYS
		else:
			child.process_mode = Node.PROCESS_MODE_PAUSABLE
	return true
