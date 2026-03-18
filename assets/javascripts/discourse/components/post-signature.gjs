import Component from "@glimmer/component";
import { htmlSafe } from "@ember/template";

export default class PostSignature extends Component {
  // Called by Discourse before rendering — returning false skips the component entirely.
  static shouldRender(args) {
    return !!args.post?.user_signature_cooked;
  }

  <template>
    <hr class="signature-separator" />
    <div class="post-signature">
      <div class="signature-content">{{htmlSafe @post.user_signature_cooked}}</div>
    </div>
  </template>
}
