<script lang="ts">
  import { canvas } from "$lib/canvas";
  import { joinChannel } from "$lib/channel";
  import CanvasWrapper from "./CanvasWrapper.svelte";
  import type {
    GameState,
    OnJoinData,
    OnUserGuess,
    Player,
    OnShapesUpdated,
  } from "$lib/types";
  import Timer from "./Timer.svelte";
  import TeamsBoard from "./TeamsBoard.svelte";
  import GameStatusDisplay from "./GameStatusDisplay.svelte";
  import mock from "./mock";
  import SecretForm from "./SecretForm.svelte";
  import GuessForm from "./GuessForm.svelte";

  export let gameId: string;
  export let userName: string;

  let gameState: GameState;
  let userId = "";
  let turnDuration = 0;

  $: activePlayers = gameState?.players?.filter((player) =>
    gameState?.teams?.map((team) => team.active_user_id).includes(player.id)
  );
  $: isActivePlayer = activePlayers?.find((player) => player.id == userId);
  $: player = gameState?.players?.find((player) => player.id == userId);
  $: playersByTeam = gameState?.players?.reduce<Record<string, Player[]>>(
    (acc, player) => {
      if (!player.team) return acc;
      if (!acc?.[player.team]) acc[player.team] = [];
      acc[player.team].push(player);
      return acc;
    },
    {}
  );
  $: teamSizesValid =
    Object.values(playersByTeam || {}).length &&
    Object.values(playersByTeam).reduce(
      (acc, val) => acc && val.length > 1,
      true
    );

  let guesses: string[] = [];

  const { updateShapes, startGame, startTurn, makeGuess, setWord, joinTeam } =
    joinChannel({
      id: gameId,
      userName,
      onJoin,
      onUserJoined,
      onShapesUpdated,
      onTurnUpdate,
      onUserGuess,
    });

  function onJoin(data: OnJoinData) {
    userId = data.self.id;
    gameState = data;
    $canvas.mergeShapes(data.shapes);

    turnDuration = (data.remaining_in_turn || data.turn_duration) / 1000;
  }

  function onTurnUpdate(state: GameState) {
    gameState = state;

    if (state.state === "turn_pending") {
      guesses = [];
      $canvas.reset();
    }

    if (state.state === "turn_ongoing") {
      turnDuration = (state.remaining_in_turn || state.turn_duration) / 1000;
    }
  }

  function onShapesUpdated(data: OnShapesUpdated) {
    if (data.player === player?.id) return;

    $canvas.inQueue.push(...data.shapes);
  }

  function onUserJoined(state) {
    gameState = state;
  }

  function onUserGuess(data: OnUserGuess) {
    guesses = [
      ...guesses,
      `${data.user.name} guessed ${data.value}. ${data.correct ? "Correct!" : "Wrong."}`,
    ];
  }
</script>

{#if gameState}
  <div class="flex gap-4 mb-3">
    <GameStatusDisplay {gameState} {teamSizesValid} />
    {#if gameState.state === "turn_ongoing"}
      <Timer {turnDuration} />
    {/if}
  </div>
  <div class="flex gap-4">
    <TeamsBoard
      {player}
      teams={gameState?.teams}
      players={gameState?.players}
      {joinTeam}
    />
    <div class="relative flex flex-col gap-2">
      <div class="relative border border-zinc-400 rounded">
        <CanvasWrapper
          enabled={isActivePlayer && gameState.state === "turn_ongoing"}
          pushToChannel={updateShapes}
          {player}
        />

        {#if gameState.state === "pending"}
          <div class="absolute inset-0 m-auto w-fit h-fit">
            <button
              on:click={startGame}
              type="button"
              class="bg-violet-700 p-2 text-white disabled:cursor-not-allowed disabled:bg-violet-500"
              disabled={!teamSizesValid}
            >
              Start game
            </button>
          </div>
        {/if}

        {#if isActivePlayer && gameState.state === "turn_pending"}
          <SecretForm onSubmit={setWord} />
        {/if}
      </div>

      {#if !isActivePlayer && gameState.state === "turn_ongoing"}
        <GuessForm onSubmit={makeGuess} />
      {/if}

      <div class="flex flex-col gap-2">
        {#each guesses as guess}
          <p>{guess}</p>
        {/each}
      </div>
    </div>
  </div>
{/if}
