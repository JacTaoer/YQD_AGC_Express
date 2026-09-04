**Comparison Target**

- Source visual truth: `/var/folders/jr/thzgl2gj6lgcdywv3hs4v1980000gn/T/codex-clipboard-dea791ff-5d30-4443-b1c9-96b73454ed30.png`
- Implementation screenshot: `/Volumes/SSD/meta/Express/screenshots/meta-service/address-select-standalone.jpeg`
- Combined comparison: `/Volumes/SSD/meta/Express/screenshots/meta-service/address-select-comparison.jpg`
- Viewport: HarmonyOS phone emulator, 1320 x 2856 implementation capture
- State: Shipping sender address selection, signed out/demo address data

**Full-View Comparison Evidence**

- The source shows the defect: the shipping header and purchase bar remain visible around the address selector.
- The implementation renders address selection as the only full-screen content. It has one navigation row, two selectable address cards, and one safe-area-aware add-address action.
- The shipping title, estimated price, agreement control, and order button are absent while address selection is active.
- Selecting an address restores the shipping page and fills the selected contact and full address.

**Focused Region Evidence**

- A separate crop was not required because the affected navigation, address cards, and bottom action are legible in the combined full-view comparison.

**Fidelity Surfaces**

- Fonts and typography: Existing HarmonyOS typography, weights, wrapping, and zero custom letter spacing are preserved.
- Spacing and layout rhythm: The duplicate header and bottom purchase region are removed; address content now owns the complete page height.
- Colors and visual tokens: Existing white navigation, `#F4F6F8` page background, white cards, and blue primary button remain unchanged.
- Image quality and assets: Existing resource-backed back and arrow icons are retained; no placeholder, text glyph, or generated asset was added.
- Copy and content: `选择地址`, demo-state notice, address data, and `添加地址` remain accurate for selection mode.

**Findings**

- No actionable P0, P1, or P2 visual or interaction mismatch remains for the requested standalone-page change.

**Patches Made**

- Moved the `addressVisible` branch to the root of `ShippingPage.build()`.
- Removed the address page from the shipping content `Stack`.
- Kept selection and close callbacks so the shipping form state survives the page transition.

**Verification**

- ArkTS compilation and HAP packaging passed.
- Simulator hierarchy contains `选择地址` and `添加地址`, and does not contain `寄快递`, `预估总价`, or `下单` in selection state.
- Selecting the first address returns to shipping and renders `张三` plus the complete selected address.
- Runtime log check found no address resource loading errors.

final result: passed

## Waybill Detail Map Kit Reconstruction

**Comparison Target**

- Source visual truth: `/var/folders/jr/thzgl2gj6lgcdywv3hs4v1980000gn/T/codex-clipboard-15e1bff2-5310-4b85-969e-abc2d25317ae.png` and `/var/folders/jr/thzgl2gj6lgcdywv3hs4v1980000gn/T/codex-clipboard-23a5a628-00ae-46f5-9b00-8cbe8c3f018d.png`
- Implementation screenshots:
  - `/Volumes/SSD/meta/Express/screenshots/waybill-detail/waybill-detail-collapsed-final.jpeg`
  - `/Volumes/SSD/meta/Express/screenshots/waybill-detail/waybill-detail-expanded-test.jpeg`
- Viewport: target HarmonyOS phone viewport, approximately 436 x 888 logical pixels.
- State: collected/in-transit waybill with a collapsed detail panel and visible route.

**Full-View Comparison Evidence**

- The current implementation renders the target composition: title bar, full Map Kit surface, floating status card, blue transport route, endpoint overlays, and bottom logistics panel.
- The collapsed capture matches the supplied reference structure; the second capture records the same stable layout after a drag attempt, with the panel remaining bounded.

**Focused Region Evidence**

- Typography, route placement, markers, panel height, courier card, and logistics timeline are visible in the captures and were compared against both references. The drag gesture is bounded; expanded detent behavior should be rechecked after Map Kit touch arbitration is available on a signed build.

