<script lang="ts">
  import { joinChannel } from "$lib/channel";
  import { GameState, Player } from "$lib/types";

  export let teams: GameState["teams"] = [];
  export let players: GameState["players"] = [];
  export let player: Player;
  export let joinTeam: ReturnType<typeof joinChannel>["joinTeam"];

  $: newPlayers = players.filter((p) => !p.team);
</script>

<section class="flex flex-col gap-2 w-1/4">
  {#each teams as team (team.id)}
    <div class="p-2 border border-violet-100 bg-violet-50 rounded">
      <p class="font-bold">
        {team.name} ({team.score} pts)
      </p>
      <div class="my-1">
        <ul>
          {#each players?.filter((player) => player.team === team.id) as user (user.id)}
            <li style:color={user.id === player?.id ? "text-violet-700" : ""}>
              {user.name}
            </li>
          {/each}
        </ul>
      </div>
      {#if player && !player?.team}
        <button
          type="button"
          on:click={() => joinTeam({ teamId: team.id })}
          class="underline text-violet-700"
        >
          Join this team
        </button>
      {/if}
    </div>
  {/each}

  {#if newPlayers.length}
    <div class="p-2 border border-violet-100 rounded">
      <p class="font-bold">New players</p>
      {#each newPlayers as item (item.id)}
        <p style:font-weight={item.id === player?.id ? "bold" : ""}>
          {item.name}
        </p>
      {/each}
    </div>
  {/if}
</section>
