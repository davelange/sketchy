<script lang="ts">
  import { joinChannel } from "$lib/channel";

  export let onSubmit: ReturnType<typeof joinChannel>["setWord"];

  let submitted = false;
</script>

<div class="absolute inset-0 m-auto w-fit h-fit">
  <form
    class="flex flex-col gap-2"
    on:submit|preventDefault={(ev) => {
      const value =
        new FormData(ev.currentTarget).get("word")?.toString() || "";
      onSubmit({ value });
      submitted = true;
    }}
  >
    <label for="word"> It's your turn, choose your secret word </label>
    <div class="flex gap-2">
      <input
        id="word"
        type="text"
        name="word"
        placeholder="The word"
        required
        class="block disabled:cursor-not-allowed disabled:text-gray-800"
        disabled={submitted}
      />
      <button
        type="submit"
        class="bg-violet-700 p-2 text-white disabled:cursor-not-allowed disabled:bg-violet-500"
        disabled={submitted}
      >
        Done
      </button>
    </div>

    <p class:opacity-0={!submitted}>
      Waiting for the other teams to choose words...
    </p>
  </form>
</div>
