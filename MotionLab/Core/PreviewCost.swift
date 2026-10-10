import Foundation

/// Effects too expensive to play live as a thumbnail: grids and strips show their still frame instead
/// (the detail page still plays them live). Measured on a real iPad Pro 12.9" (3rd gen, A12X, 120 Hz) with
/// `-ML_perfLog YES -ML_bench YES` (`PreviewBench`): four live copies at 180 pt for 1.5 s; listed when the
/// screen kept fewer than 130 of 180 frames (under ~87 fps). Re-run the bench after changing a demo.
enum PreviewCost {
    static let stillOnlyIDs: Set<String> = [
        "buttons.specular-glass",
        "cards.plan-switch",
        "charts.activity-rings",
        "charts.bar-grow",
        "charts.bullet-kpi",
        "charts.funnel-flow",
        "charts.kpi-count-up",
        "charts.legend-focus",
        "charts.line-compare",
        "charts.liquid-bars",
        "charts.scrub-tooltip",
        "charts.stacked-bars",
        "charts.threshold-split",
        "inputs.radio-travel",
        "inputs.thermostat-dial",
        "morph.mini-player",
        "morph.notification-expand",
        "morph.portal-zoom",
        "morph.search-expand",
        "navigation.dock-magnify",
        "scroll.date-bubble",
        "scroll.pinned-zoom",
        "shader.crumple",
        "showcase.best-line",
        "showcase.dimmer-lamp",
        "showcase.elevation-profile",
        "showcase.ev-charge",
        "showcase.focus-timer",
        "showcase.fresh-snow",
        "showcase.gear-checklist",
        "showcase.now-playing",
        "showcase.parcel-tracker",
        "showcase.podcast-chapters",
        "showcase.run-summary",
        "showcase.sleep-timeline",
        "showcase.speed-line",
        "showcase.steps-ring",
        "showcase.tide-pulse",
        "showcase.tip-selector",
        "showcase.water-intake",
        "showcase.weather-widget",
        "text.echo-trail",
        "text.gradient-flow",
        "text.letter-drop",
        "text.long-shadow",
        "text.magnet-letters",
    ]

    static func playsLive(_ id: String) -> Bool {
        !stillOnlyIDs.contains(id)
    }
}
