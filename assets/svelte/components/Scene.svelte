<script lang="ts">
  import { canvas } from "$lib/canvas";
  import { joinChannel } from "$lib/channel";
  import CanvasWrapper from "./CanvasWrapper.svelte";
  import type {
    GameState,
    GameStatus,
    OnJoinData,
    OnUserGuess,
    Shape,
    User,
  } from "$lib/types";
  import Timer from "./Timer.svelte";

  export let gameId: string;
  export let userName: string;
  export let live: any;

  let users: User[] = [];
  let userId = "";
  let activeUser: User;
  let gameStatus: GameStatus;
  let turnDuration: number;
  let guesses: string[] = [];

  $: isActiveUser = activeUser?.id === userId;

  const { updateShapes, startGame, startTurn, makeGuess } = joinChannel({
    id: gameId,
    userName,
    onJoin,
    onJoinFail,
    onUserJoined,
    onShapesUpdated,
    onTurnUpdate,
    onUserGuess,
  });

  function onJoinFail() {
    live.pushEvent("go_to_home");
  }

  function onJoin(data: OnJoinData) {
    userId = data.self.id;
    users = [...data.users, data.self];
    $canvas.shapes = data.shapes;
    gameStatus = data.status;
    activeUser = data.active_user;
    turnDuration = (data.remaining_in_turn || data.turn_duration) / 1000;
  }

  function onTurnUpdate({ status, active_user }: GameState) {
    gameStatus = status;
    activeUser = active_user;

    if (status === "turn_pending") {
      $canvas.sendQueue = [];
      $canvas.incomingQueue = [];
      $canvas.shapes = [];
      $canvas.sendQueueId = 0;
      guesses = [];
    }
  }

  function onUserGuess(data: OnUserGuess) {
    guesses = [
      ...guesses,
      `${data.user.name} guessed ${data.value}. ${data.correct ? "Yes!" : "Nope."}`,
    ];
  }

  function onUserJoined(state: GameState) {
    users = state.users;
  }

  function onShapesUpdated({ shapes }: { shapes: Shape[] }) {
    if (userId === activeUser.id) {
      return;
    }

    $canvas.incomingQueue.push(...shapes);
  }
</script>

<div>
  <p>Players</p>
  <div>
    {#each users as user (user.id)}
      <p style:font-weight={user.id === userId ? "bold" : ""}>{user.name}</p>
    {/each}
  </div>
  <hr />
  <p>State: {gameStatus}</p>

  {#if gameStatus === "turn_ongoing"}
    <Timer {turnDuration} />
  {/if}

  <CanvasWrapper
    enabled={activeUser?.id === userId && gameStatus === "turn_ongoing"}
    pushToChannel={updateShapes}
  />

  {#if gameStatus === "turn_pending"}
    <p>{activeUser?.name}'s turn, they're choosing a word.</p>
  {/if}

  {#if gameStatus === "pending"}
    <button on:click={startGame}> Start game </button>
  {/if}

  {#if isActiveUser && gameStatus === "turn_pending"}
    <form
      on:submit|preventDefault={(ev) => {
        const value =
          new FormData(ev.currentTarget).get("word")?.toString() || "";
        startTurn({ value });
      }}
    >
      <input type="text" name="word" placeholder="The word" required />
      <button> Start turn </button>
    </form>
  {/if}

  {#if !isActiveUser && gameStatus === "turn_ongoing"}
    <form
      on:submit|preventDefault={(ev) => {
        const value =
          new FormData(ev.currentTarget).get("guess")?.toString() || "";
        makeGuess({ value });
      }}
    >
      <input type="text" name="guess" placeholder="Guess" required />
      <button> Guess </button>
    </form>
  {/if}

  <hr />
  {#each guesses as guess}
    <p>{guess}</p>
  {/each}
</div>
