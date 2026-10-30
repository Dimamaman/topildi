import assert from "node:assert/strict";
import test from "node:test";

import { errorMessage, errorRateDay, maxStackLines, parseErrorReport, trimStack } from "../errors";

test("a report needs a message", () => {
  assert.equal(parseErrorReport({}), null);
  assert.equal(parseErrorReport({ message: "   " }), null);
  assert.equal(parseErrorReport(null), null);
  assert.equal(parseErrorReport({ message: "Null check operator" })?.message, "Null check operator");
});

test("the caller's uid stands in when the app sends none", () => {
  assert.equal(parseErrorReport({ message: "x" }, "u_me")?.uid, "u_me");
  assert.equal(parseErrorReport({ message: "x", uid: "u_app" }, "u_me")?.uid, "u_app");
});

test("an unknown kind is treated as a manual report", () => {
  assert.equal(parseErrorReport({ message: "x", kind: "nonsense" })?.kind, "manual");
  assert.equal(parseErrorReport({ message: "x", kind: "flutter" })?.kind, "flutter");
});

test("the stack keeps its top and says how much was left out", () => {
  const stack = Array.from({ length: 30 }, (_, i) => `#${i}  Foo.bar (file.dart:${i})`).join("\n");
  const kept = trimStack(stack).split("\n");
  assert.equal(kept.length, maxStackLines + 1);
  assert.match(kept[0], /#0/);
  assert.equal(kept.at(-1), `… +${30 - maxStackLines}`);
});

test("the message carries the page, the error and the stack", () => {
  const text = errorMessage({
    kind: "flutter",
    message: "Null check operator used on a null value",
    stack: "#0  _ReportSheetState._send (report_sheet.dart:80)",
    route: "/listing/l3",
    action: "Shikoyat yuborish",
    uid: "u_me",
    appVersion: "1.0.0+2",
    platform: "iOS 18.2",
    device: "iPhone14,2",
    language: "uzLatn",
    release: true,
  });
  assert.match(text, /🐞 <b>Xatolik<\/b> · iOS 18\.2 · v1\.0\.0\+2/);
  assert.match(text, /<b>Sahifa:<\/b> <code>\/listing\/l3<\/code>/);
  assert.match(text, /<b>Amal:<\/b> Shikoyat yuborish/);
  assert.match(text, /<b>Xabar:<\/b> Null check operator used on a null value/);
  assert.match(text, /qurilma: iPhone14,2/);
  assert.match(text, /<pre>#0  _ReportSheetState\._send \(report_sheet\.dart:80\)<\/pre>/);
});

test("a debug build is marked, and anything the user typed is escaped", () => {
  const text = errorMessage({
    kind: "manual",
    message: '<script>alert("x")</script> & co',
    release: false,
    platform: "Android 15",
  });
  assert.match(text, /· debug/);
  assert.match(text, /&lt;script&gt;/);
  assert.doesNotMatch(text, /<script>/);
});

test("the day key is the date, for the daily cap", () => {
  assert.equal(errorRateDay(new Date("2026-10-30T23:59:00Z")), "2026-10-30");
});
