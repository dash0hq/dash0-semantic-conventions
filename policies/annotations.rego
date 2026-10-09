package before_resolution

import rego.v1

# Annotations that each kind of registry element may declare.
# Every allowlist maps a namespace to its allowed keys, and each key to its allowed values.
# Extend the relevant map when introducing a new annotation.

allowed_attribute_annotations := {"dash0": {"transform_access": {"read", "write"}}}

# `code_generation` is defined by Weaver itself and is the only annotation groups may declare.
allowed_group_annotations := {"code_generation": {"metric_value_type": {"double", "int"}}}

# Enum members carry no annotations today.
allowed_member_annotations := {}

# Every element that can carry annotations, paired with the allowlist that governs it.
annotation_targets contains target if {
	some group in input.groups
	target := {
		"kind": "Group",
		"name": group.id,
		"group": group.id,
		"attr": "",
		"allowed": allowed_group_annotations,
		"declared": object.get(group, "annotations", null),
		"annotations": annotations_of(group),
	}
}

annotation_targets contains target if {
	some group in input.groups
	some attr in attributes_of(group)
	target := {
		"kind": "Attribute",
		"name": attr_name(attr),
		"group": group.id,
		"attr": attr_name(attr),
		"allowed": allowed_attribute_annotations,
		"declared": object.get(attr, "annotations", null),
		"annotations": annotations_of(attr),
	}
}

annotation_targets contains target if {
	some group in input.groups
	some attr in attributes_of(group)
	some member in members_of(attr)
	target := {
		"kind": "Enum member",
		"name": sprintf("%s/%s", [attr_name(attr), member_name(member)]),
		"group": group.id,
		"attr": attr_name(attr),
		"allowed": allowed_member_annotations,
		"declared": object.get(member, "annotations", null),
		"annotations": annotations_of(member),
	}
}

# Annotations must use a namespace allowed for the kind of element declaring them.
# A non-map `annotations` block needs no rule here: Weaver's own schema validation rejects it.
deny contains violation if {
	some target in annotation_targets
	some namespace, _ in target.annotations
	not target.allowed[namespace]
	violation := annotation_violation(
		"annotation_namespace_not_allowed",
		target,
		sprintf("%s: annotation namespace '%s' is not allowed; allowed namespaces: %s.", [label(target), namespace, key_list(target.allowed)]),
	)
}

# Allowed annotation namespaces must be maps.
deny contains violation if {
	some target in annotation_targets
	some namespace, entries in target.annotations
	target.allowed[namespace]
	not is_object(entries)
	violation := annotation_violation(
		"annotation_namespace_not_a_map",
		target,
		sprintf("%s: annotation namespace '%s' must be a map.", [label(target), namespace]),
	)
}

# Annotation keys must be allowed within their namespace.
deny contains violation if {
	some target in annotation_targets
	some namespace, entries in target.annotations
	is_object(entries)
	allowed_keys := target.allowed[namespace]
	some key, _ in entries
	not allowed_keys[key]
	violation := annotation_violation(
		"annotation_key_not_allowed",
		target,
		sprintf("%s: annotation '%s.%s' is not allowed; allowed keys: %s.", [label(target), namespace, key, key_list(allowed_keys)]),
	)
}

# Annotation values must be one of the allowed values for their key.
deny contains violation if {
	some target in annotation_targets
	some namespace, entries in target.annotations
	is_object(entries)
	some key, value in entries
	allowed_values := target.allowed[namespace][key]
	not value in allowed_values
	violation := annotation_violation(
		"annotation_value_not_allowed",
		target,
		sprintf("%s: annotation '%s.%s' has value '%v'; allowed values: %s.", [label(target), namespace, key, value, value_list(allowed_values)]),
	)
}

# An `annotations` block that declares nothing is dead weight.
# Weaver normalises an absent `annotations` key on attributes and enum members to null,
# so only an explicitly empty map (`annotations: {}`) is distinguishable from no block at all.
deny contains violation if {
	some target in annotation_targets
	is_object(target.declared)
	count(target.declared) == 0
	violation := annotation_warning(
		"empty_annotations_block",
		target,
		sprintf("%s: empty `annotations` block; remove it.", [label(target)]),
	)
}

# Built with `concat` rather than `sprintf`: Weaver's Rego engine swallows a space that
# immediately follows a format verb, so no `%s` above is ever followed by one.
label(target) := concat(" ", [target.kind, sprintf("'%s'", [target.name])])

annotation_violation(id, target, message) := annotation_advice(id, target, message, "violation")

annotation_warning(id, target, message) := annotation_advice(id, target, message, "improvement")

annotation_advice(id, target, message, level) := {
	"type": "advice",
	"advice_type": id,
	"advice_level": level,
	"value": target.name,
	"message": message,
	"advice_context": {"group": target.group, "attr": target.attr},
}

# Weaver passes absent optional fields as null, which `some .. in` rejects.
annotations_of(x) := a if {
	a := object.get(x, "annotations", null)
	is_object(a)
} else := {}

attributes_of(group) := a if {
	a := object.get(group, "attributes", null)
	is_array(a)
} else := []

members_of(attr) := m if {
	t := object.get(attr, "type", null)
	is_object(t)
	m := object.get(t, "members", null)
	is_array(m)
} else := []

attr_name(attr) := n if {
	n := object.get(attr, "id", null)
	is_string(n)
} else := n if {
	n := object.get(attr, "ref", null)
	is_string(n)
} else := "<unnamed>"

member_name(member) := n if {
	n := object.get(member, "id", null)
	is_string(n)
} else := "<unnamed>"

key_list(obj) := list_or_none([key | some key, _ in obj])

value_list(values) := list_or_none([sprintf("%v", [value]) | some value in values])

list_or_none(items) := "none" if {
	count(items) == 0
}

list_or_none(items) := concat(", ", sort(items)) if {
	count(items) > 0
}
