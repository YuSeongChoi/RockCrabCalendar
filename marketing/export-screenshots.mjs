import { chromium } from "playwright";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";
import { execFileSync } from "node:child_process";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const outputDir = path.join(__dirname, "exports");
const appStoreDir = path.join(__dirname, "exports-appstore-1284x2778");
const htmlUrl = pathToFileURL(path.join(__dirname, "index.html")).href;

const names = [
  "01-rockcrabcalendar-main-calendar.png",
  "02-rockcrabcalendar-monthly-list.png",
  "03-rockcrabcalendar-records.png",
  "04-rockcrabcalendar-record-write.png",
  "05-rockcrabcalendar-qwer-filter.png",
  "06-rockcrabcalendar-add-qwer.png",
  "07-rockcrabcalendar-add-private.png",
  "08-rockcrabcalendar-widget.png",
  "09-rockcrabcalendar-settings.png"
];

fs.mkdirSync(outputDir, { recursive: true });
fs.mkdirSync(appStoreDir, { recursive: true });

for (const dir of [outputDir, appStoreDir]) {
  for (const file of fs.readdirSync(dir)) {
    if (file.endsWith(".png")) {
      fs.unlinkSync(path.join(dir, file));
    }
  }
}

const browser = await chromium.launch({ headless: true });
const page = await browser.newPage({
  viewport: { width: 1400, height: 3000 },
  deviceScaleFactor: 2
});

await page.goto(htmlUrl, { waitUntil: "networkidle" });

const slides = page.locator(".slide-frame");
const count = await slides.count();

if (count !== names.length) {
  throw new Error(`Expected ${names.length} slides, found ${count}`);
}

for (let i = 0; i < count; i += 1) {
  const slide = slides.nth(i);
  const outputPath = path.join(outputDir, names[i]);
  const appStorePath = path.join(appStoreDir, names[i]);

  await slide.screenshot({
    path: outputPath,
    type: "png"
  });

  execFileSync("sips", ["-z", "2778", "1284", outputPath, "--out", appStorePath], {
    stdio: "ignore"
  });

  console.log(`saved ${outputPath}`);
  console.log(`saved ${appStorePath}`);
}

await browser.close();
