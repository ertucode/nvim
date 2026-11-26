ObjC.import("CoreGraphics");

let direction = 1;

while (true) {
  const p = $.CGEventGetLocation($.CGEventCreate(null));

  $.CGWarpMouseCursorPosition($.CGPointMake(p.x + direction * 10, p.y));

  direction *= -1;
  delay(1);
}
