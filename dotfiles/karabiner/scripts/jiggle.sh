#!/bin/bash

PID_FILE="/tmp/jiggle-$UID.pid"

# Toggle off
if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")

    if kill -0 "$PID" 2>/dev/null; then
        kill "$PID"
        rm -f "$PID_FILE"
        exit 0
    fi

    rm -f "$PID_FILE"
fi

# Toggle on
nohup /usr/bin/osascript -l JavaScript \
    > /tmp/jiggle.log 2>&1 <<'EOF' &
ObjC.import("CoreGraphics");
ObjC.import("AppKit");
ObjC.import("Foundation");

const app = $.NSApplication.sharedApplication;
app.setActivationPolicy(1);

// Configuration
const tolerance = 3;
const distance = 5;
const interval = 1000;
const pollInterval = 0.2;

// Screen bounds
const bounds = $.CGDisplayBounds($.CGMainDisplayID());

const right = bounds.origin.x + bounds.size.width - 1;
const bottom = bounds.origin.y + bounds.size.height - 1;
const top = bounds.origin.y;

let direction = 1;
let active = true;
let lastMove = Date.now();

// Menu bar
const statusBar = $.NSStatusBar.systemStatusBar;
const statusItem = statusBar.statusItemWithLength(36);
const button = statusItem.button;

// Icon rendering
function createIcon(active) {
    const width = 32;
    const height = 22;

    const image = $.NSImage.alloc.initWithSize(
        $.NSMakeSize(width, height)
    );

    image.lockFocus;

    const background = active
        ? $.NSColor.colorWithRedGreenBlueAlpha(
            0.95, 0.55, 0, 1
        )
        : $.NSColor.colorWithRedGreenBlueAlpha(
            0.45, 0.45, 0.45, 1
        );

    background.setFill;

    $.NSBezierPath
        .bezierPathWithRoundedRectXRadiusYRadius(
            $.NSMakeRect(0, 0, width, height),
            4,
            4
        ).fill;

    const attributes = $.NSMutableDictionary.alloc.init;

    attributes.setObjectForKey(
        $.NSFont.boldSystemFontOfSize(20),
        $.NSFontAttributeName
    );

    attributes.setObjectForKey(
        $.NSColor.whiteColor,
        $.NSForegroundColorAttributeName
    );

    const text = $(active ? "↕" : "Ⅱ");
    const size = text.sizeWithAttributes(attributes);

    text.drawAtPointWithAttributes(
        $.NSMakePoint(
            (width - size.width) / 2,
            (height - size.height) / 2
        ),
        attributes
    );

    image.unlockFocus;
    image.setTemplate(false);

    return image;
}

const activeIcon = createIcon(true);
const pausedIcon = createIcon(false);

button.image = activeIcon;
button.toolTip = "Mouse jiggler — click to stop";

// Generate mouse events
function move(x, y) {
    const event = $.CGEventCreateMouseEvent(
        null,
        5,
        $.CGPointMake(x, y),
        0
    );

    $.CGEventPost(0, event);
}

// Periodic mouse movement
function tick() {
    const p = $.CGEventGetLocation(
        $.CGEventCreate(null)
    );

    const atEdge = Math.abs(p.x - right) <= tolerance;

    if (active !== atEdge) {
        active = atEdge;
        button.image = active ? activeIcon : pausedIcon;
    }

    const now = Date.now();

    if (atEdge && now - lastMove >= interval) {
        const y = Math.max(
            top,
            Math.min(bottom, p.y + direction * distance)
        );

        move(right, y);

        direction *= -1;
        lastMove = now;
    }
}

// Timer callback
ObjC.registerSubclass({
    name: "JigglerController",
    superclass: "NSObject",
    methods: {
        "tick:": {
            types: ["void", ["id"]],
            implementation: function(sender) {
                tick();
            }
        }
    }
});

const controller = $.JigglerController.alloc.init;

// Clicking directly terminates the application.
// No custom click handler required.
button.setTarget(app);
button.setAction("terminate:");

// Initially move to the right edge
move(right, top + bounds.size.height / 2);

// Schedule periodic mouse movement
const timer = $.NSTimer
    .scheduledTimerWithTimeIntervalTargetSelectorUserInfoRepeats(
        pollInterval,
        controller,
        "tick:",
        null,
        true
    );

// Native application event loop
app.run;

EOF

PID=$!
echo "$PID" > "$PID_FILE"

# Clean up PID file on exit
(
    while kill -0 "$PID" 2>/dev/null; do
        sleep 0.5
    done

    if [ "$(cat "$PID_FILE" 2>/dev/null)" = "$PID" ]; then
        rm -f "$PID_FILE"
    fi
) >/dev/null 2>&1 </dev/null &
