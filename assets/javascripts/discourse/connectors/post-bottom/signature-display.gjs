import Component from "@glimmer/component";
import { htmlSafe } from "@ember/template";

/**
 * Connector: post-bottom / signature-display
 *
 * Renders the author's cooked signature beneath every post in the stream.
 * `user_signature_cooked` is injected server-side via the :post serializer
 * (see plugin.rb) — it is sanitised HTML produced by PrettyText.cook.
 *
 * Using htmlSafe() is intentional: the content has already been sanitised
 * server-side and must be rendered as HTML, not escaped text.
 */
export default class SignatureDisplay extends Component {
  get signature() {
    // post-bottom passes the post POJO as @outletArgs.model
    return this.args.outletArgs.model?.user_signature_cooked ?? null;
  }

  <template>
    {{#if this.signature}}
      <aside class="post-signature" aria-label="Signature">
        <hr class="signature-separator" />
        <div class="signature-content">{{htmlSafe this.signature}}</div>
      </aside>
    {{/if}}
  </template>
}
