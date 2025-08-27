module Iceberg
  class Catalog
    def list_namespaces(parent = nil)
      @catalog.list_namespaces(parent)
    end

    def create_namespace(namespace, properties: {})
      @catalog.create_namespace(namespace, properties)
    end

    def namespace_exists?(namespace)
      @catalog.namespace_exists?(namespace)
    end

    def namespace_properties(namespace)
      @catalog.namespace_properties(namespace)
    end

    def update_namespace(namespace, properties:)
      @catalog.update_namespace(namespace, properties)
    end

    def drop_namespace(namespace, if_exists: nil)
      @catalog.drop_namespace(namespace)
    rescue Error => e
      if !if_exists || (e.message != "Tried to drop a namespace that does not exist" && !e.message.include?("No such namespace"))
        raise e
      end
      nil
    end

    def list_tables(namespace)
      @catalog.list_tables(namespace)
    end

    def create_table(table_name, schema: nil, location: nil)
      if !schema.nil? && block_given?
        raise ArgumentError, "Must pass schema or block"
      end

      if block_given?
        table_definition = TableDefinition.new
        yield table_definition
        schema = Schema.new(table_definition.fields)
      elsif schema.is_a?(Hash)
        fields =
          schema.map.with_index do |(k, v), i|
            {
              id: i + 1,
              name: k.is_a?(Symbol) ? k.to_s : k,
              type: v,
              required: false
            }
          end
        schema = Schema.new(fields)
      elsif schema.nil?
        schema = Schema.new([])
      end

      Table.new(@catalog.create_table(table_name, schema, location), @catalog)
    end

    def load_table(table_name)
      Table.new(@catalog.load_table(table_name), @catalog)
    end

    def drop_table(table_name, if_exists: nil)
      @catalog.drop_table(table_name)
    rescue Error => e
      if !if_exists || (e.message != "Tried to drop a table that does not exist" && !e.message.include?("No such table"))
        raise e
      end
      nil
    end

    def table_exists?(table_name)
      @catalog.table_exists?(table_name)
    rescue NamespaceNotFoundError
      false
    end

    def rename_table(table_name, new_name)
      @catalog.rename_table(table_name, new_name)
    end

    def register_table(table_name, metadata_location)
      @catalog.register_table(table_name, metadata_location)
    end

    def query(sql)
      # requires datafusion feature
      raise Todo unless @catalog.respond_to?(:query)

      @catalog.query(sql)
    end

    # hide internal state
    def inspect
      to_s
    end
  end
end
