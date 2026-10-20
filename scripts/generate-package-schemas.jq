def local_definition_name:
  if type == "string" and startswith("#/$defs/") and (split("/") | length) == 3
  then split("/")[2]
  else null
  end;

def merge_properties($left; $right):
  reduce ($right | to_entries[]) as $entry ($left;
    .[$entry.key] = if .[$entry.key] == null or .[$entry.key] == true
                    then $entry.value
                    elif $entry.value == true
                    then .[$entry.key]
                    else $entry.value
                    end
  );

def collect_properties($schema; $node; $seen):
  if ($node | type) != "object" then
    {}
  else
    ($node["$ref"]? // null) as $ref
    | ($ref | local_definition_name) as $definition_name
    | (if $definition_name != null and (($seen[$ref] // false) | not)
       then [collect_properties($schema; $schema["$defs"][$definition_name]; $seen + {($ref): true})]
       else []
       end) as $referenced_properties
    | ([$node.allOf[]?, $node.anyOf[]?, $node.oneOf[]?, $node.then?, $node.else?]
       | map(collect_properties($schema; .; $seen))) as $composed_properties
    | reduce (($referenced_properties + $composed_properties + [($node.properties // {})])[]) as $properties
        ({}; merge_properties(.; $properties))
  end;

# Package overrides are recursively merged over chart defaults. Remove
# requirements that may be satisfied by those defaults while retaining types,
# enums, patterns, known properties, and complete validation for array elements.
def partialize($partial_object):
  if type == "array" then
    map(partialize($partial_object))
  elif type != "object" then
    .
  else
    with_entries(
      select(($partial_object and (.key == "required" or .key == "dependentRequired" or .key == "minProperties")) | not)
      | if .key == "$ref" and $partial_object and ((.value | local_definition_name) != null) then
          .value = "#/$defs/packagePartials/\(.value | local_definition_name)"
        elif .key == "items" or .key == "contains" or .key == "if" or .key == "not" then
          .value |= partialize(false)
        elif (.key == "properties" or .key == "patternProperties" or .key == "additionalProperties")
             and (.value | type) == "object" then
          .value |= with_entries(.value |= partialize(true))
        else
          .value |= partialize($partial_object)
        end
    )
  end;

def package_override($schema; $values; $package):
  $schema["$defs"].builtinPackageSchemas.properties[$package.key] as $package_schema
  | $values.packages[$package.key] as $package_defaults
  | if $package_schema == null then
      error("missing built-in package schema for \($package.key)")
    elif $package_defaults == null then
      error("missing built-in package defaults for \($package.key)")
    else . end
  | collect_properties($schema; $package_schema; {}) as $schema_properties
  | (reduce ($package_defaults | keys[]) as $name ($schema_properties;
      if has($name) then . else .[$name] = true end
    )) as $properties
  | ($package_schema | partialize(true))
  | del(.required)
  | .type = "object"
  | .properties = ($properties | with_entries(.value |= partialize(true)))
  | .additionalProperties = false
  | .description = "Partial override merged over the built-in package defaults.";

def validate_metadata($metadata):
  if $metadata.apiVersion != "bigbang.dev/v1alpha1" then
    error("package metadata apiVersion must be bigbang.dev/v1alpha1")
  elif ($metadata.packages | type) != "object" or ($metadata.packages | length) == 0 then
    error("package metadata packages must be a non-empty mapping")
  elif any($metadata.packages | to_entries[]; . as $package
           | ($package.key | type) != "string" or ($package.key | length) == 0
           or ($package.value | type) != "object"
           or any(["displayName", "category", "legacyPath", "templateDirectory"][]; . as $field
                  | ($package.value[$field]? // "") as $value
                  | ($value | type) != "string" or ($value | length) == 0)) then
    error("package metadata contains a missing or invalid required field")
  elif any($metadata.packages | keys[]; test("^[a-z][A-Za-z0-9]*$") | not) then
    error("package metadata package keys must use camelCase identifiers")
  elif any($metadata.packages[].templateDirectory;
           test("^[a-z0-9]+(-[a-z0-9]+)*$") | not) then
    error("package metadata templateDirectory values must use kebab-case directory names")
  elif any($metadata.packages[]; .category != "core" and .category != "addon") then
    error("package metadata category must be core or addon")
  elif any($metadata.packages | to_entries[];
           .value.legacyPath != (if .value.category == "addon" then "addons.\(.key)" else .key end)) then
    error("package metadata legacyPath does not match its package name and category")
  elif (($metadata.packages | map(.legacyPath) | length) != ($metadata.packages | map(.legacyPath) | unique | length)) then
    error("package metadata legacyPath values must be unique")
  elif (($metadata.packages | map(.templateDirectory) | length) != ($metadata.packages | map(.templateDirectory) | unique | length)) then
    error("package metadata templateDirectory values must be unique")
  else
    $metadata
  end;

validate_metadata($metadata[0]) as $validated_metadata
| . as $schema
| $values[0] as $chart_values
| if ($schema["$defs"].builtinPackageSchemas.properties | keys) != ($validated_metadata.packages | keys) then
    error("built-in package schemas must match the package catalog")
  elif (($validated_metadata.packages | keys) - ($chart_values.packages | keys)) != [] then
    error("built-in package defaults are missing catalog entries")
  elif $schema["$defs"].customPackages == null then
    error("missing custom package schema")
  else . end
| $schema["$defs"].customPackages as $custom_packages
| (reduce ($validated_metadata.packages | to_entries[]) as $package
    ({}; .[$package.key] = package_override($schema; $chart_values; $package))) as $overrides
| (reduce ($validated_metadata.packages | keys_unsorted[]) as $name
    ({}; .[$name] = {"$ref": "#/$defs/packagePartials/overrides/\($name)"})) as $package_properties
| ($schema["$defs"] | del(.packagePartials, .builtinPackageSchemas, .customPackages, .canonicalPackages)
   | with_entries(.value |= partialize(true))) as $partial_definitions
| ($custom_packages + {"properties": $package_properties}) as $canonical_packages
| .properties.packages = {"$ref": "#/$defs/canonicalPackages"}
| .["$defs"].customPackages = $custom_packages
| .["$defs"].canonicalPackages = $canonical_packages
| .["$defs"].packagePartials = ($partial_definitions + {overrides: $overrides})
