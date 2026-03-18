import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { on } from "@ember/modifier";
import { i18n } from "discourse-i18n";

export default class SignatureField extends Component {
  @service currentUser;
  @service siteSettings;

  // Seed from whatever is already saved on the model
  @tracked _value = this.args.model?.custom_fields?.user_signature ?? "";

  // can_have_signature is exposed via DiscoursePluginRegistry.serialized_current_user_fields
  // and therefore stays snake_case on the client (no camelization).
  get canHaveSignature() {
    if (!this.siteSettings.custom_signatures_enabled) return false;
    return this.currentUser?.can_have_signature !== false;
  }

  get maxLength() {
    return this.siteSettings.custom_signatures_max_length ?? 500;
  }

  get charsRemaining() {
    return this.maxLength - this._value.length;
  }

  get isNearLimit() {
    return this.charsRemaining <= 50;
  }

  get isOverLimit() {
    return this.charsRemaining < 0;
  }

  @action
  handleInput(event) {
    const val = event.target.value;
    this._value = val;
    // Write into the model so the standard preferences save picks it up
    const model = this.args.model;
    if (model) {
      if (!model.custom_fields) model.custom_fields = {};
      model.custom_fields.user_signature = val;
    }
  }

  <template>
    {{#if this.siteSettings.custom_signatures_enabled}}
      {{#if this.canHaveSignature}}
        <div class="control-group pref-signature">
          <label class="control-label">
            {{i18n "user.signature.title"}}
          </label>

          <div class="controls">
            <textarea
              class="signature-input input-xxlarge"
              rows="4"
              maxlength={{this.maxLength}}
              placeholder={{i18n "user.signature.placeholder"}}
              {{on "input" this.handleInput}}
            >{{this._value}}</textarea>

            <div
              class="signature-char-count
                {{if this.isNearLimit 'near-limit'}}
                {{if this.isOverLimit 'over-limit'}}"
            >
              {{i18n
                "user.signature.characters_remaining"
                count=this.charsRemaining
              }}
            </div>

            <p class="signature-description">
              {{i18n "user.signature.description"}}
            </p>
          </div>
        </div>
      {{/if}}
    {{/if}}
  </template>
}
