# frozen_string_literal: true

# name: discourse-plugin-custom-signature
# about: Allows users to add a custom Markdown/HTML signature to all their posts
# version: 1.0.2
# authors: Boris Tronquoy
# url: https://github.com/btronquo/discourse-plugin-custom-signature

enabled_site_setting :custom_signatures_enabled

after_initialize do
  # ── Custom field registration ──────────────────────────────────────────────

  # The raw field is editable via the user preferences API
  register_editable_user_custom_field :user_signature
  register_user_custom_field_type(:user_signature, :text)

  # The cooked (rendered HTML) version is stored server-side for safe display
  register_user_custom_field_type(:user_signature_cooked, :text)

  # ── Helper method on User ──────────────────────────────────────────────────

  add_to_class(:user, :can_have_signature?) do
    return false unless SiteSetting.custom_signatures_enabled

    allowed = SiteSetting.custom_signatures_allowed_groups.to_s
    # Empty list = nobody (plugin enabled but no group selected yet)
    return false if allowed.blank?

    allowed_ids = allowed.split("|").map(&:to_i)

    # Group ID 0 is Discourse's virtual "everyone" group — it has no rows in
    # group_users, so we must handle it explicitly.
    return true if allowed_ids.include?(0)

    GroupUser.where(user_id: id, group_id: allowed_ids).exists?
  end

  # ── Serializers ────────────────────────────────────────────────────────────

  # Expose permission flag to the client (used to show/hide the textarea)
  add_to_serializer(:current_user, :can_have_signature) do
    object.can_have_signature?
  end

  # Expose raw + cooked values on the user serializer (profile page)
  add_to_serializer(:user, :user_signature) do
    object.custom_fields["user_signature"]
  end

  add_to_serializer(:user, :user_signature_cooked) do
    object.custom_fields["user_signature_cooked"]
  end

  # Expose the cooked signature on the post serializer (post stream)
  add_to_serializer(:post, :user_signature_cooked) do
    return nil unless SiteSetting.custom_signatures_enabled
    # Enforce permission at display time too (handles setting changes retroactively)
    return nil unless object.user&.can_have_signature?

    object.user.custom_fields["user_signature_cooked"]
  end

  # ── Cook signature on save ─────────────────────────────────────────────────

  on(:user_updated) do |user|
    raw = user.custom_fields["user_signature"].to_s.strip

    if raw.present? && user.can_have_signature?
      max_len = SiteSetting.custom_signatures_max_length

      # Silently truncate to the configured max length
      raw = raw[0, max_len] if raw.length > max_len

      cooked = PrettyText.cook(raw, sanitize: true)

      # Persist raw (possibly truncated) + cooked version only when changed
      changed = user.custom_fields["user_signature"] != raw ||
                user.custom_fields["user_signature_cooked"] != cooked

      if changed
        user.custom_fields["user_signature"]        = raw
        user.custom_fields["user_signature_cooked"] = cooked
        user.save_custom_fields
      end
    elsif user.custom_fields["user_signature_cooked"].present? || !user.can_have_signature?
      # Clear signature for users who are not allowed or who deleted it
      user.custom_fields["user_signature"]        = nil
      user.custom_fields["user_signature_cooked"] = nil
      user.save_custom_fields
    end
  end
end
