<script lang="ts">
  import { GameState } from "$lib/types";

  export let gameState: GameState;
  export let teamSizesValid: boolean;

  $: activePlayerIds = gameState?.teams?.map((team) => team.active_user_id);
  $: activePlayersDesc = gameState?.players
    ?.filter((player) => activePlayerIds.includes(player.id))
    ?.map((p) => p.name)
    ?.join(" and ");
</script>

{#if gameState?.state === "pending" && gameState?.players.length < 2}
  <p>Waiting for more players to join</p>
{/if}

{#if gameState?.state === "pending" && !teamSizesValid}
  <p>You need at least 2 players in each team to start</p>
{/if}

{#if gameState?.state === "turn_pending" && activePlayerIds?.length}
  <p>{activePlayersDesc} are choosing their words</p>
{/if}
