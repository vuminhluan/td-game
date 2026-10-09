import Phaser from "phaser";
import { BattleScene } from "./game/scene";
import { BASE, WIDTH, HEIGHT, RULES, type Direction } from "./game/config";
import type { Simulation } from "./game/simulation";
import "./style.css";
const icon = `<svg viewBox="0 0 32 36" fill="none" aria-hidden="true"><path d="M3 3h8l5 7 5-7h8l-4 22-9 8-9-8z" fill="currentColor"/><path d="m9 14 7 5 7-5-3 10h-8z" fill="#171e20"/></svg>`;
document.querySelector<HTMLDivElement>("#app")!.innerHTML = `
<header class="masthead"><a class="brand" href="./" aria-label="Robot Defense">${icon}<span>ROBOT<span class="brand-sub">DEFENSE</span></span></a><div class="header-note">PHÒNG TUYẾN CUỐI CÙNG <span>CHIẾN DỊCH / 01</span></div><div class="live"><i></i> HỆ THỐNG SẴN SÀNG</div></header>
<main><div class="mission-bar"><div><span class="eyebrow">KHU VỰC 07 / KHU CÔNG NGHIỆP</span><h1>Giữ vững phòng tuyến<span>.</span></h1></div><div class="mission-actions"><button id="sound" aria-pressed="false" title="Bật âm thanh">ÂM THANH: TẮT</button><button id="pause" disabled>TẠM DỪNG <kbd>P</kbd></button></div></div>
<div class="console"><section class="battle-section" aria-label="Chiến trường"><div class="battle-top"><span><i class="dot"></i> <span id="field-status">CHỜ TRIỂN KHAI</span></span><span id="clock">00:00</span><span>CAM 01 · TOP VIEW</span></div><div class="arena-frame"><div id="game" aria-label="Game robot bảo vệ căn cứ"></div><div id="overlay"><div class="briefing"><span class="eyebrow" id="overlay-label">NHIỆM VỤ / 01</span><div class="briefing-mark">${icon}</div><h2 id="overlay-title">Căn cứ cần bạn.</h2><p id="overlay-copy">Điều khiển robot, ngăn chặn 5 đợt tấn công.<br>Đừng để kẻ địch phá hủy căn cứ.</p><button class="primary" id="start">TRIỂN KHAI ROBOT <span>→</span></button><span class="briefing-hint">WASD để di chuyển · SPACE để bắn</span></div></div></div><div class="battle-bottom"><span id="message">Sẵn sàng nhận nhiệm vụ</span><span>RD–07</span></div></section>
<aside aria-label="Trạng thái chiến đấu"><section class="wave-section"><div class="panel-label">CHIẾN DỊCH <span id="wave-phase">SẴN SÀNG</span></div><div class="wave-number"><span id="wave">01</span><span>/ 05<small>ĐỢT TẤN CÔNG</small></span></div><div class="wave-track">${Array.from({ length: 5 }, (_, i) => `<i data-wave="${i + 1}"></i>`).join("")}</div></section>
<section class="stats-section"><div class="stat-row"><span>ĐỊCH CÒN LẠI</span><strong id="enemies">05</strong></div><div class="stat-row"><span>ĐIỂM CHIẾN ĐẤU</span><strong id="score">00000</strong></div></section>
<section class="player-section"><div class="panel-label">ROBOT CỦA BẠN <span class="accent">ATK–01</span></div><div class="robot-status"><canvas id="portrait" width="64" height="64" aria-label="Robot đỏ cam"></canvas><div><strong id="lives">× 3</strong><span>ROBOT CÒN LẠI</span></div></div><div class="health-label"><span>GIÁP ROBOT</span><span id="armor">100%</span></div><div class="meter armor"><i id="armor-fill"></i></div></section>
<section class="base-section"><div class="panel-label">TRẠNG THÁI CĂN CỨ <span id="base-status">AN TOÀN</span></div><div class="base-readout">${icon}<strong id="base-hp">100<span>%</span></strong></div><div class="meter"><i id="base-fill"></i></div></section>
<section class="radar-section"><div class="panel-label">BẢN ĐỒ CHIẾN THUẬT <span class="radar-dot">●</span></div><canvas id="radar" width="210" height="190" aria-label="Bản đồ vị trí robot và kẻ địch"></canvas><div class="radar-key"><span><i></i> BẠN</span><span><i></i> KẺ ĐỊCH</span><span><i></i> CĂN CỨ</span></div></section>
</aside></div>
<div class="lower-deck"><section class="controls"><span class="eyebrow">ĐIỀU KHIỂN</span><div><kbd>W</kbd><kbd>A</kbd><kbd>S</kbd><kbd>D</kbd><span>Di chuyển</span></div><div><kbd>SPACE</kbd><span>Bắn</span></div><div><kbd>P</kbd><span>Tạm dừng</span></div></section><section class="legend"><span><i class="brick"></i>Gạch · 3 phát</span><span><i class="steel"></i>Thép · Bất hoại</span><span><i class="water"></i>Nước · Chặn đường</span><span><i class="grass"></i>Cây · Đi xuyên</span></section></div>
<div class="touch-controls" aria-label="Điều khiển cảm ứng"><div class="dpad"><button data-dir="up" aria-label="Đi lên">↑</button><button data-dir="left" aria-label="Đi trái">←</button><button data-dir="down" aria-label="Đi xuống">↓</button><button data-dir="right" aria-label="Đi phải">→</button></div><button id="touch-fire">BẮN ◎</button></div>
</main><footer><span>ROBOT DEFENSE <span class="muted">/ MVP 0.1</span></span><span>MỘT ROBOT. MỘT CĂN CỨ. GIỮ ĐẾN CÙNG.</span></footer>`;
const $ = (id: string) => document.getElementById(id)!;
// Keep touch controls directly below the battlefield, within reach on phones.
document
  .querySelector(".battle-section")!
  .appendChild(document.querySelector(".touch-controls")!);
