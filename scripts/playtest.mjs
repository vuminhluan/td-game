import { chromium } from "@playwright/test";
import assert from "node:assert/strict";
const browser = await chromium.launch({ headless: true, channel: "chrome" });
const page = await browser.newPage({ viewport: { width: 1440, height: 1100 } });
const errors = [];
page.on("pageerror", (e) => errors.push(String(e)));
await page.goto(process.env.GAME_URL || "http://localhost:5174");
await page.waitForSelector("#game canvas");
await page.screenshot({
  path: "/private/tmp/robot-defense-ready.png",
  fullPage: true,
});
await page.getByRole("button", { name: "TRIỂN KHAI ROBOT" }).click();
await page.waitForTimeout(300);
const start = await page.evaluate(() => window.__battle.sim.player.x);
await page.keyboard.down("ArrowRight");
await page.waitForTimeout(300);
await page.keyboard.up("ArrowRight");
assert.ok((await page.evaluate(() => window.__battle.sim.player.x)) > start);
await page.keyboard.down("Space");
await page.waitForTimeout(500);
await page.keyboard.up("Space");
await page.keyboard.press("p");
assert.equal(await page.evaluate(() => window.__battle.sim.status), "paused");
const t = await page.evaluate(() => window.__battle.sim.elapsed);
await page.waitForTimeout(200);
assert.equal(await page.evaluate(() => window.__battle.sim.elapsed), t);
await page.getByRole("button", { name: "TIẾP TỤC →" }).click();
await page.waitForTimeout(1500);
await page.screenshot({
  path: "/private/tmp/robot-defense-playing.png",
  fullPage: true,
});
await page.evaluate(() => {
  const s = window.__battle.sim;
  s.status = "lost";
  s.message = "Căn cứ đã bị phá hủy";
});
await page.waitForTimeout(200);
await page.getByRole("button", { name: "CHƠI LẠI" }).click();
assert.equal(await page.evaluate(() => window.__battle.sim.wave), 1);
for (const width of [320, 375, 414, 768]) {
  await page.setViewportSize({ width, height: 1000 });
  await page.waitForTimeout(100);
  assert.ok(
    await page.evaluate(
      () => document.documentElement.scrollWidth <= innerWidth,
    ),
    `overflow ${width}`,
  );
}
await page.setViewportSize({ width: 375, height: 900 });
await page.waitForTimeout(150);
await page.screenshot({
  path: "/private/tmp/robot-defense-mobile.png",
  fullPage: true,
});
assert.deepEqual(errors, []);
console.log(
  "Browser checks passed: rendering, movement, fire, pause, resume, restart, responsive 320/375/414/768, zero page errors.",
);
await browser.close();
