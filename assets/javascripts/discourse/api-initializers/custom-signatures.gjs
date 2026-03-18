// This file is intentionally minimal.
// Post signature rendering is handled by the Glimmer connector at:
//   connectors/post-bottom/signature-display.gjs
//
// This initializer is kept as an extension point for future JS-level
// customisation (e.g. keyboard shortcuts, composer helpers, etc.).
import { apiInitializer } from "discourse/lib/api";

export default apiInitializer("1.0", (_api) => {});
