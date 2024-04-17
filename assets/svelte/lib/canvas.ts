import { writable } from 'svelte/store';
import type { Point, Shape } from './types';

export class Canvas {
	canvas: HTMLCanvasElement;
	context: CanvasRenderingContext2D;
	shapes: Shape[] = [];
	sendQueue: Shape[] = [];
	incomingQueue: Shape[] = [];
	sendQueueId = 0;
	isDrawing = false;

	setup(canvasEl: HTMLCanvasElement) {
		if (this.canvas) return;
		
		this.canvas = canvasEl;
		this.context = this.canvas.getContext('2d')!;
		this.context.lineJoin = 'round';
		this.context.lineCap = 'round';
		this.context.lineWidth = 20;
		this.context.strokeStyle = 'black';
	}

	clear() {
		this.context.clearRect(0, 0, 800, 600);
	}

	handleNewPoint(point: Point) {
		if (!this.isDrawing && !point.clicked) {
			return;
		}

		if (this.isDrawing && !point.clicked) {
			this.isDrawing = false;
			this.sendQueueId++;

			return;
		}

		if (!this.isDrawing) {
			this.shapes.push({
				points: [point]
			});
			this.sendQueue.push({
				points: [point],
				id: this.sendQueueId
			});
			this.isDrawing = true;

			return;
		}

		if (this.isDrawing) {
			this.shapes.at(-1)?.points.push(point);
			this.sendQueue.at(-1)?.points.push(point);

			return;
		}
	}

	handleQueue() {
		if (!this.incomingQueue.length) return;

		const nextPoint = this.incomingQueue.at(0)?.points.shift();

		if (!this.shapes.length || this.shapes.at(-1)?.id !== this.incomingQueue.at(0)?.id) {
			this.shapes.push({ points: [], id: this.incomingQueue.at(0)?.id });
		}

		if (nextPoint) {
			this.shapes.at(-1)?.points.push(nextPoint);
		}

		if (!this.incomingQueue.at(0)?.points.length) {			
			this.incomingQueue.shift();
		}
	}

	renderShapes() {
		this.shapes.forEach((shape) => {
			if (!shape.points?.length) {
				return;
			}

			this.context.moveTo(shape.points[0].x, shape.points[0].y);
			this.context.beginPath();

			shape.points.map((point) => this.context.lineTo(point.x, point.y));

			this.context.stroke();
		});
	}

	handleFrame() {
		this.handleQueue();
		this.clear();
		this.renderShapes();
	}
}

export const canvas = writable(new Canvas());
