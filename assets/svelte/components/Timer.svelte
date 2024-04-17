<script lang="ts">
  import { onMount } from "svelte";

  export let turnDuration: number;

  let interval: ReturnType<typeof setInterval>;
  let remaining = turnDuration;

  function tick() {
    remaining -= 1;
  }

  function start() {
    tick();
    interval = setInterval(tick, 1000);
  }

  onMount(() => {
    start();

    return () => {
      clearInterval(interval);
    };
  });
</script>

{#if remaining}
  <div>
    {Math.round(remaining)}s
  </div>
{/if}
