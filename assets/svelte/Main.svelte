<script lang="ts">
  export let number: number;
  export let live;

  let count = number;
</script>

<div>{count}</div>
<button on:click={() => count++}>Increment</button>
