<script lang="ts">
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

<main>
  <h1>sketchy</h1>
  <br />
  <form on:submit|preventDefault={handleSubmit}>
    <input
      type="text"
      name="name"
      bind:value={name}
      placeholder="Your name"
      required
    />
    <button type="submit">Create game</button>
  </form>
</main>
