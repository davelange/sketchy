<script lang="ts">
  import Layout from "$components/Layout.svelte";
  import { onMount } from "svelte";

  export let live;

  let name: string;

  const handleSubmit = async () => {
    localStorage.setItem("name", name);

    live.pushEvent("create_game");
  };

  onMount(() => {
    let localName = localStorage.getItem("name");

    if (localName) {
      name = localName;
    }
  });
</script>

<Layout>
  <main>
    <form
      on:submit|preventDefault={handleSubmit}
      class="flex flex-col gap-2 w-fit mx-auto"
    >
      <h1>Start new game</h1>
      <input
        type="text"
        name="name"
        bind:value={name}
        placeholder="Your name"
        required
      />
      <button type="submit" class="bg-violet-700 py-2 text-white">
        Create game
      </button>
    </form>
  </main>
</Layout>
