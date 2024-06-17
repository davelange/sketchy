<script lang="ts">
  import { joinChannel } from "$lib/channel";

  export let onSubmit: ReturnType<typeof joinChannel>["makeGuess"];

  let input: HTMLInputElement;
</script>

<form
  class="self-center"
  on:submit|preventDefault={(ev) => {
    const value = new FormData(ev.currentTarget).get("guess")?.toString() || "";
    onSubmit({ value });
    input.value = "";
  }}
>
  <input
    bind:this={input}
    type="text"
    name="guess"
    placeholder="Your guess"
    required
  />
  <button
    class="bg-violet-700 p-2 text-white disabled:cursor-not-allowed disabled:bg-violet-500"
  >
    Submit
  </button>
</form>
