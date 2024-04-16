<script lang="ts">
  import socket from "js/user_socket";

  export let number: number;

  let count = number;
</script>

<div>{count}</div>
<button on:click={() => count++}>Increment</button>
