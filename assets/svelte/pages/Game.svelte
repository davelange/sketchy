<script lang="ts">
  import Layout from "$components/Layout.svelte";
  import Scene from "$components/Scene.svelte";
  import { onMount } from "svelte";

  export let gameId: string;

  let userName: string;

  const onSubmit = (event) => {
    userName = new FormData(event.currentTarget).get("name").toString();
  };

  onMount(() => {
    let localName = localStorage.getItem("name");

    if (localName) {
      userName = localName;
    }
  });
</script>

<Layout>
  {#if userName}
    <Scene {gameId} {userName} />
  {:else}
    <form
      on:submit|preventDefault={onSubmit}
      class="flex flex-col gap-2 w-fit mx-auto"
    >
      <h1>Join this game</h1>
      <input type="text" name="name" placeholder="Your name" required />
      <button type="submit" class="bg-violet-700 py-2 text-white">
        Join
      </button>
    </form>
  {/if}
</Layout>