const scene = new BattleScene();
const game = new Phaser.Game({
  type: Phaser.AUTO,
  parent: "game",
  width: WIDTH,
  height: HEIGHT,
  backgroundColor: "#303a3e",
  pixelArt: true,
  antialias: false,
  scene,
  scale: { mode: Phaser.Scale.FIT, autoCenter: Phaser.Scale.CENTER_BOTH },
  banner: false,
});
let sound = false;
let audio: AudioContext | undefined;
let lastBullets = 0;
let previousStatus = "";
const beep = () => {
  if (!sound || !audio) return;
  const osc = audio.createOscillator(),
    gain = audio.createGain();
  osc.type = "square";
  osc.frequency.setValueAtTime(150, audio.currentTime);
  osc.frequency.exponentialRampToValueAtTime(40, audio.currentTime + 0.07);
  gain.gain.setValueAtTime(0.025, audio.currentTime);
  gain.gain.exponentialRampToValueAtTime(0.001, audio.currentTime + 0.08);
  osc.connect(gain);
  gain.connect(audio.destination);
  osc.start();
  osc.stop(audio.currentTime + 0.08);
};
$("sound").onclick = () => {
  sound = !sound;
  if (sound) {
    audio ??= new AudioContext();
    void audio.resume();
  }
  $("sound").textContent = `ÂM THANH: ${sound ? "BẬT" : "TẮT"}`;
  $("sound").setAttribute("aria-pressed", String(sound));
};
$("start").onclick = () => {
  if (scene.sim.status === "ready") scene.start();
  else if (scene.sim.status === "paused") scene.togglePause();
  else scene.restart();
  if (audio) void audio.resume();
  ($("start") as HTMLButtonElement).blur();
};
$("pause").onclick = () => {
  scene.togglePause();
  ($("pause") as HTMLButtonElement).blur();
};
for (const button of document.querySelectorAll<HTMLButtonElement>(
  "[data-dir]",
)) {
  button.onpointerdown = (e) => {
    button.setPointerCapture(e.pointerId);
    scene.touchDirection = button.dataset.dir as Direction;
  };
  const release = () => {
    scene.touchDirection = undefined;
  };
  button.onpointerup = release;
  button.onpointercancel = release;
  button.onlostpointercapture = release;
}
$("touch-fire").onpointerdown = (e) => {
  $("touch-fire").setPointerCapture(e.pointerId);
  scene.touchFire = true;
};
for (const name of ["pointerup", "pointercancel", "lostpointercapture"])
  $("touch-fire").addEventListener(name, () => (scene.touchFire = false));
