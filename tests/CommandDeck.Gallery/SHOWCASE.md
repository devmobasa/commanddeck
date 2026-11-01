# Feature showcases

`showcase.qml` hosts the production launcher and Settings with fictional data.
`ShowcaseTimeline.js` holds the three stories; each supports chapter cards and
footage-only captions. `ShowcaseCard.qml` shares the typography and caption bar.
No daemon or desktop connection is used. Copy feedback and server receipts are
prepared in memory. Spotlight opacity is sampled explicitly for repeatable fades.

Run the six optional scenes with an output directory outside `docs/screenshots`:

```sh
dotnet scripts/capture-gallery.cs --output /tmp/commanddeck-showcase \
  showcase-shortcuts-chapters showcase-shortcuts-captions \
  showcase-settings-search-chapters showcase-settings-search-captions \
  showcase-new-look-chapters showcase-new-look-captions
```

The scenes are excluded from the default gallery run. Each emits a GIF, an MP4,
and a `<scene>-frames` directory with the timed PNGs and encoding manifest. Runs
replace only that scene's generated frames. Captures check the important visible
states and whether the controls, cards and captions fit. The encoder limits its
worker threads and computes the GIF palette separately to keep memory bounded.

The stories follow the current UI: Reduce motion is on Search; segmented choices
are on Editors and Customization. The Settings search types `transparency`, the
card's title, which points at the card's first control, Transparent background.
