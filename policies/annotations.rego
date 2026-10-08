package before_resolution

import rego.v1

# Annotations that attributes may declare.
# Maps each namespace to its allowed keys, and each key to its allowed values.
# Extend this map when introducing a new annotation.
allowed_annotations := {"dash0": {"transform_access": {"read", "write"}}}

# Groups must not declare annotations.
deny contains violation if {
	some group in input.groups
	object.get(group, "annotations", null) != null
	violation := annotation_violation(
		"group_annotations_not_allowed",
		group.id,
		"",
		sprintf("Group '%s' declares annotations; annotations are only allowed on attributes.", [group.id]),
	)
}

# Attribute annotations must use an allowed namespace.
deny contains violation if {
	some group in input.groups
	some attr in attributes_of(group)
	some namespace, _ in annotations_of(attr)
	not allowed_annotations[namespace]
	violation := annotation_violation(
		"annotation_namespace_not_allowed",
		group.id,
		attr_name(attr),
		sprintf("Attribute '%s' uses annotation namespace '%s'; allowed namespaces: %v.", [attr_name(attr), namespace, object.keys(allowed_annotations)]),
	)
}

# Allowed annotation namespaces must be maps.
deny contains violation if {
	some group in input.groups
	some attr in attributes_of(group)
	some namespace, entries in annotations_of(attr)
	allowed_annotations[namespace]
	not is_object(entries)
	violation := annotation_violation(
		"annotation_namespace_not_a_map",
		group.id,
		attr_name(attr),
		sprintf("Attribute '%s' annotation namespace '%s' must be a map.", [attr_name(attr), namespace]),
	)
}

# Annotation keys must be allowed within their namespace.
deny contains violation if {
	some group in input.groups
	some attr in attributes_of(group)
	some namespace, entries in annotations_of(attr)
	is_object(entries)
	allowed_keys := allowed_annotations[namespace]
	some key, _ in entries
	not allowed_keys[key]
	violation := annotation_violation(
		"annotation_key_not_allowed",
		group.id,
		attr_name(attr),
		sprintf("Attribute '%s' uses annotation '%s.%s'; allowed keys: %v.", [attr_name(attr), namespace, key, object.keys(allowed_keys)]),
	)
}

# Annotation values must be one of the allowed values for their key.
deny contains violation if {
	some group in input.groups
	some attr in attributes_of(group)
	some namespace, entries in annotations_of(attr)
	is_object(entries)
	some key, value in entries
	allowed_values := allowed_annotations[namespace][key]
	not value in allowed_values
	violation := annotation_violation(
		"annotation_value_not_allowed",
		group.id,
		attr_name(attr),
		sprintf("Attribute '%s' annotation '%s.%s' has value '%v'; allowed values: %v.", [attr_name(attr), namespace, key, value, allowed_values]),
	)
}

annotation_violation(id, group_id, attr, message) := {
	"type": "advice",
	"advice_type": id,
	"advice_level": "violation",
	"value": attr,
	"message": message,
	"advice_context": {"group": group_id, "attr": attr},
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

attr_name(attr) := object.get(attr, "id", object.get(attr, "ref", ""))
