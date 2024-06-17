import { Socket } from "phoenix";
import type {
  GameState,
  OnJoinData,
  OnUserGuess,
  Shape,
  Player,
  OnShapesUpdated,
} from "./types";

type EventCallback<T> = (data: T) => void;

let socket: Socket

export function joinChannel({
  id,
  userName,
  onJoin,
  onUserJoined,
  onShapesUpdated,
  onTurnUpdate,
  onUserGuess,
}: {
  id: string;
  userName: string;
  onJoin: EventCallback<OnJoinData>;
  onUserJoined: EventCallback<GameState>;
  onShapesUpdated: EventCallback<{shapes: Shape[], player: string}>;
  onTurnUpdate: EventCallback<GameState>;
  onUserGuess: EventCallback<OnUserGuess>;
}) {
  let user: Player;


  socket = new Socket("/socket");
  socket.connect();

  const channel = socket.channel(`game:${id}`, { user: userName });

  channel
    .join()
    .receive("ok", (data: OnJoinData) => {
      console.log("Joined successfully", data);
      user = data.self;
      onJoin(data);
    })
    .receive("error", (resp) => {
      console.log("Unable to join", resp);
    });

  // Attach listeners
  channel.on("shapes_updated", onShapesUpdated);
  channel.on("user_update", onUserJoined);
  channel.on("turn_update", onTurnUpdate);
  channel.on("user_guess", onUserGuess);

  // Client actions
  const updateShapes = (data: OnShapesUpdated) => {
    channel.push("user_action", {
      ...data,
      action: "update_shapes",
      user,
    });
  };

  const startGame = () => {
    channel.push("user_action", {
      action: "start",
      user,
    });
  };

  const startTurn = ({ value }: { value: string }) => {
    channel.push("user_action", {
      action: "start_turn",
      value,
      user,
    });
  };

  const makeGuess = ({ value }: { value: string }) => {
    channel.push("user_action", {
      action: "guess",
      value,
      user,
    });
  };
  
  const joinTeam = ({ teamId }: { teamId: string }) => {
    channel.push("user_action", {
      action: "choose_team",
      team_id:teamId,
      user,
    });
  };
  
  const setWord = ({ value }: { value: string }) => {
    channel.push("user_action", {
      action: "set_word",
      value,
      user,
    });
  };

  return {
    updateShapes,
    startGame,
    startTurn,
    makeGuess,
    joinTeam,
    setWord
  };
}
