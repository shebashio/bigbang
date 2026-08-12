#!/usr/bin/env ruby

require "json"
require "yaml"

ROOT = File.expand_path("..", __dir__)
METADATA_PATH = File.join(ROOT, "chart", "package-metadata.yaml")
SCHEMA_PATH = File.join(ROOT, "chart", "values.schema.json")
VALUES_PATH = File.join(ROOT, "chart", "values.yaml")
MIGRATION_PATH = File.join(ROOT, "scripts", "migrate-values-3-to-4.sh")
GENERATED_DEFINITION = "packageAliasPartials"
REQUIRED_METADATA_FIELDS = %w[displayName category legacyPath templateDirectory].freeze

def fail_with(message)
  warn "Error: #{message}"
  exit 1
end

def deep_copy(value)
  Marshal.load(Marshal.dump(value))
end

def local_definition_name(ref)
  match = ref&.match(%r{\A#/\$defs/([^/]+)\z})
  match && match[1]
end

class PartialSchemaBuilder
  attr_reader :partial_definitions

  def initialize(schema)
    @schema = schema
    @partial_definitions = {}
    @definitions_in_progress = {}
  end

  def build(legacy_schema, legacy_defaults)
    properties = collect_properties(legacy_schema)
    legacy_defaults.each_key { |name| properties[name] = true unless properties.key?(name) }
    partial = partialize(deep_copy(legacy_schema), true)
    partial.delete("required")
    partial["type"] = "object"
    partial["properties"] = properties.transform_values do |property_schema|
      partialize(deep_copy(property_schema), true)
    end
    partial["additionalProperties"] = false
    partial["description"] = "Partial override merged over the built-in package's legacy defaults."
    partial
  end

  private

  def resolve_ref(ref)
    name = local_definition_name(ref)
    fail_with("unsupported schema reference #{ref}") unless name

    definition = @schema.fetch("$defs").fetch(name, nil)
    fail_with("schema reference #{ref} does not exist") unless definition
    definition
  end

  # Collect all properties that apply to an object, including properties supplied
  # by allOf references and conditional branches. Concrete property schemas replace
  # permissive `true` placeholders inherited from basePackage.
  def collect_properties(node, seen_refs = {})
    return {} unless node.is_a?(Hash)

    properties = {}
    if node["$ref"]
      ref = node["$ref"]
      unless seen_refs[ref]
        properties.merge!(collect_properties(resolve_ref(ref), seen_refs.merge(ref => true)))
      end
    end

    %w[allOf anyOf oneOf].each do |keyword|
      Array(node[keyword]).each do |subschema|
        merge_properties!(properties, collect_properties(subschema, seen_refs))
      end
    end
    %w[then else].each do |keyword|
      merge_properties!(properties, collect_properties(node[keyword], seen_refs)) if node[keyword]
    end
    merge_properties!(properties, node.fetch("properties", {}))
    properties
  end

  def merge_properties!(target, additions)
    additions.each do |name, candidate|
      existing = target[name]
      target[name] = if existing.nil? || existing == true
                       deep_copy(candidate)
                     elsif candidate == true
                       existing
                     else
                       deep_copy(candidate)
                     end
    end
  end

  def ensure_partial_definition(name)
    return if @partial_definitions.key?(name)
    fail_with("recursive schema definition #{name} is not supported") if @definitions_in_progress[name]

    @definitions_in_progress[name] = true
    original = @schema.fetch("$defs").fetch(name)
    @partial_definitions[name] = partialize(deep_copy(original), true)
    @definitions_in_progress.delete(name)
  end

  # Objects supplied through packages.<name> are recursively merged over legacy
  # defaults, so their required/dependentRequired/minProperties constraints must
  # not apply to the fragment by itself. Array elements are not partialized because
  # arrays replace the legacy value rather than merging element-by-element.
  def partialize(node, partial_object)
    case node
    when Array
      node.map { |entry| partialize(entry, partial_object) }
    when Hash
      result = {}
      node.each do |key, value|
        next if partial_object && %w[required dependentRequired minProperties].include?(key)

        if key == "$ref" && partial_object && (name = local_definition_name(value))
          ensure_partial_definition(name)
          result[key] = "#/$defs/#{GENERATED_DEFINITION}/#{name}"
        elsif key == "items" || key == "contains"
          result[key] = partialize(value, false)
        elsif key == "if" || key == "not"
          result[key] = partialize(value, false)
        elsif %w[properties patternProperties additionalProperties].include?(key)
          result[key] = if value.is_a?(Hash)
                          value.transform_values { |entry| partialize(entry, true) }
                        else
                          value
                        end
        else
          result[key] = partialize(value, partial_object)
        end
      end
      result
    else
      node
    end
  end
end

def schema_at_legacy_path(schema, legacy_path)
  legacy_path.split(".").reduce(schema) do |node, segment|
    properties = node.is_a?(Hash) && node["properties"]
    fail_with("legacy schema path #{legacy_path} does not exist") unless properties&.key?(segment)
    properties.fetch(segment)
  end
end

def value_at_legacy_path(values, legacy_path)
  value = legacy_path.split(".").reduce(values) do |node, segment|
    fail_with("legacy values path #{legacy_path} does not exist") unless node.is_a?(Hash) && node.key?(segment)
    node.fetch(segment)
  end
  fail_with("legacy values path #{legacy_path} must be a mapping") unless value.is_a?(Hash)
  value
end

def validate_metadata(metadata)
  fail_with("package metadata apiVersion must be bigbang.dev/v1alpha1") unless metadata["apiVersion"] == "bigbang.dev/v1alpha1"
  packages = metadata["packages"]
  fail_with("package metadata packages must be a non-empty mapping") unless packages.is_a?(Hash) && !packages.empty?

  legacy_paths = {}
  template_directories = {}
  packages.each do |name, package|
    fail_with("package name #{name.inspect} must be a non-empty string") unless name.is_a?(String) && !name.empty?
    fail_with("metadata for #{name} must be a mapping") unless package.is_a?(Hash)
    missing = REQUIRED_METADATA_FIELDS.reject { |field| package[field].is_a?(String) && !package[field].empty? }
    fail_with("metadata for #{name} is missing #{missing.join(', ')}") unless missing.empty?
    fail_with("metadata category for #{name} must be core or addon") unless %w[core addon].include?(package["category"])

    legacy_path = package["legacyPath"]
    expected_prefix = package["category"] == "addon" ? "addons." : ""
    fail_with("legacyPath #{legacy_path} does not match category #{package['category']} for #{name}") unless legacy_path == "#{expected_prefix}#{name}"
    fail_with("legacyPath #{legacy_path} is already assigned to #{legacy_paths[legacy_path]}") if legacy_paths[legacy_path]
    legacy_paths[legacy_path] = name

    directory = package["templateDirectory"]
    fail_with("templateDirectory #{directory} is already assigned to #{template_directories[directory]}") if template_directories[directory]
    fail_with("template directory chart/templates/#{directory} does not exist") unless Dir.exist?(File.join(ROOT, "chart", "templates", directory))
    template_directories[directory] = name
  end
  packages
end

def generated_migration_block(packages)
  root_packages = packages.select { |_name, package| package.fetch("category") == "core" }.keys
  addon_packages = packages.select { |_name, package| package.fetch("category") == "addon" }.keys
  lines = [
    "# BEGIN GENERATED PACKAGE METADATA",
    "# Generated by scripts/generate-package-schemas.rb from chart/package-metadata.yaml.",
    "ROOT_PACKAGES=(",
    *root_packages.map { |name| "  #{name}" },
    ")",
    "",
    "ADDON_PACKAGES=(",
    *addon_packages.map { |name| "  #{name}" },
    ")",
    "# END GENERATED PACKAGE METADATA"
  ]
  lines.join("\n")
end

def generate
  metadata = YAML.safe_load(File.read(METADATA_PATH), permitted_classes: [], permitted_symbols: [], aliases: false)
  packages = validate_metadata(metadata)
  schema = JSON.parse(File.read(SCHEMA_PATH))
  values = YAML.safe_load(File.read(VALUES_PATH), permitted_classes: [], permitted_symbols: [], aliases: true)
  builder = PartialSchemaBuilder.new(schema)

  aliases = {}
  package_properties = {}
  packages.each do |name, package|
    legacy_schema = schema_at_legacy_path(schema, package.fetch("legacyPath"))
    legacy_defaults = value_at_legacy_path(values, package.fetch("legacyPath"))
    aliases[name] = builder.build(legacy_schema, legacy_defaults)
    package_properties[name] = { "$ref" => "#/$defs/#{GENERATED_DEFINITION}/aliases/#{name}" }
  end

  schema.fetch("properties").fetch("packages")["properties"] = package_properties
  schema.fetch("$defs").delete("packageAlias")
  schema.fetch("$defs")[GENERATED_DEFINITION] = builder.partial_definitions.merge("aliases" => aliases)
  migration = File.read(MIGRATION_PATH)
  generated_block = generated_migration_block(packages)
  marker_pattern = /# BEGIN GENERATED PACKAGE METADATA.*?# END GENERATED PACKAGE METADATA/m
  fail_with("#{MIGRATION_PATH} is missing generated metadata markers") unless migration.match?(marker_pattern)

  {
    SCHEMA_PATH => JSON.pretty_generate(schema) + "\n",
    MIGRATION_PATH => migration.sub(marker_pattern, generated_block)
  }
end

mode = ARGV.fetch(0, "--write")
fail_with("usage: #{File.basename($PROGRAM_NAME)} [--write|--check]") unless %w[--write --check].include?(mode) && ARGV.length <= 1

generated_files = generate
if mode == "--check"
  stale = generated_files.each_with_object([]) do |(path, contents), paths|
    paths << path unless File.read(path) == contents
  end
  fail_with("generated files are stale: #{stale.join(', ')}; run scripts/generate-package-schemas.rb --write") unless stale.empty?
  puts "Generated package metadata files are up to date."
else
  generated_files.each { |path, contents| File.write(path, contents) }
  puts "Updated generated package metadata files."
end
