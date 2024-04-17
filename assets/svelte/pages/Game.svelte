<script lang="ts">
  import Scene from "$components/Scene.svelte";
  import { onMount } from "svelte";

  export let gameId: string;

  let userName: string;

  const onSubmit = (event) => {
    let input = new FormData(event.currentTarget).get("name").toString();

    localStorage.setItem("name", input);

    userName = input;
  };

  onMount(() => {
    let localName = localStorage.getItem("name");

    if (localName) {
      userName = localName;
    }
  });
</script>

{#if userName}
  <Scene {gameId} {userName} />
{:else}
  <h1>Join game</h1>
  <form action="" on:submit|preventDefault={onSubmit}>
    <input type="text" name="name" placeholder="Your name" required />
    <button type="submit">Play</button>
  </form>
{/if}
