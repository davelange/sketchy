<script lang="ts">
  import { joinChannel } from "js/channel";

  export let id: string;

  joinChannel({
    id,
  });
</script>

<p>Game {id}</p>
