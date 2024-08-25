json.id site.id
json.is_tspot site.is_tspot?
json.url site.url

json.name site.name
json.description site.description

json.tw_kind site.tw_kind
json.tw_version site.tw_version

json.is_private site.is_private
json.hub_listed site.hub_listed?
json.allow_public_clone site.allow_public_clone unless site.is_tspot?

json.allow_in_iframe site.allow_in_iframe
json.prefer_put_saver site.prefer_put_saver unless site.is_tspot?
json.prefer_upload_saver site.prefer_upload_saver unless site.is_tspot?

json.view_count site.view_count
json.access_count site.access_count
json.save_count site.save_count
json.clone_count site.clone_count unless site.is_tspot?

json.accessed_at site.accessed_at
json.created_at site.created_at
json.updated_at site.blob_created_at

json.size site.raw_byte_size
json.blob_size site.blob_byte_size
