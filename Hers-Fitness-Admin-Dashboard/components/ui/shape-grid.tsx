"use client";

import { useEffect, useRef } from "react";

type CanvasStrokeStyle = string | CanvasGradient | CanvasPattern;

interface GridOffset {
  x: number;
  y: number;
}

interface ShapeGridProps {
  direction?: "diagonal" | "up" | "right" | "down" | "left";
  speed?: number;
  borderColor?: CanvasStrokeStyle;
  squareSize?: number;
  hoverFillColor?: CanvasStrokeStyle;
  shape?: "square" | "hexagon" | "circle" | "triangle";
  hoverTrailAmount?: number;
}

export default function ShapeGrid({
  direction = "right",
  speed = 1,
  borderColor = "#999",
  squareSize = 40,
  hoverFillColor = "#222",
  shape = "square",
  hoverTrailAmount = 0,
}: ShapeGridProps) {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const requestRef = useRef<number | null>(null);
  const gridOffset = useRef<GridOffset>({ x: 0, y: 0 });
  const hoveredSquareRef = useRef<GridOffset | null>(null);
  const recentCells = useRef<GridOffset[]>([]);
  const trailCells = useRef<GridOffset[]>([]);
  const exitTrailCells = useRef<GridOffset[]>([]);
  const exitTrailStartedAt = useRef<number | null>(null);
  const cellOpacities = useRef<Map<string, number>>(new Map());

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;

    const ctx = canvas.getContext("2d");
    if (!ctx) return;

    const isHex = shape === "hexagon";
    const isTri = shape === "triangle";
    const hexHoriz = squareSize * 1.5;
    const hexVert = squareSize * Math.sqrt(3);

    const resizeCanvas = () => {
      canvas.width = canvas.offsetWidth;
      canvas.height = canvas.offsetHeight;
    };

    const drawHex = (cx: number, cy: number, size: number) => {
      ctx.beginPath();
      for (let i = 0; i < 6; i++) {
        const angle = (Math.PI / 3) * i;
        const vx = cx + size * Math.cos(angle);
        const vy = cy + size * Math.sin(angle);
        if (i === 0) ctx.moveTo(vx, vy);
        else ctx.lineTo(vx, vy);
      }
      ctx.closePath();
    };

    const drawCircle = (cx: number, cy: number, size: number) => {
      ctx.beginPath();
      ctx.arc(cx, cy, size / 2, 0, Math.PI * 2);
      ctx.closePath();
    };

    const drawTriangle = (cx: number, cy: number, size: number, flip: boolean) => {
      ctx.beginPath();
      if (flip) {
        ctx.moveTo(cx, cy + size / 2);
        ctx.lineTo(cx + size / 2, cy - size / 2);
        ctx.lineTo(cx - size / 2, cy - size / 2);
      } else {
        ctx.moveTo(cx, cy - size / 2);
        ctx.lineTo(cx + size / 2, cy + size / 2);
        ctx.lineTo(cx - size / 2, cy + size / 2);
      }
      ctx.closePath();
    };

    const updateCellOpacities = () => {
      const targets = new Map<string, number>();
      const now = performance.now();

      if (hoveredSquareRef.current) {
        targets.set(`${hoveredSquareRef.current.x},${hoveredSquareRef.current.y}`, 1);
      }

      if (hoverTrailAmount > 0) {
        for (let i = 0; i < trailCells.current.length; i++) {
          const cell = trailCells.current[i];
          const key = `${cell.x},${cell.y}`;
          if (!targets.has(key)) {
            targets.set(key, (trailCells.current.length - i) / (trailCells.current.length + 1));
          }
        }
      }

      if (!hoveredSquareRef.current && exitTrailCells.current.length > 0) {
        const elapsed = exitTrailStartedAt.current ? now - exitTrailStartedAt.current : 0;
        const staggerMs = 110;

        for (let i = 0; i < exitTrailCells.current.length; i++) {
          const cell = exitTrailCells.current[i];
          const key = `${cell.x},${cell.y}`;

          if (elapsed < i * staggerMs) {
            targets.set(key, 1);
          }
        }

        if (elapsed > exitTrailCells.current.length * staggerMs + 900) {
          exitTrailCells.current = [];
          exitTrailStartedAt.current = null;
        }
      }

      for (const [key] of targets) {
        if (!cellOpacities.current.has(key)) cellOpacities.current.set(key, 0);
      }

      for (const [key, opacity] of cellOpacities.current) {
        const target = targets.get(key) || 0;
        const next = opacity + (target - opacity) * 0.15;
        if (next < 0.005) cellOpacities.current.delete(key);
        else cellOpacities.current.set(key, next);
      }
    };

    const drawGrid = () => {
      ctx.clearRect(0, 0, canvas.width, canvas.height);

      const colShift = Math.floor(gridOffset.current.x / squareSize);
      const rowShift = Math.floor(gridOffset.current.y / squareSize);

      if (isHex) {
        const hexColShift = Math.floor(gridOffset.current.x / hexHoriz);
        const hexRowShift = Math.floor(gridOffset.current.y / hexVert);
        const offsetX = ((gridOffset.current.x % hexHoriz) + hexHoriz) % hexHoriz;
        const offsetY = ((gridOffset.current.y % hexVert) + hexVert) % hexVert;
        const cols = Math.ceil(canvas.width / hexHoriz) + 3;
        const rows = Math.ceil(canvas.height / hexVert) + 3;

        for (let col = -2; col < cols; col++) {
          for (let row = -2; row < rows; row++) {
            const cx = col * hexHoriz + offsetX;
            const cy = row * hexVert + ((col + hexColShift) % 2 !== 0 ? hexVert / 2 : 0) + offsetY;
            
            // Use absolute coordinates for key
            const alpha = cellOpacities.current.get(`${col - hexColShift},${row - hexRowShift}`);
            
            if (alpha) {
              ctx.globalAlpha = alpha;
              drawHex(cx, cy, squareSize);
              ctx.fillStyle = hoverFillColor;
              ctx.fill();
              ctx.globalAlpha = 1;
            }
            drawHex(cx, cy, squareSize);
            ctx.strokeStyle = borderColor;
            ctx.stroke();
          }
        }
      } else if (isTri) {
        const halfW = squareSize / 2;
        const triColShift = Math.floor(gridOffset.current.x / halfW);
        const triRowShift = Math.floor(gridOffset.current.y / squareSize);
        const offsetX = ((gridOffset.current.x % halfW) + halfW) % halfW;
        const offsetY = ((gridOffset.current.y % squareSize) + squareSize) % squareSize;
        const cols = Math.ceil(canvas.width / halfW) + 4;
        const rows = Math.ceil(canvas.height / squareSize) + 4;

        for (let col = -2; col < cols; col++) {
          for (let row = -2; row < rows; row++) {
            const cx = col * halfW + offsetX;
            const cy = row * squareSize + squareSize / 2 + offsetY;
            const flip = ((col + triColShift + row + triRowShift) % 2 + 2) % 2 !== 0;
            
            const alpha = cellOpacities.current.get(`${col - triColShift},${row - triRowShift}`);
            
            if (alpha) {
              ctx.globalAlpha = alpha;
              drawTriangle(cx, cy, squareSize, flip);
              ctx.fillStyle = hoverFillColor;
              ctx.fill();
              ctx.globalAlpha = 1;
            }
            drawTriangle(cx, cy, squareSize, flip);
            ctx.strokeStyle = borderColor;
            ctx.stroke();
          }
        }
      } else if (shape === "circle") {
        const offsetX = ((gridOffset.current.x % squareSize) + squareSize) % squareSize;
        const offsetY = ((gridOffset.current.y % squareSize) + squareSize) % squareSize;
        const cols = Math.ceil(canvas.width / squareSize) + 3;
        const rows = Math.ceil(canvas.height / squareSize) + 3;

        for (let col = -2; col < cols; col++) {
          for (let row = -2; row < rows; row++) {
            const cx = col * squareSize + squareSize / 2 + offsetX;
            const cy = row * squareSize + squareSize / 2 + offsetY;
            
            const alpha = cellOpacities.current.get(`${col - colShift},${row - rowShift}`);
            
            if (alpha) {
              ctx.globalAlpha = alpha;
              drawCircle(cx, cy, squareSize);
              ctx.fillStyle = hoverFillColor;
              ctx.fill();
              ctx.globalAlpha = 1;
            }
            drawCircle(cx, cy, squareSize);
            ctx.strokeStyle = borderColor;
            ctx.stroke();
          }
        }
      } else {
        const offsetX = ((gridOffset.current.x % squareSize) + squareSize) % squareSize;
        const offsetY = ((gridOffset.current.y % squareSize) + squareSize) % squareSize;
        const cols = Math.ceil(canvas.width / squareSize) + 3;
        const rows = Math.ceil(canvas.height / squareSize) + 3;

        for (let col = -2; col < cols; col++) {
          for (let row = -2; row < rows; row++) {
            const sx = col * squareSize + offsetX;
            const sy = row * squareSize + offsetY;
            
            const alpha = cellOpacities.current.get(`${col - colShift},${row - rowShift}`);
            
            if (alpha) {
              ctx.globalAlpha = alpha;
              ctx.fillStyle = hoverFillColor;
              ctx.fillRect(sx, sy, squareSize, squareSize);
              ctx.globalAlpha = 1;
            }
            ctx.strokeStyle = borderColor;
            ctx.strokeRect(sx, sy, squareSize, squareSize);
          }
        }
      }

      const gradient = ctx.createRadialGradient(
        canvas.width / 2,
        canvas.height / 2,
        0,
        canvas.width / 2,
        canvas.height / 2,
        Math.sqrt(canvas.width ** 2 + canvas.height ** 2) / 2,
      );
      gradient.addColorStop(0, "rgba(0, 0, 0, 0)");
      gradient.addColorStop(1, "#120F17");
      ctx.fillStyle = gradient;
      ctx.fillRect(0, 0, canvas.width, canvas.height);
    };

    const updateAnimation = () => {
      const effectiveSpeed = Math.max(speed, 0.1);
      const wrapX = isHex ? hexHoriz * 2 : squareSize;
      const wrapY = isHex ? hexVert : isTri ? squareSize * 2 : squareSize;

      switch (direction) {
        case "right":
          gridOffset.current.x = (gridOffset.current.x - effectiveSpeed + wrapX) % wrapX;
          break;
        case "left":
          gridOffset.current.x = (gridOffset.current.x + effectiveSpeed + wrapX) % wrapX;
          break;
        case "up":
          gridOffset.current.y = (gridOffset.current.y + effectiveSpeed + wrapY) % wrapY;
          break;
        case "down":
          gridOffset.current.y = (gridOffset.current.y - effectiveSpeed + wrapY) % wrapY;
          break;
        case "diagonal":
          gridOffset.current.x = (gridOffset.current.x - effectiveSpeed + wrapX) % wrapX;
          gridOffset.current.y = (gridOffset.current.y - effectiveSpeed + wrapY) % wrapY;
          break;
      }

      updateCellOpacities();
      drawGrid();
      requestRef.current = requestAnimationFrame(updateAnimation);
    };

    const rememberCell = (cell: GridOffset) => {
      if (hoverTrailAmount <= 0) return;
      trailCells.current.unshift({ ...cell });
      if (trailCells.current.length > hoverTrailAmount) {
        trailCells.current.length = hoverTrailAmount;
      }
    };

    const rememberRecentCell = (cell: GridOffset) => {
      const last = recentCells.current[recentCells.current.length - 1];
      if (last && last.x === cell.x && last.y === cell.y) return;

      recentCells.current.push({ ...cell });
      if (recentCells.current.length > 4) {
        recentCells.current.shift();
      }
    };

    const startExitTrail = () => {
      const exitCells = hoveredSquareRef.current
        ? [...recentCells.current, hoveredSquareRef.current]
        : [...recentCells.current];
      const uniqueExitCells: GridOffset[] = [];

      for (const cell of exitCells) {
        const last = uniqueExitCells[uniqueExitCells.length - 1];
        if (!last || last.x !== cell.x || last.y !== cell.y) {
          uniqueExitCells.push({ ...cell });
        }
      }

      exitTrailCells.current = uniqueExitCells.slice(-4);
      exitTrailStartedAt.current = performance.now();
      hoveredSquareRef.current = null;
      recentCells.current = [];
      trailCells.current = [];
    };

    const handleMouseMove = (event: MouseEvent) => {
      const rect = canvas.getBoundingClientRect();
      const mouseX = event.clientX - rect.left;
      const mouseY = event.clientY - rect.top;

      const elementAtPoint = document.elementFromPoint(event.clientX, event.clientY);
      if (elementAtPoint !== canvas) {
        if (hoveredSquareRef.current || recentCells.current.length > 0) {
          startExitTrail();
        }
        return;
      }

      let nextCell: GridOffset;

      const absX = mouseX - gridOffset.current.x;
      const absY = mouseY - gridOffset.current.y;

      if (isHex) {
        const hexColShift = Math.floor(gridOffset.current.x / hexHoriz);
        const col = Math.round(absX / hexHoriz);
        const rowOffset = (col + hexColShift) % 2 !== 0 ? hexVert / 2 : 0;
        const row = Math.round((absY - rowOffset) / hexVert);
        nextCell = { x: col, y: row };
      } else if (isTri) {
        const halfW = squareSize / 2;
        nextCell = {
          x: Math.round(absX / halfW),
          y: Math.floor(absY / squareSize),
        };
      } else if (shape === "circle") {
        nextCell = {
          x: Math.round(absX / squareSize),
          y: Math.round(absY / squareSize),
        };
      } else {
        nextCell = {
          x: Math.floor(absX / squareSize),
          y: Math.floor(absY / squareSize),
        };
      }

      if (
        !hoveredSquareRef.current ||
        hoveredSquareRef.current.x !== nextCell.x ||
        hoveredSquareRef.current.y !== nextCell.y
      ) {
        if (hoveredSquareRef.current) {
          rememberCell(hoveredSquareRef.current);
          rememberRecentCell(hoveredSquareRef.current);
        }
        exitTrailCells.current = [];
        exitTrailStartedAt.current = null;
        hoveredSquareRef.current = nextCell;
      }
    };

    const handleMouseLeave = () => {
      startExitTrail();
    };

    window.addEventListener("resize", resizeCanvas);
    window.addEventListener("mousemove", handleMouseMove);
    canvas.addEventListener("mouseleave", handleMouseLeave);
    resizeCanvas();
    requestRef.current = requestAnimationFrame(updateAnimation);

    return () => {
      window.removeEventListener("resize", resizeCanvas);
      window.removeEventListener("mousemove", handleMouseMove);
      canvas.removeEventListener("mouseleave", handleMouseLeave);
      if (requestRef.current) cancelAnimationFrame(requestRef.current);
    };
  }, [direction, speed, borderColor, squareSize, hoverFillColor, shape, hoverTrailAmount]);

  return <canvas ref={canvasRef} aria-hidden="true" className="block h-full w-full border-none" />;
}
