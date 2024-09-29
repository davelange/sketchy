import { writable } from "svelte/store";
import { PointAccess, type Point, type Shape } from "./types";
let c = ["tomato", "indigo", "pink", "teal"];

function getQueueChunkSize(length: number) {
  if (length > 30) {
    return 3;
  }

  return 1;
}

export class Canvas {
  playerId: string;
  canvas: HTMLCanvasElement;
  context: CanvasRenderingContext2D;
  shapes: Shape[] = [];
  outQueue: Shape[] = [];
  inQueue: Shape[] = [];
  outQueueId = 0;
  isDrawing = false;

  setup(canvasEl: HTMLCanvasElement, playerId: string) {
    if (this.canvas) return;

    this.playerId = playerId;
    this.canvas = canvasEl;
    this.context = this.canvas.getContext("2d")!;
    this.context.lineJoin = "round";
    this.context.lineCap = "round";
    this.context.lineWidth = 20;
    this.context.strokeStyle = "black";
  }

  clear() {
    this.context.clearRect(0, 0, 800, 600);
  }

  reset() {
    this.outQueue = [];
    this.inQueue = [];
    this.shapes = [];
    this.outQueueId = 0;
  }

  handleNewPoint(point: Point) {
    if (!this.isDrawing && !point[PointAccess.clicked]) {
      return;
    }

    if (this.isDrawing && !point[PointAccess.clicked]) {
      this.isDrawing = false;
      this.outQueueId++;

      return;
    }

    if (!this.isDrawing && point[PointAccess.clicked]) {
      this.shapes.push({
        points: [point],
      });
      this.outQueue.push({
        points: [point],
        id: `${this.playerId}_${this.outQueueId}`,
      });
      this.isDrawing = true;

      return;
    }

    if (this.isDrawing && point[PointAccess.clicked]) {
      this.shapes.at(-1)?.points.push(point);
      this.outQueue.at(-1)?.points.push(point);

      return;
    }
  }

  getOutQueuePayload() {
    if (!this.outQueue.length) {
      return null;
    }

    const payload = {
      shapes: this.outQueue.filter((list) => list.points.length),
      player: this.playerId,
    };

    if (!payload.shapes.length) {
      return null;
    }

    this.outQueue = [
      {
        points: [],
        id: payload.shapes.at(-1)?.id,
      },
    ];

    return payload;
  }

  handleInQueue() {
    if (!this.inQueue.length) {
      return;
    }

    if (!this.inQueue.at(0)?.points.length) {
      this.inQueue.shift();

      if (!this.inQueue.at(0)) return;
    }

    const nextPoints = this.inQueue
      .at(0)
      ?.points.splice(0, getQueueChunkSize(this.inQueue.at(0)?.points.length));

    this.mergePoints(nextPoints, this.inQueue.at(0).id);
  }

  mergeShapes(newShapes: Shape[]) {
    for (const shape of newShapes.slice().reverse()) {
      this.mergePoints(shape.points, shape.id);
    }
  }

  mergePoints(points: Point[], shapeId: string) {
    for (const point of points) {
      if (!this.shapes.length || this.shapes.at(-1)?.id !== shapeId) {
        this.shapes.push({ points: [], id: shapeId });
      }

      this.shapes.at(-1)?.points.push(point);
    }
  }

  renderShapes() {
    this.shapes.forEach((shape) => {
      if (!shape.points?.length) {
        return;
      }

      this.context.beginPath();

      this.context.moveTo(
        shape.points[0][PointAccess.x],
        shape.points[0][PointAccess.y]
      );
      shape.points.map((point) =>
        this.context.lineTo(point[PointAccess.x], point[PointAccess.y])
      );

      this.context.stroke();
    });
  }

  handleFrame() {
    this.handleInQueue();
    this.clear();
    this.renderShapes();
  }
}

export const canvas = writable(new Canvas());
