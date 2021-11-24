# frozen_string_literal: true

module Bulkrax::HasLocalProcessing
  include ControlledIndexerBehavior

  SOURCES_OF_AUTHORITIES = {
    # local db, faster
    ::Qa::Authorities::Local => 'local',
    # remote, slower
    ::Qa::Authorities::Loc => 'loc',
    ::Qa::Authorities::Getty => 'getty'
  }.freeze

  # This method is called during build_metadata
  # add any special processing here, for example to reset a metadata property
  # to add a custom property from outside of the import data
  def add_local
    parsed_metadata.delete('rights_statement')
    if override_rights_statement || parsed_metadata['rightsStatement'].blank?
      parsed_metadata['rightsStatement'] = [parser.parser_fields['rights_statement']]
    end

    add_controlled_fields
  end

  def add_controlled_fields
    metadata_schema = ::ScoobySnacks::METADATA_SCHEMA

    metadata_schema.controlled_field_names.each do |field_name|
      parsed_metadata.delete(field_name) # remove non-standardized values
      next if raw_metadata[field_name.downcase].blank?

      # TODO: ensure existing values don't get lost
      raw_metadata[field_name.downcase].split(/\s*[|]\s*/).uniq.each_with_index do |value, i|
        auth_id = if value.match?(::URI::DEFAULT_PARSER.make_regexp)
                    value # assume raw, user-provided URI is a valid authority
                  else # find or create an authority
                    found_id = nil
                    field = metadata_schema.get_field(field_name)
                    SOURCES_OF_AUTHORITIES.each do |auth_source, auth_name| # attempt to lookup id
                      subauth_name = get_subauthority_for(field: field, authority_name: auth_name)
                      next unless subauth_name.present?

                      subauthority = auth_source.subauthority_for(subauth_name)
                      found_id = subauthority.search(value)&.first&.dig('id')
                    end
                    if found_id.blank? # create local auth if unable to find one
                      local_subauth_name = get_subauthority_for(field: field, authority_name: 'local')
                      found_id = mint_local_auth_url(local_subauth_name, value) if local_subauth_name.present?
                    end
                    found_id
                  end
        parsed_metadata["#{field_name}_attributes"] ||= {}
        parsed_metadata["#{field_name}_attributes"][i] = { 'id' => auth_id } if auth_id.present?
      end
    end
  end
end
