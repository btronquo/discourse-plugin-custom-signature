import { apiInitializer } from "discourse/lib/api";

/**
 * API Initializer: custom-signatures
 *
 * Uses `api.decorateCooked` to append the user's cooked signature after the
 * body of every post in the stream.
 *
 * `decorateCooked` is called each time a post is rendered (including after
 * edits), so we remove any pre-existing signature node first to avoid
 * duplicates.
 *
 * The cooked HTML is produced server-side by `PrettyText.cook(..., sanitize: true)`
 * so it is already sanitised — XSS-safe to inject as innerHTML.
 */
export default apiInitializer("1.0", (api) => {
  api.decorateCooked(
    (cooked, helper) => {
      // Only run inside the post stream (not in the composer preview, etc.)
      if (!helper) return;

      const post = helper.getModel?.();
      if (!post) return;

      const signature = post.user_signature_cooked;
      if (!signature) return;

      // Remove a previously injected signature (e.g. after post edit)
      cooked.querySelector(".post-signature")?.remove();

      // Build the signature block
      const wrapper = document.createElement("aside");
      wrapper.className = "post-signature";
      wrapper.setAttribute("aria-label", "Signature");

      const hr = document.createElement("hr");
      hr.className = "signature-separator";

      const content = document.createElement("div");
      content.className = "signature-content";
      content.innerHTML = signature; // cooked & sanitised HTML from server

      wrapper.appendChild(hr);
      wrapper.appendChild(content);

      cooked.appendChild(wrapper);
    },
    { id: "custom-post-signature", onlyStream: true }
  );
});