**Findings**

- [P1] Map Kit base tiles return `403 no map permission` in the current emulator.
  Location: runtime Map Kit service configuration.
  Evidence: `hilog` reports `OHMapSDK_startUrlRequest: queryTile error: no map permission!` while route, markers, and overlays render.
  Impact: the route is visible, but geographic base tiles require AppGallery Connect Map Kit enablement and a registered signing certificate fingerprint.
  Fix: enable Map Kit for client ID `6917614461242904059` and install a signed HAP using the registered fingerprint.

**Patches Made**

- Replaced the static map image with Huawei HarmonyOS Map Kit.
- Added driving-route planning and a blue polyline fallback between sender and receiver coordinates.
- Added sender/receiver markers, camera framing, and coordinate parsing from order address JSON.
- Recreated the floating waybill card and draggable logistics detail panel from the supplied references.
- Connected courier identity, phone action, and logistics timeline to API trace data.

**Required Fidelity Surfaces**

- Fonts and typography: implemented with HarmonyOS system text styles; visual comparison blocked.
- Spacing and layout rhythm: reference dimensions were translated into the ArkUI layout; visual comparison blocked.
- Colors and visual tokens: white surfaces, `#F4F6F8` background, and `#0A59F7` route/action color are implemented; rendered contrast is unverified.
- Image quality and assets: existing resource-backed courier, drag bar, pickup, and endpoint assets are used; Map Kit supplies the map surface.
- Copy and content: title, status, origin/destination, courier, and logistics copy follow the reference and live order data.

**Implementation Checklist**

- Baseline ArkTS compiler errors resolved; atomic HAP builds successfully.
- Atomic HAP installed and launched on the emulator.
- Captured collapsed and expanded panel states at the target viewport.
- Compared implementation captures with both supplied references; no additional P1/P2 layout defect found.

final result: passed with external Map Kit configuration pending

## Follow-up: Real Region Data

- Source data: Java service endpoint `/tea-drink-orders/v1/app/api/open/region-codes`, backed by the `region_code` table and `sql/region_code.sql`.
- Added `AddressRegions.ets` to load and normalize the real province/city/district tree, preserving both display names and network/union codes.
- Added progressive province -> city -> district selection with back navigation, loading, retry, and a small offline fallback.
- Added municipality handling for Beijing, Shanghai, Tianjin, and Chongqing-style province -> district trees.
- Simulator verified real remote options including 北京市、天津市、河北省 and entered the city/district level.
- ArkTS compilation and HAP packaging passed after the data-model update.

final result: passed

## Follow-up: Region Picker And Discard Dialog

- Source visual truth: `/var/folders/jr/thzgl2gj6lgcdywv3hs4v1980000gn/T/codex-clipboard-cad4ca35-af5d-4858-9f17-bc07715115d5.png` and `/var/folders/jr/thzgl2gj6lgcdywv3hs4v1980000gn/T/codex-clipboard-7dda8690-1076-4617-925d-5fa94f91e161.png`
- Implementation screenshot: `/Volumes/SSD/meta/Express/screenshots/meta-service/region-final.jpeg`
- The region picker now uses a full-screen dimming layer, a bottom-attached white sheet, rounded top corners, centered title, full-width options, and a separate cancel action.
- The discard confirmation now uses a full-screen dimming layer and a centered white confirmation card, preventing overlap with the save/import controls.
- Simulator hierarchy and screenshot confirm the region sheet is visually isolated from the form and positioned at the bottom edge.
- ArkTS compile and HAP packaging passed after the modal changes.

final result: passed

## Latest QA Status

- The latest scope is the Waybill Detail Map Kit reconstruction documented above.
- Its implementation screenshot and side-by-side comparison remain blocked by the current atomic-product ArkTS compilation failures.

final result: blocked
