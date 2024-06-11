<script lang="ts">
  import { canvas } from "$lib/canvas";
  import type { joinChannel } from "$lib/channel";
  import { throttle } from "$lib/utils";

  export let enabled: boolean;
  export let pushToChannel: ReturnType<typeof joinChannel>["updateShapes"];

  let canvasEl: HTMLCanvasElement;
  let clicked = false;

  let debouncedSend = throttle(() => {
    pushToChannel({ shapes: $canvas.sendQueue });
    $canvas.sendQueue = [{ points: [], id: $canvas.sendQueueId }];
  }, 200);

  function handleMousemove(event: MouseEvent) {
    if (!enabled) return;

    $canvas.handleNewPoint([
      Math.round(event.offsetX),
      Math.round(event.offsetY),
      Number(clicked),
    ]);
    debouncedSend();
  }

  function render() {
    $canvas.handleFrame();

    requestAnimationFrame(render);
  }

  $: if (canvasEl) {
    $canvas.setup(canvasEl);
    render();
  }
</script>

<div style="position: relative; margin: 1rem">
  <canvas
    class="canvas"
    width="800"
    height="600"
    bind:this={canvasEl}
    on:mousedown={() => (clicked = true)}
    on:mouseup={() => (clicked = false)}
    on:mousemove={throttle(handleMousemove, 10)}
  ></canvas>
</div>

<style>
  .canvas {
    border: 1px solid black;
  }
</style>
