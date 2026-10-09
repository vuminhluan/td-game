import Phaser from "phaser";
// All artwork is generated once; swap these named textures for a sprite atlas later.
export function createTextures(scene: Phaser.Scene) {
  const texture = (
    name: string,
    w: number,
    h: number,
    paint: (c: CanvasRenderingContext2D) => void,
  ) => {
    const t = scene.textures.createCanvas(name, w, h)!;
    paint(t.context);
    t.refresh();
  };
  const rect = (
    c: CanvasRenderingContext2D,
    x: number,
    y: number,
    w: number,
    h: number,
    color: string,
  ) => {
    c.fillStyle = color;
    c.fillRect(x, y, w, h);
  };
  const plate = (
    c: CanvasRenderingContext2D,
    x: number,
    y: number,
    w: number,
    h: number,
    color: string,
  ) => {
    rect(c, x + 1, y + 3, w, h, "#101719");
    rect(c, x, y, w, h, color);
    rect(c, x, y, w, 1, "#7a8586");
    rect(c, x, y, 1, h, "#566166");
    rect(c, x + w - 1, y, 1, h, "#182124");
    rect(c, x, y + h - 2, w, 2, "#182124");
  };
  let seed = 23;
  const random = () => {
    seed = (seed * 1664525 + 1013904223) >>> 0;
    return seed / 4294967296;
  };
  for (let n = 0; n < 4; n++)
    texture(`floor${n}`, 40, 40, (c) => {
      rect(c, 0, 0, 40, 40, ["#303a3e", "#333d40", "#2e393d", "#354044"][n]);
      rect(c, 0, 0, 40, 1, "#4a5457");
      rect(c, 0, 0, 1, 40, "#475156");
      rect(c, 39, 0, 1, 40, "#192226");
      rect(c, 0, 39, 40, 1, "#192226");
      for (let i = 0; i < 110; i++) {
        c.globalAlpha = 0.1;
        rect(
          c,
          random() * 40,
          random() * 40,
          1,
          1,
          random() > 0.5 ? "#a8b8b8" : "#101718",
        );
      }
      c.globalAlpha = 1;
      for (const x of [3, 35])
        for (const y of [3, 35]) {
          rect(c, x, y, 2, 2, "#162023");
          rect(c, x, y, 1, 1, "#7a8485");
        }
      if (n === 2) {
        c.strokeStyle = "#495356";
        c.beginPath();
        c.moveTo(8, 24);
        c.lineTo(17, 21);
        c.lineTo(21, 14);
        c.stroke();
      }
    });
  for (let hp = 1; hp <= 3; hp++)
    texture(`brick${hp}`, 40, 40, (c) => {
      rect(c, 0, 3, 40, 37, "#191c19");
      for (let row = 0; row < 4; row++)
        for (let col = -1; col < 3; col++) {
          let x = col * 20 + (row % 2) * 10,
            y = row * 9;
          plate(
            c,
            x + 1,
            y + 1,
            18,
            8,
            ["#96513a", "#ad6040", "#874632"][(row + col + 4) % 3],
          );
          rect(c, x + 2, y + 2, 15, 1, "#d39165");
        }
      if (hp < 3) {
        c.strokeStyle = "#251e1a";
        c.lineWidth = 2;
        c.beginPath();
        c.moveTo(17, 0);
        c.lineTo(23, 8);
        c.lineTo(16, 17);
        c.lineTo(23, 25);
        c.lineTo(18, 37);
        c.stroke();
      }
      if (hp === 1) {
        c.lineWidth = 3;
        c.beginPath();
        c.moveTo(2, 11);
        c.lineTo(17, 17);
        c.lineTo(34, 29);
        c.lineTo(39, 27);
        c.stroke();
        rect(c, 17, 17, 6, 5, "#262323");
      }
    });
  texture("steel", 40, 40, (c) => {
    plate(c, 1, 1, 38, 38, "#778084");
    plate(c, 5, 5, 30, 29, "#596569");
    for (const x of [5, 32])
      for (const y of [5, 31]) {
        rect(c, x, y, 3, 3, "#1d282c");
        rect(c, x, y, 2, 1, "#b1b9b6");
      }
    for (let y = 13; y < 28; y += 4) rect(c, 12, y, 16, 2, "#283439");
  });
  texture("water", 40, 40, (c) => {
    plate(c, 0, 0, 40, 40, "#57676b");
    rect(c, 3, 3, 34, 34, "#174d66");
    for (let i = 0; i < 13; i++) {
      const x = random() * 32 + 4,
        y = random() * 32 + 4;
      c.strokeStyle = i % 2 ? "#28738c" : "#205c76";
      c.beginPath();
      c.moveTo(x, y);
      c.lineTo(x + 5, y - 2);
      c.lineTo(x + 10, y + 1);
      c.stroke();
    }
    rect(c, 3, 3, 34, 2, "#103a4a");
  });
  texture("grass", 48, 48, (c) => {
    for (let i = 0; i < 130; i++) {
      let x = random() * 40 + 4,
        y = random() * 40 + 4;
      c.fillStyle = ["#253d22", "#385326", "#4a652d", "#607b37", "#758340"][
        i % 5
      ];
      c.beginPath();
      c.ellipse(x, y, 2, 4, random() * Math.PI, 0, Math.PI * 2);
      c.fill();
    }
  });
  for (const kind of ["player", "robot", "tank"])
    texture(kind, 48, 48, (c) => {
      c.fillStyle = "#101619";
      c.beginPath();
      c.ellipse(24, 28, 21, 18, 0, 0, Math.PI * 2);
      c.fill();
      const color =
        kind === "player" ? "#bc5938" : kind === "tank" ? "#82845d" : "#647478";
      const light = kind === "player" ? "#f18d54" : "#93a1a1";
      if (kind === "tank") {
        for (const x of [5, 33]) {
          plate(c, x, 8, 10, 34, "#293435");
          for (let y = 10; y < 40; y += 5) rect(c, x + 1, y, 8, 2, "#627072");
        }
        plate(c, 14, 11, 20, 28, color);
        plate(c, 17, 15, 14, 16, "#737e63");
        plate(c, 21, 0, 6, 20, "#a1a489");
        rect(c, 22, 0, 4, 3, "#26312b");
        return;
      }
      for (const x of [10, 28]) {
        plate(c, x, 29, 10, 13, "#263237");
        plate(c, x, 33, 10, 7, color);
      }
      plate(c, 10, 11, 28, 23, "#273337");
      plate(c, 15, 14, 18, 17, color);
      for (const x of [3, 34]) {
        plate(c, x, 12, 11, 13, color);
        rect(c, x + 2, 14, 7, 2, light);
        plate(c, x + 2, 26, 7, 10, "#3f4c4e");
      }
      plate(c, 17, 7, 14, 14, "#7c8583");
      plate(c, 19, 8, 10, 7, "#303c3e");
      rect(c, 20, 13, 8, 3, kind === "player" ? "#a9e4c1" : "#fb6944");
      rect(c, 20, 14, 8, 1, "#f5e2b0");
      plate(c, 33, 1, 5, 28, "#222f33");
      rect(c, 34, 2, 2, 23, "#788582");
      rect(c, 33, 2, 5, 4, "#171d20");
      rect(c, 19, 25, 10, 2, "#1e2a2e");
      rect(c, 19, 25, 3, 2, light);
    });
  texture("base", 100, 100, (c) => {
    for (const x of [6, 75]) {
      plate(c, x, 31, 19, 56, "#333f43");
      for (let y = 37; y < 81; y += 9) plate(c, x + 2, y, 15, 6, "#647071");
    }
    plate(c, 20, 24, 60, 65, "#465458");
    plate(c, 26, 13, 48, 64, "#8b9491");
    plate(c, 31, 16, 38, 22, "#303f44");
    for (let y = 19; y < 35; y += 4) rect(c, 34, y, 32, 2, "#637574");
    plate(c, 30, 43, 40, 30, "#35464a");
    c.fillStyle = "#e37345";
    c.beginPath();
    c.moveTo(38, 47);
    c.lineTo(50, 54);
    c.lineTo(62, 47);
    c.lineTo(57, 61);
    c.lineTo(50, 66);
    c.lineTo(43, 61);
    c.fill();
    plate(c, 38, 73, 24, 20, "#1d2c30");
    rect(c, 42, 77, 16, 3, "#9ad0a1");
    for (const x of [13, 80]) rect(c, x, 61, 6, 10, "#e6a556");
  });
}
