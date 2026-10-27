export const sharedClipboardPath = "/Users/Shared/shared-clipboard.txt";
export const sharedClipboardImagePath =
  "/Users/Shared/shared-clipboard-image.png";
export const sharedClipboardTypePath = "/Users/Shared/shared-clipboard.type";
export const sharedClipboardImageScriptPath =
  "/Users/Shared/shared-clipboard-image.js";

export const sharedClipboardImageScript = `ObjC.import("AppKit");
ObjC.import("Foundation");

function run(argv) {
  const action = argv[0];
  const path = argv[1];
  const pasteboard = $.NSPasteboard.generalPasteboard;

  if (action === "export") {
    const image = $.NSImage.alloc.initWithPasteboard(pasteboard);
    if (!image) throw new Error("The clipboard does not contain an image");

    const bitmap = $.NSBitmapImageRep.imageRepWithData(image.TIFFRepresentation);
    const png = bitmap.representationUsingTypeProperties(
      $.NSBitmapImageFileTypePNG,
      $({}),
    );
    if (!png.writeToFileAtomically(path, false)) {
      throw new Error("Could not write the shared clipboard image");
    }
    return;
  }

  if (action === "import") {
    const png = $.NSData.dataWithContentsOfFile(path);
    if (!png) throw new Error("Could not read the shared clipboard image");

    pasteboard.clearContents;
    if (!pasteboard.setDataForType(png, $.NSPasteboardTypePNG)) {
      throw new Error("Could not restore the shared clipboard image");
    }
    return;
  }

  throw new Error("Expected an export or import action");
}
`;

const copyTextToSharedClipboardCommand =
  `LANG=en_US.UTF-8 /usr/bin/pbpaste > ${sharedClipboardPath}` +
  ` && /usr/bin/printf text > ${sharedClipboardTypePath}`;
const copyImageToSharedClipboardCommand =
  `/usr/bin/osascript -l JavaScript ${sharedClipboardImageScriptPath}` +
  ` export ${sharedClipboardImagePath}` +
  ` && /usr/bin/printf image > ${sharedClipboardTypePath}`;
const restoreSharedClipboardCommand =
  `if [ "$(/bin/cat ${sharedClipboardTypePath} 2>/dev/null)" = image ]; then ` +
  `/usr/bin/osascript -l JavaScript ${sharedClipboardImageScriptPath} import ${sharedClipboardImagePath}; ` +
  `else LANG=en_US.UTF-8 /usr/bin/pbcopy < ${sharedClipboardPath}; fi`;

export const sharedClipboardManipulators = [
  {
    from: {
      key_code: "c",
      modifiers: { mandatory: ["command", "shift", "control"] },
    },
    to: [
      {
        key_code: "c",
        modifiers: ["left_command"],
        hold_down_milliseconds: 200,
      },
      { shell_command: copyTextToSharedClipboardCommand },
    ],
    type: "basic",
  },
  {
    from: {
      key_code: "b",
      modifiers: { mandatory: ["command", "shift", "control"] },
    },
    to: [{ shell_command: copyImageToSharedClipboardCommand }],
    type: "basic",
  },
  {
    from: {
      key_code: "v",
      modifiers: { mandatory: ["command", "shift", "control"] },
    },
    to: [
      {
        shell_command: restoreSharedClipboardCommand,
        hold_down_milliseconds: 200,
      },
      { key_code: "v", modifiers: ["left_command"] },
    ],
    type: "basic",
  },
] as const;
