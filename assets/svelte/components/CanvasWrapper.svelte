<script lang="ts">
  import { canvas } from "$lib/canvas";
  import type { joinChannel } from "$lib/channel";
  import { Player } from "$lib/types";
  import { throttle } from "$lib/utils";

  export let enabled: boolean;
  export let player: Player;
  export let pushToChannel: ReturnType<typeof joinChannel>["updateShapes"];

  let canvasEl: HTMLCanvasElement;
  let clicked = false;

  let debouncedSend = throttle(() => {
    const data = $canvas.getOutQueuePayload();

    if (data) {
      pushToChannel(data);
    }
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

  $: if (canvasEl && player) {
    $canvas.setup(canvasEl, player.id);
    render();
  }
</script>

<canvas
  class="canvas"
  width="800"
  height="600"
  bind:this={canvasEl}
  on:mousedown={() => (clicked = true)}
  on:mouseup={() => (clicked = false)}
  on:mousemove={throttle(handleMousemove, 10)}
></canvas>