function render(sim: Simulation) {
  $("wave").textContent = String(sim.wave || 1).padStart(2, "0");
  $("enemies").textContent = String(
    sim.status === "ready" ? 5 : sim.toSpawn + sim.enemies.length,
  ).padStart(2, "0");
  $("score").textContent = String(sim.score).padStart(5, "0");
  $("lives").textContent = `× ${sim.lives}`;
  $("armor").textContent =
    `${(Math.max(0, sim.player.hp) / RULES.playerHp) * 100}%`;
  $("armor-fill").style.width =
    `${(Math.max(0, sim.player.hp) / RULES.playerHp) * 100}%`;
  const hp = (Math.max(0, sim.baseHp) / RULES.baseHp) * 100;
  $("base-hp").innerHTML = `${hp}<span>%</span>`;
  $("base-fill").style.width = `${hp}%`;
  $("base-status").textContent =
    hp > 50 ? "AN TOÀN" : hp > 0 ? "NGUY CẤP" : "THẤT THỦ";
  $("clock").textContent = `${Math.floor(sim.elapsed / 60)
    .toString()
    .padStart(2, "0")}:${Math.floor(sim.elapsed % 60)
    .toString()
    .padStart(2, "0")}`;
  $("message").textContent = sim.message;
  $("field-status").textContent =
    sim.status === "playing"
      ? "ĐANG GIAO TRANH"
      : sim.status === "paused"
        ? "TẠM DỪNG"
        : sim.status === "ready"
          ? "CHỜ TRIỂN KHAI"
          : "NHIỆM VỤ KẾT THÚC";
  $("wave-phase").textContent =
    sim.status === "playing"
      ? "ĐANG DIỄN RA"
      : sim.status === "won"
        ? "HOÀN THÀNH"
        : "CHỜ LỆNH";
  document
    .querySelectorAll<HTMLElement>("[data-wave]")
    .forEach((el) =>
      el.classList.toggle("active", Number(el.dataset.wave) <= sim.wave),
    );
  ($("pause") as HTMLButtonElement).disabled = !["playing", "paused"].includes(
    sim.status,
  );
  $("pause").innerHTML =
    sim.status === "paused" ? "TIẾP TỤC <kbd>P</kbd>" : "TẠM DỪNG <kbd>P</kbd>";
  $("overlay").hidden = sim.status === "playing";
  if (sim.status !== previousStatus) {
    if (sim.status === "paused") {
      $("overlay-label").textContent = "TẠM DỪNG";
      $("overlay-title").textContent = "Chờ lệnh của bạn.";
      $("overlay-copy").textContent =
        "Chiến trường đã tạm dừng. Tiếp tục khi bạn sẵn sàng.";
      $("start").innerHTML = "TIẾP TỤC <span>→</span>";
    } else if (sim.status === "won" || sim.status === "lost") {
      $("overlay-label").textContent =
        sim.status === "won" ? "NHIỆM VỤ HOÀN THÀNH" : "NHIỆM VỤ THẤT BẠI";
      $("overlay-title").textContent =
        sim.status === "won" ? "Căn cứ đứng vững." : "Phòng tuyến đã vỡ.";
      $("overlay-copy").textContent =
        `${sim.message}. Tiêu diệt ${sim.kills} kẻ địch · ${sim.score} điểm.`;
      $("start").innerHTML = "CHƠI LẠI <span>↻</span>";
    }
    previousStatus = sim.status;
  }
  const radar = ($("radar") as HTMLCanvasElement).getContext("2d")!;
  radar.fillStyle = "#152023";
  radar.fillRect(0, 0, 210, 190);
  const colors: Record<string, string> = {
    brick: "#a86242",
    steel: "#768487",
    water: "#316b83",
    grass: "#536c37",
  };
  sim.map.forEach((row, y) =>
    row.forEach((t, x) => {
      if (t.kind !== "floor") {
        radar.fillStyle = colors[t.kind];
        radar.fillRect(x * 10 + 1, y * 10 + 1, 8, 8);
      }
    }),
  );
  radar.fillStyle = "#8dc6b8";
  radar.fillRect(BASE.x / 4 - 6, BASE.y / 4 - 6, 12, 12);
  radar.fillStyle = "#bae393";
  radar.fillRect(sim.player.x / 4 - 3, sim.player.y / 4 - 3, 6, 6);
  radar.fillStyle = "#f47e56";
  for (const e of sim.enemies) radar.fillRect(e.x / 4 - 3, e.y / 4 - 3, 6, 6);
  if (sim.bullets.length > lastBullets) beep();
  lastBullets = sim.bullets.length;
  const portrait = ($("portrait") as HTMLCanvasElement).getContext("2d")!;
  if (scene.textures.exists("player")) {
    portrait.imageSmoothingEnabled = false;
    portrait.clearRect(0, 0, 64, 64);
    portrait.drawImage(
      scene.textures.get("player").getSourceImage() as HTMLCanvasElement,
      0,
      0,
      64,
      64,
    );
  }
}
scene.onChange = render;
// Expose only in dev for deterministic browser playtests.
if (import.meta.env.DEV)
  Object.assign(window, { __battle: scene, __game: game });
