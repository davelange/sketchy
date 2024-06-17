<script lang="ts">
  import Header from "./Header.svelte";
</script>

<div class="bg-zinc-50 h-full">
  <div class="w-[95%] max-w-[3000px] mx-auto">
    <Header />
    <slot />
  </div>
</div>
