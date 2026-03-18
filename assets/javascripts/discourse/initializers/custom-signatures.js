import { withPluginApi } from "discourse/lib/plugin-api";
import PostSignature from "../components/post-signature";

export default {
  name: "discourse-plugin-custom-signature",

  initialize(container) {
    const siteSettings = container.lookup("service:site-settings");
    if (!siteSettings.custom_signatures_enabled) return;

    withPluginApi((api) => {
      // Register user_signature_cooked as a tracked post property so Discourse
      // includes it in the post stream data and reacts to changes.
      api.addTrackedPostProperties("user_signature_cooked");

      // Render PostSignature after the post body using the modern outlet API.
      api.renderAfterWrapperOutlet("post-content-cooked-html", PostSignature);

      // Tell Discourse to include user_signature (raw) when saving the profile page.
      api.addSaveableCustomFields("profile");
    });
  },
};
