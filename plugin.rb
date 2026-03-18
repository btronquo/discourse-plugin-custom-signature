# frozen_string_literal: true

# name: discourse-plugin-custom-signature
# about: Allows users to add a custom Markdown/HTML signature to all their posts
# version: 1.1.0
# authors: Boris Tronquoy
# url: https://github.com/btronquo/discourse-plugin-custom-signature

enabled_site_setting :custom_signatures_enabled

# Expose to the current user JS object.
# Fields added here keep their snake_case name on the client side.
DiscoursePluginRegistry.serialized_current_user_fields << "can_have_signature"

after_initialize do
  # ── Custom field registration ──────────────────────────────────────────────

  register_editable_user_custom_field :user_signature
  register_user_custom_field_type(:user_signature, :text)
  register_user_custom_field_type(:user_signature_cooked, :text)

  # Make the cooked signature accessible in the post stream
  allow_public_user_custom_field :user_signature_cooked

  # ── Helper method on User ──────────────────────────────────────────────────

  add_to_class(:user, :can_have_signature) do
    return false unless SiteSetting.custom_signatures_enabled

    allowed = SiteSetting.custom_signatures_allowed_groups.to_s
    return true if allowed.blank? # no group restriction = everyone

    allowed_ids = allowed.split("|").map(&:to_i)
    return true if allowed_ids.include?(0) # group 0 = everyone (virtual, no group_users rows)

    in_any_groups?(allowed_ids)
  end

  # ── Serializers ────────────────────────────────────────────────────────────

  # Picked up by DiscoursePluginRegistry.serialized_current_user_fields above
  add_to_serializer(:current_user, :can_have_signature) { object.can_have_signature }

  # Expose raw signature on the user serializer (to pre-fill the preferences form)
  add_to_serializer(:user, :user_signature) { object.custom_fields["user_signature"] }

  # Expose cooked signature on the post serializer (post stream display)
  add_to_serializer(:post, :user_signature_cooked) do
    return nil unless SiteSetting.custom_signatures_enabled
    return nil unless object.user&.can_have_signature

    object.user.custom_fields["user_signature_cooked"]
  end

  # ── Cook signature on save ─────────────────────────────────────────────────

  on(:user_updated) do |user|
    unless user.can_have_signature
      user.custom_fields["user_signature"]        = nil
      user.custom_fields["user_signature_cooked"] = nil
      user.save_custom_fields
      next
    end

    raw = user.custom_fields["user_signature"].to_s.strip

    if raw.present?
      max_len = SiteSetting.custom_signatures_max_length
      raw     = raw[0, max_len] if raw.length > max_len
      cooked  = PrettyText.cook(raw, sanitize: true)

      if user.custom_fields["user_signature_cooked"] != cooked
        user.custom_fields["user_signature"]        = raw
        user.custom_fields["user_signature_cooked"] = cooked
        user.save_custom_fields
      end
    elsif user.custom_fields["user_signature_cooked"].present?
      user.custom_fields["user_signature_cooked"] = nil
      user.save_custom_fields
    end
  end
end

register_asset "stylesheets/common/custom-signatures.scss"
